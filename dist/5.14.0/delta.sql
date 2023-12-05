/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 02.01.2023 Sofia SIAC-8878 - inizio 
DROP  FUNCTION IF EXISTS
fnc_fasi_bil_gest_ribaltamento_vincoli
(
  p_tipo_ribaltamento varchar, --'GEST-GEST' 'PREV-GEST'
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_ribaltamento_vincoli (
  p_tipo_ribaltamento varchar, --'GEST-GEST' 'PREV-GEST'
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
) returns RECORD
AS
  $body$
  DECLARE
    strmessaggio       			VARCHAR(1500)	:='';
    strmessaggiofinale 			VARCHAR(1500)	:='';
    bilelemidret           		INTEGER  		:=NULL;
    codresult              		INTEGER  		:=NULL;
    datainizioval 				timestamp		:=NULL;
    fasebilelabid    			INTEGER  		:=NULL;
    categoriacapcode 			VARCHAR  		:=NULL;
    bilelemstatoanid 			INTEGER  		:=NULL;
    ape_prev_da_gest            CONSTANT VARCHAR:='APE_PREV';
    --v_dataprimogiornoanno 		timestamp		:=NULL;
    rec_vincoli_prev            RECORD;
    rec_vincoli_gest  			RECORD;
    rec_capitoli_gest 			RECORD;
    rec_capitoli_prev 			RECORD;
    _row_count 					INTEGER;

    --v_vincolo_tipo_id_prev      INTEGER;
    v_vincolo_tipo_id_gest      INTEGER;

    v_bilancio_id          		INTEGER;
    v_bilancio_id_prec     		INTEGER;

    v_periodo_id           		INTEGER;
    v_periodo_id_prec      		INTEGER;

    v_vincolo_id                INTEGER;
    v_elem_id                   INTEGER;
    v_elem_tipo_code            VARCHAR;
    v_elem_tipo_id              INTEGER;
  BEGIN
    messaggiorisultato:='';
    codicerisultato:=0;
    fasebilelabidret:=0;
    datainizioval:= clock_timestamp();
    --v_dataprimogiornoanno:= (p_annobilancio||'-01-01')::timestamp;
    strmessaggiofinale:='Ribaltamento Vincoli.';

    -- inserimento fase_bil_t_elaborazione
    strmessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    INSERT INTO fase_bil_t_elaborazione
    (
      fase_bil_elab_esito,
      fase_bil_elab_esito_msg,
      fase_bil_elab_tipo_id,
      ente_proprietario_id,
      validita_inizio,
      login_operazione
    )
    (
    SELECT 'IN', 'ELABORAZIONE FASE BILANCIO  IN CORSO : RIBALTAMENTO VINCOLI.',
        tipo.fase_bil_elab_tipo_id,
        p_enteproprietarioid,
        datainizioval,
        p_loginoperazione
    FROM
    	fase_bil_d_elaborazione_tipo tipo
    WHERE  tipo.ente_proprietario_id=p_enteproprietarioid
    AND    tipo.fase_bil_elab_tipo_code='APE_GEST_VINCOLI'
    AND    tipo.data_cancellazione IS NULL
    AND    tipo.validita_fine IS NULL)
    returning   fase_bil_elab_id
    INTO        fasebilelabid;


    IF fasebilelabid IS NULL THEN
      RAISE EXCEPTION ' Inserimento non effettuato.';
    END IF;

    faseBilElabIdRet:= fasebilelabid;
    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
    (
      fase_bil_elab_id,
      fase_bil_elab_log_operazione,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )VALUES(
      fasebilelabid,
      strmessaggio,
      clock_timestamp(),
      p_loginoperazione,
      p_enteproprietarioid
    ) returning   fase_bil_elab_log_id INTO        codresult;

    IF codresult IS NULL THEN
      RAISE EXCEPTION ' Errore in inserimento LOG.';
    END IF;




	--inizio procedura
    strmessaggio:='estraggo il periodo del bilancio in esame = anno-->'||p_annobilancio||'.';
    begin
      select per.periodo_id,bil.bil_id
      into strict v_periodo_id ,v_bilancio_id
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
	end;

    strmessaggio:='estraggo il periodo del bilancio anno precedente periodo_code = anno'||p_annobilancio-1||'.';
    begin
      select per.periodo_id,bil.bil_id
      into strict v_periodo_id_prec ,v_bilancio_id_prec
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio-1;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
	end;


    strmessaggio:='vincolo_tipo_id dei vincoli nuovi di gestione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_gest
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'G'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code G.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code G.';
		 return;
	end;
/*
    strmessaggio:='vincolo_tipo_id dei vincoli di previsione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_prev
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'P'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code P.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code P.';
		 return;
	end;
*/

   /* execute 'CREATE TABLE IF NOT EXISTS siac_t_vincolo_tmp(id INTEGER);';

    strmessaggio:='cancello eventuale ribaltamento fatto precedentemente';
    delete from siac_r_vincolo_bil_elem using siac_t_vincolo_tmp 	where  siac_r_vincolo_bil_elem.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_genere using siac_t_vincolo_tmp 		where  siac_r_vincolo_genere.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_attr using siac_t_vincolo_tmp 		where  siac_r_vincolo_attr.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_stato using siac_t_vincolo_tmp 		where  siac_r_vincolo_stato.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_t_vincolo using siac_t_vincolo_tmp 			where  siac_t_vincolo.vincolo_id = siac_t_vincolo_tmp.id ;

    -- pulisco la tabella di bck
    execute 'delete from siac_t_vincolo_tmp;';*/


    -- pulizia dati presenti
    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_bil_elem.';
    update siac_r_vincolo_bil_elem r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_attr.';
    update siac_r_vincolo_attr r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_genere.';
    update siac_r_vincolo_genere r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - inizio
	strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_risorse_vincolate.';
    update siac_r_vincolo_risorse_vincolate r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;
 	-- 05.03.2021 Sofia Jira SIAC-790 - fine


    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_stato.';
    update siac_r_vincolo_stato r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_t_vincolo.';
    update siac_t_vincolo v
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=v.login_operazione||'-'||p_loginoperazione
    from siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   v.data_cancellazione is null
    and   v.validita_fine is null;

	strmessaggio:='ribalto da gestione anno precedente a gestione anno in esame';
	if p_tipo_ribaltamento = 'GEST-GEST' THEN

            strmessaggio:='inizio ciclo sui vincoli di gestione anno precedente';
            FOR rec_vincoli_gest IN(
               select
                   siac_t_vincolo.vincolo_id
                  ,siac_t_vincolo.vincolo_code
                  ,siac_t_vincolo.vincolo_desc
                  ,siac_t_vincolo.vincolo_tipo_id
                  ,siac_t_vincolo.periodo_id
    --              ,siac_d_vincolo_genere.vincolo_gen_id
              from
                   siac_t_vincolo
                  ,siac_d_vincolo_tipo
                  ,siac_r_vincolo_stato
                  ,siac_d_vincolo_stato
--                  ,siac_r_vincolo_genere
  --                ,siac_d_vincolo_genere
              where
                    siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
              and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
              and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
              and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--              and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id
--              and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id
              and   siac_d_vincolo_stato.vincolo_stato_code!='A'
              and   siac_d_vincolo_tipo.vincolo_tipo_code='G'
              and   siac_t_vincolo.periodo_id = v_periodo_id_prec
              and 	siac_r_vincolo_stato.data_cancellazione is null
              and 	siac_r_vincolo_stato.validita_fine is null
              and 	siac_t_vincolo.data_cancellazione is null
              and 	siac_t_vincolo.validita_fine is null
--              and   siac_r_vincolo_genere.data_cancellazione is null

            )LOOP

                strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_gest '||v_vincolo_tipo_id_gest||' v_periodo_id '||v_periodo_id||'.';

                insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
                )VALUES(
                   rec_vincoli_gest.vincolo_code
                  ,rec_vincoli_gest.vincolo_desc
                  ,v_vincolo_tipo_id_gest
                  ,v_periodo_id
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                ) returning   vincolo_id INTO v_vincolo_id;

                --mi tengo un bck per sicurezza
                -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

                strmessaggio:='inserimento del genere.';
                insert into siac_r_vincolo_genere
                ( vincolo_id,
                  vincolo_gen_id,
                  validita_inizio,
                  ente_proprietario_id,
                  login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_gen_id
                  ,now()
                  ,p_enteproprietarioid
                  ,p_loginoperazione
                from siac_r_vincolo_genere r
                where r.vincolo_id=rec_vincoli_gest.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );

                -- 05.03.2021 Sofia Jira SIAC-790 - inizio
                strmessaggio:='inserimento risorse.';
                insert into siac_r_vincolo_risorse_vincolate
                (vincolo_id,
                 vincolo_risorse_vincolate_id,
                 validita_inizio,
                 ente_proprietario_id,
                 data_creazione,
                 login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_risorse_vincolate_id
                  ,now()
                  ,p_enteproprietarioid
                  ,now()
                  ,p_loginoperazione
                from siac_r_vincolo_risorse_vincolate r
                where r.vincolo_id=rec_vincoli_gest.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
                -- 05.03.2021 Sofia Jira SIAC-790 - fine

                strmessaggio:='inserimento attributi sul vincolo.';
                insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
                select
                   v_vincolo_id
                  ,attr_id
                  ,tabella_id
                  ,boolean
                  ,percentuale
                  ,testo
                  ,numerico
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                from
                    siac_r_vincolo_attr
                where
                    siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
                and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_gest.vincolo_id
                and siac_r_vincolo_attr.data_cancellazione is null
                and siac_r_vincolo_attr.validita_fine is null;

                strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
                insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
                select
                   v_vincolo_id
                  ,vincolo_stato_id
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                from
                siac_r_vincolo_stato
                 where
                    siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
                and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_gest.vincolo_id
                and siac_r_vincolo_stato.data_cancellazione is null
                and siac_r_vincolo_stato.validita_fine is null;


                strmessaggio:='ciclo capitoli di gestione da ribaltare di  anno precedente .';
                FOR rec_capitoli_gest IN(
   /*               select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                  where
                      siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                  and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                  and siac_t_bil_elem.bil_id          =  v_bilancio_id_prec
                  and siac_r_vincolo_bil_elem.data_cancellazione is null
                  and siac_r_vincolo_bil_elem.validita_fine is null
                  and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_gest.vincolo_id
                  and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
SIAC-8099 Sofia 22.04.2021                  */
-- SIAC-8099 Sofia 22.04.2021
                  select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem r,
                       siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                       siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                  where r.ente_proprietario_id = p_enteproprietarioid
                  and   r.elem_id =  e.elem_id
                  and   e.elem_tipo_id    =  tipo.elem_tipo_id
                  and   e.bil_id          =  v_bilancio_id_prec
                  and   r.vincolo_id = rec_vincoli_gest.vincolo_id
                  and   rs.elem_id=e.elem_id
                  and   stato.elem_stato_id=rs.elem_stato_id
                  and   stato.elem_stato_code!='AN'
                  and   r.data_cancellazione is null
                  and   r.validita_fine is null
                  and   rs.data_cancellazione is null
                  and   rs.validita_fine is null
                  and   e.data_cancellazione is null
                  and   e.validita_fine is null
                )LOOP

                    strmessaggio:='estraggo il tipo nuovo di prev.';
                    raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_gest.elem_tipo_code,rec_capitoli_gest.elem_code,rec_capitoli_gest.elem_id;

                    select elem_tipo_id into strict v_elem_tipo_id
                    from siac_d_bil_elem_tipo
                    where
                    ente_proprietario_id = p_enteproprietarioid
                    and elem_tipo_code = rec_capitoli_gest.elem_tipo_code;

                    v_elem_id:=null;
                    strmessaggio:='estraggo elem_id v_elem_tipo_id '|| v_elem_tipo_id::varchar||' rec_capitoli_gest.elem_code '||rec_capitoli_gest.elem_code||' rec_capitoli_gest.elem_code2 '||rec_capitoli_gest.elem_code2||' rec_capitoli_gest.elem_code3 '||rec_capitoli_gest.elem_code3||'.';
--                    select siac_t_bil_elem.elem_id into strict v_elem_id
/* 29.04.2021 Sofia Jira SIAC-8099
                    select siac_t_bil_elem.elem_id into v_elem_id
                    FROM   siac_t_bil_elem,siac_t_bil
                    where
                        siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                    and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                    and siac_t_bil_elem.elem_code      = rec_capitoli_gest.elem_code
                    and siac_t_bil_elem.elem_code2     = rec_capitoli_gest.elem_code2
                    and siac_t_bil_elem.elem_code3     = rec_capitoli_gest.elem_code3
                    and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                    and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/

					-- 29.04.2021 Sofia Jira SIAC-8099
					select e.elem_id into v_elem_id
                    FROM   siac_t_bil_elem e,siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                           siac_t_bil bil
                    where e.ente_proprietario_id = p_enteproprietarioid
                    and   e.elem_tipo_id   = v_elem_tipo_id
                    and   e.bil_id         = bil.bil_id
                    and   bil.bil_code     = 'BIL_'||p_annobilancio
                    and   e.elem_code      = rec_capitoli_gest.elem_code
                    and   e.elem_code2     = rec_capitoli_gest.elem_code2
                    and   e.elem_code3     = rec_capitoli_gest.elem_code3
                    and   rs.elem_id       = e.elem_id
                    and   stato.elem_stato_id=rs.elem_Stato_id
                    and   stato.elem_stato_code!='AN'
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null;

					if v_elem_id is not null then
                     strmessaggio:='inizio inserimenti per i capitoli .';
                     raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code,rec_capitoli_gest.elem_code,v_elem_id;

                     insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
                     )values(
                         v_vincolo_id
                        ,v_elem_id
                        ,now()
                        ,null
                        ,p_enteproprietarioid
                        ,now()
                        ,now()
                        ,null
                        ,p_loginoperazione
                     );
                    end if;


                end LOOP;
            end LOOP;
 	end if;

	--ribalto da previsione anno in esame a gestione anno in esame

	if p_tipo_ribaltamento = 'PREV-GEST' THEN
    	      strmessaggio:='ribaltamento da previsiione a gestione dello stesso anno';
              FOR rec_vincoli_prev IN(
                 select
                     siac_t_vincolo.vincolo_id
                    ,siac_t_vincolo.vincolo_code
                    ,siac_t_vincolo.vincolo_desc
                    ,siac_t_vincolo.vincolo_tipo_id
                    ,siac_t_vincolo.periodo_id
--                    ,siac_d_vincolo_genere.vincolo_gen_id
                from
                     siac_t_vincolo
                    ,siac_d_vincolo_tipo
                    ,siac_r_vincolo_stato
                    ,siac_d_vincolo_stato
--                    ,siac_r_vincolo_genere
--                    ,siac_d_vincolo_genere
                where
                      siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
                and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
                and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
                and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--                and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id
--                and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id
                and   siac_d_vincolo_stato.vincolo_stato_code!='A'
                and   siac_d_vincolo_tipo.vincolo_tipo_code='P'
                and   siac_t_vincolo.periodo_id = v_periodo_id
                and 	siac_r_vincolo_stato.data_cancellazione is null
                and 	siac_r_vincolo_stato.validita_fine is null
                and 	siac_t_vincolo.data_cancellazione is null
                and 	siac_t_vincolo.validita_fine is null
  --              and   siac_r_vincolo_genere.data_cancellazione is null

              )LOOP

                  strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_gest '||v_vincolo_tipo_id_gest||' v_periodo_id '||v_periodo_id||'.';
                  insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
                  )VALUES(
                     rec_vincoli_prev.vincolo_code
                    ,rec_vincoli_prev.vincolo_desc
                    ,v_vincolo_tipo_id_gest
                    ,v_periodo_id
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  ) returning   vincolo_id INTO v_vincolo_id;

                  --mi tengo un bck per sicurezza
                 -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

                  strmessaggio:='inserimento del genere.';
                  insert into siac_r_vincolo_genere
                  ( vincolo_id,
                    vincolo_gen_id,
                    validita_inizio,
                    ente_proprietario_id,
                    login_operazione
                  )
                  (
                  select
                     v_vincolo_id
                    ,r.vincolo_gen_id
                    ,now()
                    ,p_enteproprietarioid
                    ,p_loginoperazione
                  from siac_r_vincolo_genere r
                  where r.vincolo_id=rec_vincoli_prev.vincolo_id
                  and   r.data_cancellazione is null
                  and   r.validita_fine is null
                  );

				-- 20.04.2021 Sofia Jira 	SIAC-8099 - inizio
                strmessaggio:='inserimento risorse.';
                insert into siac_r_vincolo_risorse_vincolate
                (vincolo_id,
                 vincolo_risorse_vincolate_id,
                 validita_inizio,
                 ente_proprietario_id,
                 data_creazione,
                 login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_risorse_vincolate_id
                  ,now()
                  ,p_enteproprietarioid
                  ,now()
                  ,p_loginoperazione
                from siac_r_vincolo_risorse_vincolate r
                where r.vincolo_id=rec_vincoli_prev.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
                -- 20.04.2021 Sofia Jira 	SIAC-8099 - fine

                  strmessaggio:='inserimento attributi sul vincolo.';
                  insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
                  select
                     v_vincolo_id
                    ,attr_id
                    ,tabella_id
                    ,boolean
                    ,percentuale
                    ,testo
                    ,numerico
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  from
                      siac_r_vincolo_attr
                  where
                      siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
                  and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_prev.vincolo_id
                  and siac_r_vincolo_attr.data_cancellazione is null
                  and siac_r_vincolo_attr.validita_fine is null;

                  strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
                  insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
                  select
                     v_vincolo_id
                    ,vincolo_stato_id
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  from
                  siac_r_vincolo_stato
                   where
                      siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
                  and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_prev.vincolo_id
                  and siac_r_vincolo_stato.data_cancellazione is null
                  and siac_r_vincolo_stato.validita_fine is null;


                  strmessaggio:='ciclo capitoli di previsione da ribaltare dello stesso anno .';
                  FOR rec_capitoli_prev IN(
/*
                    select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                    from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                    where
                        siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                    and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.bil_id          =  v_bilancio_id
                    and siac_r_vincolo_bil_elem.data_cancellazione is null
                    and siac_r_vincolo_bil_elem.validita_fine is null
                    and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_prev.vincolo_id
                    and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
SIAC-8099 Sofia 22.04.2021                    */
-- SIAC-8099 Sofia 22.04.2021
                    select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
                    from siac_r_vincolo_bil_elem r, siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                         siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                    where r.ente_proprietario_id = p_enteproprietarioid
                    and   r.elem_id =  e.elem_id
                    and   e.elem_tipo_id    =  tipo.elem_tipo_id
                    and   e.bil_id          =  v_bilancio_id
                    and   r.vincolo_id = rec_vincoli_prev.vincolo_id
					--    02.01.2023 Sofia SIAC-8878
                    --and   rs.elemid=e.elem_id
					and   rs.elem_id=e.elem_id
                    and   stato.elem_stato_id=rs.elem_stato_id
                    and   stato.elem_stato_code!='AN'
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                  )LOOP

                      strmessaggio:='deduco il codice del capitolo di gestione nuovo.';

                      if rec_capitoli_prev.elem_tipo_code = 'CAP-UP' THEN
                          v_elem_tipo_code := 'CAP-UG';
                      elseif rec_capitoli_prev.elem_tipo_code = 'CAP-EP' THEN
                          v_elem_tipo_code := 'CAP-EG';
                      end if;

                      strmessaggio:='estraggo il tipo nuovo di prev.';
                      raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_prev.elem_tipo_code,rec_capitoli_prev.elem_code,rec_capitoli_prev.elem_id;
                      select elem_tipo_id into strict v_elem_tipo_id
                      from siac_d_bil_elem_tipo
                      where
                      ente_proprietario_id = p_enteproprietarioid
                      and elem_tipo_code = v_elem_tipo_code ;

                      strmessaggio:='estraggo elem_id v_elem_tipo_id '|| v_elem_tipo_id::varchar||' rec_capitoli_prev.elem_code '||rec_capitoli_prev.elem_code||' rec_capitoli_prev.elem_code2 '||rec_capitoli_prev.elem_code2||' rec_capitoli_prev.elem_code3 '||rec_capitoli_prev.elem_code3||'.';

--                      select siac_t_bil_elem.elem_id into strict v_elem_id
                      v_elem_id:=null;
/* 29.04.2021 Sofia Jira SIAC-8099
                      select siac_t_bil_elem.elem_id into v_elem_id
                      FROM   siac_t_bil_elem,siac_t_bil
                      where
                          siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                      and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                      and siac_t_bil_elem.elem_code      = rec_capitoli_prev.elem_code
                      and siac_t_bil_elem.elem_code2     = rec_capitoli_prev.elem_code2
                      and siac_t_bil_elem.elem_code3     = rec_capitoli_prev.elem_code3
                      and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                      and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/
					  -- 29.04.2021 Sofia Jira SIAC-8099
                      --select siac_t_bil_elem.elem_id into v_elem_id
					  -- 02.01.2023 Sofia Jira and   rs.elemid=e.elem_id
					  select e.elem_id into v_elem_id
                      FROM   siac_t_bil_elem e,siac_t_bil bil,
                             siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                      where e.ente_proprietario_id = p_enteproprietarioid
                      and   e.elem_tipo_id   = v_elem_tipo_id
                      and   e.bil_id         = bil.bil_id
                      and   bil.bil_code     = 'BIL_'||p_annobilancio
                      and   e.elem_code      = rec_capitoli_prev.elem_code
                      and   e.elem_code2     = rec_capitoli_prev.elem_code2
                      and   e.elem_code3     = rec_capitoli_prev.elem_code3
                      and   rs.elem_id       =e.elem_id
                      and   stato.elem_stato_id=rs.elem_stato_id
                      and   stato.elem_stato_code='AN'
                      and   rs.data_cancellazione is null
                      and   rs.validita_fine is null
                      and   e.data_cancellazione is null
                      and   e.validita_fine is null;



                      if v_elem_id is not null then
                       strmessaggio:='inizio inserimenti per i capitoli .';
                       raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code,rec_capitoli_prev.elem_code,v_elem_id;

                       insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
                       )values(
                           v_vincolo_id
                          ,v_elem_id
                          ,now()
                          ,null
                          ,p_enteproprietarioid
                          ,now()
                          ,now()
                          ,null
                          ,p_loginoperazione
                       );
                      end if;

                  end LOOP;
              end LOOP;
/*    ELSE
      	RAISE notice 'PAREAMETRO p_tipo_ribaltamento non valorizzato correttamente valori ammessi GEST-GEST PREV-GEST. ';
      	messaggiorisultato:='PAREAMETRO p_tipo_ribaltamento non valorizzato correttamente valori ammessi GEST-GEST PROV-GEST. ' ;
      	codicerisultato:=-1;
    	return;*/
    end if;
	--Fine procedura

	strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE RIBALTAMENTO VINCOLI TERMINATA.'
    where fase_bil_elab_id=faseBilElabId;

	codResult:=null;
   	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),p_loginoperazione,p_enteproprietarioid)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
       	raise exception ' Errore in inserimento LOG.';
    end if;


    messaggiorisultato := 'vincoli ribaltati correttamente';
    codicerisultato := 0 ;
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

 alter function siac.fnc_fasi_bil_gest_ribaltamento_vincoli (  varchar,  integer,  integer,  varchar,  timestamp,  out integer,  out integer,  out varchar) owner to siac;
 -- 02.01.2023 Sofia SIAC-8878 - fine
 
 
 -- 03.01.2023 Sofia SIAC-8881- inizio
 insert into siac_t_attr 
(
attr_code,
attr_desc,
attr_tipo_id,
validita_inizio,
login_operazione ,
ente_proprietario_id 
)
select 'annoScritturaEconomicoPatrimoniale',
           'annoScritturaEconomicoPatrimoniale',
           tipo.attr_tipo_id ,
           now(),
           'SIAC-8881',
           tipo.ente_proprietario_id 
from siac_d_attr_tipo tipo 
where tipo.ente_proprietario_id in (2,3,4,5,10,16)
and      tipo.attr_tipo_code ='X'
and      not exists 
(select 1 from siac_t_attr attr1 where attr1.ente_proprietario_id=tipo.ente_proprietario_id and   attr1.attr_code='annoScritturaEconomicoPatrimoniale');
 -- 03.01.2023 Sofia SIAC-8881- fine 
 
 -- 11.01.2023 Sofia SIAC-8879 - inizio 
 drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean DEFAULT true, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
)
RETURNS record
AS $body$
			 
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';

	STATO_AN 			    	     CONSTANT varchar:='AN';

	-- 21.01.2022 Sofia Jira SIAC-8536
    FL_RIL_FPV_ATTR                  CONSTANT varchar:='FlagRilevanteFPV';
    FlagRilevanteFPVAttrId           integer:=NULL;

    numeroProgr                      integer:=null;
    numeroCronop					 integer:=null;

     -- 30.07.2019 Sofia siac-6934
    flagDaRiaccAttrId                integer:=null;
    annoRiaccAttrId                  integer:=null;
    numeroRiaccAttrId                integer:=null;

   
   
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Elaborazione.';


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null;

    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
    select 1 into codResult
    from fase_bil_t_programmi fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      -- 10.09.2019 Sofia SIAC-7023
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;

   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio-1
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;



   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
   else
   	bilancioElabId:=bilancioId;
   end if;

   -- 30.07.2019 Sofia siac-6934
   strMessaggio:='Lettura identificativi attributi riaccertamento.';
   SELECT attr.attr_id
   INTO   flagDaRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='flagDaRiaccertamento'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   annoRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='annoRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   numeroRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='numeroRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

  
  	
   -- 21.01.2022 Sofia Jira SIAC-8536
   strMessaggio:='Lettura identificativo attributo FlagRilevanteFPV.';
   SELECT attr.attr_id
   INTO   FlagRilevanteFPVAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code =FL_RIL_FPV_ATTR
   AND    attr.ente_proprietario_id = enteproprietarioid;
  
   strMessaggio:='Inizio inserimento dati programmi da  fase_bil_t_programmi - inizio.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- siac_t_programma

   strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_t_programma].';
   insert into siac_t_programma
   (
   	 programma_code,
	 programma_desc,
     programma_tipo_id,
     bil_id,
     programma_data_gara_indizione,
	 programma_data_gara_aggiudicazione,
	 investimento_in_definizione,
     programma_responsabile_unico,
	 programma_spazi_finanziari,
     programma_affidamento_id,
     login_operazione,
     validita_inizio,
     ente_proprietario_id
   )
   select  progr.programma_code,
           progr.programma_desc,
           tipo.programma_tipo_id,
           bilancioId,
           progr.programma_data_gara_indizione,
		   progr.programma_data_gara_aggiudicazione,
	   	   progr.investimento_in_definizione,
	       progr.programma_responsabile_unico,
	   	   progr.programma_spazi_finanziari,
	       progr.programma_affidamento_id,
           loginOperazione||'@'||fase.fase_bil_programma_id::varchar,
           clock_timestamp(),
           progr.ente_proprietario_id
   from fase_bil_t_programmi fase,siac_t_programma progr,
        siac_d_programma_tipo tipo
   where fase.fase_bil_elab_id=faseBilElabId
   and   progr.programma_id=fase.programma_id
   and   fase.fl_elab='N'
   and   tipo.ente_proprietario_id=progr.ente_proprietario_id
   and   tipo.programma_tipo_code=tipoApertura
   and   fase.data_cancellazione is null;

   GET DIAGNOSTICS numeroProgr = ROW_COUNT;


   strMessaggio:='Numero di programmi inseriti='||coalesce(numeroProgr,0)::varchar||'.';
   raise notice '%', strMessaggio;
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- inserimento dati programmi
   if coalesce(numeroProgr,0)!=0 then
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - aggiornamento fase_bil_t_programmi.';
    codResult:=null;
    update fase_bil_t_programmi fase
    set    programma_new_id=progr.programma_id,
           fl_elab='S'
    from   siac_t_programma progr
    where  fase.fase_bil_elab_id=faseBilElabId
    and    fase.fl_elab='N'
    and    progr.ente_proprietario_id=enteProprietarioId
    and    progr.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-SIAC-8470
    and    progr.login_operazione like loginOperazione||'@%'
    and    substring(progr.login_operazione from position ('@' in progr.login_operazione)+1)::integer=fase.fase_bil_programma_id
    and    fase.data_cancellazione is null
    and    progr.data_cancellazione is null
    and    progr.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=coalesce(numeroProgr,0) then
     raise exception ' Il numero di aggiornamenti non corrisponde al numero di programmi inseriti.';
    end if;


    -- siac_r_programma_stato
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_stato].';
    codResult:=null;
    insert into siac_r_programma_stato
    (
   	 programma_id,
     programma_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rs.programma_stato_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_stato rs
    where fase.fase_bil_elab_id=faseBilElabId
    and   rs.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   fase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=0 and coalesce(numeroProgr,0)=0 then
	   raise exception ' Il numero di stati inseriti non corrisponde al numero di programmi inseriti.';
    end if;
    raise notice '% numIns=%', strMessaggio,codResult;



    -- siac_r_programma_class
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_class].';
    codResult:=null;
    insert into siac_r_programma_class
    (
   	 programma_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rc.classif_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_class rc,siac_t_class c
    where fase.fase_bil_elab_id=faseBilElabId
    and   rc.programma_id=fase.programma_id
    and   c.classif_id=rc.classif_id
    and   fase.programma_new_id is not null
    and   c.data_cancellazione is null
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

 

    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_attr].';
    -- siac_r_programma_attr
    codResult:=null;
    insert into siac_r_programma_attr
    (
   	 programma_id,
     attr_id,
     boolean,
     testo,
     percentuale,
     numerico,
     tabella_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
   	       rattr.attr_id,
---   	       rattr.boolean     -- 21.01.2022 Sofia Jira SIAC-8563
   	       ( CASE WHEN tipoapertura=P_FASE AND rattr.attr_id=FlagRilevanteFPVAttrId THEN 'N'
   	         ELSE  rattr.boolean END 
   	       )  ,     -- 21.01.2022 Sofia Jira SIAC-8563
		   rattr.testo,
		   rattr.percentuale,
	       rattr.numerico,
	       rattr.tabella_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_attr rattr
    where fase.fase_bil_elab_id=faseBilElabId
    and   rattr.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

   
   
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_atto_amm].';
    -- siac_r_programma_atto_amm
    codResult:=null;
    insert into siac_r_programma_atto_amm
    (
     programma_id,
     attoamm_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
	       ratto.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_atto_amm ratto
    where fase.fase_bil_elab_id=faseBilElabId
    and   ratto.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;
  end if;




  strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - fine .';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
  end if;
  -- fine inserimento dati programmi

  strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - verifica dati creare [fase_bil_t_cronop].';

  codResult:=null;
  select 1 into codResult
  from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec
  where fasep.fase_bil_elab_id=faseBilElabId
  and   fasep.programma_new_id is not null
  and   fasep.fl_elab='S'
  and   fasec.fase_bil_elab_id=faseBilElabId
  and   fasec.programma_id=fasep.programma_id
  and   fasec.fl_elab='N'
  and   fasep.data_cancellazione is null
  and   fasec.data_cancellazione is null;

  raise notice '% numdaIns=%', strMessaggio,codResult;


  if codResult is not null then

   	strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop da inserire numero='||codResult::varchar||'- inizio.';
	codResult:=null;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop].';
    -- siac_t_cronop
   	insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     fasep.programma_new_id,
	     bilancioId,
--	     cronop.usato_per_fpv,      -- 04.10.2022 Sofia Jira SIAC-8816
   	       ( CASE WHEN tipoapertura=P_FASE  THEN false
   	         ELSE  cronop.usato_per_fpv END 
   	       )  ,     -- 04.10.2022 Sofia Jira SIAC-8816
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec,siac_t_cronop cronop
    where fasep.fase_bil_elab_id=faseBilElabId
    and   fasep.programma_new_id is not null
    and   fasep.fl_elab='S'
    and   fasec.fase_bil_elab_id=faseBilElabId
    and   fasec.programma_id=fasep.programma_id
    and   fasec.fl_elab='N'
    and   cronop.cronop_id=fasec.cronop_id
    and   fasep.data_cancellazione is null
    and   fasec.data_cancellazione is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS numeroCronop = ROW_COUNT;

    if coalesce(numeroCronop,0)!=0 then

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop inseriti numero='||coalesce(numeroCronop,0)::varchar||'.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
	 (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
	 )
     values
     (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  - aggiornamento fase_bil_t_cronop.';
     codResult:=null;
     update fase_bil_t_cronop fase
     set    cronop_new_id=cronop.cronop_id,
           fl_elab='S'
     from   siac_t_cronop cronop
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='N'
     and    cronop.ente_proprietario_id=enteProprietarioId
     and    cronop.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-8879
     and    cronop.login_operazione like loginOperazione||'@%'
     and    substring(cronop.login_operazione from position ('@' in cronop.login_operazione)+1)::integer=fase.fase_bil_cronop_id
     and    fase.data_cancellazione is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
	      raise exception ' Il numero di aggiornamenti non corrisponde al numero di crono-programmi inseriti.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_stato].';
     -- siac_r_cronop_stato
     codResult:=null;
     insert into siac_r_cronop_stato
     (
    	cronop_id,
        cronop_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            rs.cronop_stato_id,
            clock_timestamp(),
            loginOperazione,
            rs.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_stato rs
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rs.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;


     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_atto_amm].';
     -- siac_r_cronop_atto_amm
     codResult:=null;
     insert into siac_r_cronop_atto_amm
     (
    	cronop_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            ratto.attoamm_id,
            clock_timestamp(),
            loginOperazione,
            ratto.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_atto_amm ratto
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    ratto.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    ratto.data_cancellazione is null
     and    ratto.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
/*     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;*/

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_attr].';

     -- siac_r_cronop_attr
     codResult:=null;
     insert into siac_r_cronop_attr
     (
    	cronop_id,
		attr_id,
	    boolean,
	    testo,
    	percentuale,
	    numerico,
    	tabella_id,
	    validita_inizio,
    	login_operazione,
	    ente_proprietario_id
     )
     select
        fase.cronop_new_id,
        rattr.attr_id,
	    rattr.boolean,
    	rattr.testo,
	    rattr.percentuale,
	    rattr.numerico,
    	rattr.tabella_id,
	    clock_timestamp(),
    	loginOperazione,
	    rattr.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_attr rattr
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rattr.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rattr.data_cancellazione is null
     and    rattr.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem].';
	 codResult:=null;
     -- siac_t_cronop_elem
     insert into siac_t_cronop_elem
     (
	    cronop_elem_code,
	    cronop_elem_code2,
	    cronop_elem_code3,
	    cronop_elem_desc,
	    cronop_elem_desc2,
	    cronop_id,
--	    cronop_elem_id_padre,
        cronop_elem_is_ava_amm,
	    elem_tipo_id,
	    ordine,
	    livello,
   	    login_operazione,
	    validita_inizio,
	    ente_proprietario_id
     )
     select
        celem.cronop_elem_code,
	    celem.cronop_elem_code2,
	    celem.cronop_elem_code3,
	    celem.cronop_elem_desc,
	    celem.cronop_elem_desc2,
        fase.cronop_new_id,
--        cronop_elem_id_padre,
	    celem.cronop_elem_is_ava_amm,
        tiponew.elem_tipo_id,
        celem.ordine,
	    celem.livello,
        loginOperazione||'@'||celem.cronop_elem_id::varchar,
        clock_timestamp(),
        celem.ente_proprietario_id
 	 from fase_bil_t_cronop fase,siac_t_cronop_elem celem,
          siac_d_bil_elem_tipo tipo, siac_d_bil_elem_tipo tiponew
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_id
     and    tipo.elem_tipo_id=celem.elem_tipo_id
     and    tiponew.ente_proprietario_id=tipo.ente_proprietario_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;






     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_class].';
	 codResult:=null;
	 -- siac_r_cronop_elem_class
     insert into siac_r_cronop_elem_class
     (
  	  	cronop_elem_id,
	    classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            c.classif_id,
            clock_timestamp(),
            loginOperazione,
            c.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_class r,siac_t_class c
	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    c.classif_id=r.classif_id
     and    c.data_cancellazione is null
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_bil_elem].';
	 codResult:=null;
     -- siac_r_cronop_elem_bil_elem
     insert into siac_r_cronop_elem_bil_elem
     (
	    cronop_elem_id,
	    elem_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            enew.elem_id,
            clock_timestamp(),
            loginOperazione,
            enew.ente_proprietario_id
     from  fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_bil_elem r,
           siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
           siac_t_bil_elem enew,siac_d_bil_elem_tipo tiponew,
           siac_r_bil_elem_stato rs,siac_d_bil_elem_Stato stato
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    e.elem_id=r.elem_id
     and    tipo.elem_tipo_id=e.elem_tipo_id
     and    enew.bil_id=bilancioId
     and    enew.elem_code=e.elem_code
     and    enew.elem_code2=e.elem_code2
     and    enew.elem_code3=e.elem_code3
     and    tiponew.elem_tipo_id=enew.elem_tipo_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    rs.elem_id=enew.elem_id
     and    stato.elem_stato_id=rs.elem_stato_id
     and    stato.elem_stato_code!='AN'
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    e.data_cancellazione is null
     and    enew.data_cancellazione is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem_det].';
     codResult:=null;
     -- siac_t_cronop_elem_det
     insert into siac_t_cronop_elem_det
     (
	    cronop_elem_det_desc,
	    cronop_elem_id,
	    cronop_elem_det_importo,
	    elem_det_tipo_id,
	    periodo_id,
	    anno_entrata,
        quadro_economico_id_padre,
	    quadro_economico_id_figlio,
	    quadro_economico_det_importo,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
     )
     select
         det.cronop_elem_det_desc,
	     celem.cronop_elem_id,
	     det.cronop_elem_det_importo,
	     det.elem_det_tipo_id,
	     det.periodo_id,
	     det.anno_entrata,
         det.quadro_economico_id_padre,
	     det.quadro_economico_id_figlio,
	     det.quadro_economico_det_importo,
         loginOperazione,
         clock_timestamp(),
         det.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem, siac_t_cronop_elem_det det
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    det.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    det.data_cancellazione is null
     and    det.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;
   end if;
   strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - fine.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
   end if;

 end if;

 --- inserimento collegamenti tra programma e siac_t_movgest_Ts [siac_r_movgest_ts_programma]
 --- inserimento collegamenti tra cronop    e siac_t_movgest_ts [siac_r_movgest_ts_cronop_elem]
 --  inserimento da effettuare solo per tipoApertura='G'
 --  quindi partendo da movimenti validi e programmi - cronop nuovi, riportare le relazioni da annoBilancioPrec
 --  convertendo gli id da annoPrec a annoBilancio
 -- 06.05.2019 Sofia siac-6255
-- if tipoApertura=G_FASE then -- tutto da rivedere
-- 06.02.2020 Sofia jira SIAC-7386 aggiunto par. non aggiornare tutti i collegamenti in caso di esecuzione da puntuale
 if tipoApertura=G_FASE and ribalta_coll_mov=true then

  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inizio.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;

  -- inserimento legami aperti esistenti su impegni/accertamenti residui
  -- siac_r_movgest_ts_programma
  -- residui
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma residui.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_res_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_res_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_res_anno,
         mov_res_anno_prec, progr progr_anno, progr progr_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   mov_res_anno.movgest_tipo_id=mov_res_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_res_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- pluriennali
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma pluriennali.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_pluri_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_pluri_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_pluri_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_pluri_anno,
         mov_pluri_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_pluri_anno.movgest_anno=mov_pluri_anno_prec.movgest_anno
    and   mov_pluri_anno.movgest_numero=mov_pluri_anno_prec.movgest_numero
    and   mov_pluri_anno.movgest_subnumero=mov_pluri_anno_prec.movgest_subnumero
    and   mov_pluri_anno.movgest_tipo_id=mov_pluri_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_pluri_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- 30.07.2019 Sofia siac-6934
  -- riaccertati
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma riaccertati.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,
           siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
    select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipo.movgest_ts_tipo_code='T' -- non il legame ad un sub sugli attributi quindi associo solo i programmi del padre
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_riacc_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_riacc_anno,
         mov_riacc_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   mov_riacc_anno.movgest_tipo_id=mov_riacc_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_riacc_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'
     and    pstato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno, cronop cronop_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'   -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'   -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  --- 30.07.2019 Sofia siac-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_anno_prec.cronop_id=mov_riacc_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
   where
   not exists
   (select 1
    from siac_r_movgest_ts_cronop_elem r1
    where r1.movgest_ts_id=query.movgest_ts_id
    and   r1.cronop_id=query.cronop_new_id
    and   r1.cronop_elem_id is null
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)      elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'')  cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  --- 31.07.2019 Sofia SIAC-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
     with
     mov_anno as
     (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     annoRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=annoRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     numeroRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=numeroRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     )
     select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
     from mov_anno, annoRiacc, numeroRiacc
     where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
     and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
---     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_riacc_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
   where not exists
   (
   select 1
   from siac_r_movgest_ts_cronop_elem r1
   where r1.movgest_ts_id=query.movgest_ts_id
   and   r1.cronop_id=query.cronop_new_id
   and   r1.cronop_elem_id=query.cronop_elem_new_id
   and   r1.data_cancellazione is null
   and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;



  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - fine.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;
 end if;
 -- 06.05.2019 Sofia siac-6255



 strMessaggio:='Inserimento LOG.';
 codResult:=null;
 insert into fase_bil_t_elaborazione_log
 (fase_bil_elab_id,fase_bil_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
 if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
 end if;


 if coalesce(codiceRisultato,0)=0 then
   	messaggioRisultato:=strMessaggioFinale||'- FINE.';
 else messaggioRisultato:=strMessaggioFinale||strMessaggio;
 end if;

 return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
integer, 
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer, 
OUT  varchar
) owner to siac;

 -- 11.01.2023 Sofia SIAC-8879 - fine 

 -- 18.01.2023 Alessandra SIAC-8890 - inizio  
DROP FUNCTION IF EXISTS siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER);

CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER)
RETURNS SETOF VARCHAR AS 
$body$
DECLARE
    v_messaggiorisultato VARCHAR;
    v_perc_media_confronto NUMERIC;
    v_tipo_media_confronto VARCHAR;
    v_uid_capitolo_previsione INTEGER;
    v_elem_code VARCHAR;
    v_elem_code2 VARCHAR;
BEGIN

	SELECT stbe.elem_code, stbe.elem_code2 
	FROM siac_t_bil_elem stbe 
	WHERE stbe.elem_id = p_uid_elem_gestione
	AND stbe.data_cancellazione IS NULL INTO v_elem_code, v_elem_code2;

	v_messaggiorisultato := 'Ricerca per capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di GESTIONE';
	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	
    v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti defintivi precedenti in GESTIONE';
    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

    v_tipo_media_confronto := 'GESTIONE';

    -- GESTIONE DEFINITIVA
    SELECT 
    CASE 
	/*  SIAC-8890
		WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
		ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
		ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
		else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
		ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  */
	    when tipomedia.afde_tipo_media_code != 'UTENTE' then tafdeEquiv.acc_fde_media_confronto
	    else tafdeEquiv.acc_fde_media_utente end
    FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
    JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
    JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
    JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
    JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
    JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
    JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
    JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
    WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
    AND tafdeEquiv.elem_id = p_uid_elem_gestione
    AND step.ente_proprietario_id = p_uid_ente_proprietario
    AND sdafdes.afde_stato_code = 'DEFINITIVA'
    AND tafdeEquiv.data_cancellazione IS NULL 
    AND tafdeEquiv.validita_fine IS NULL 
    ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    -- PREVISIONE DEFINITIVA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO DEFINITIVA - GESTIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco uid del capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT stbe.elem_id
        FROM siac_t_bil_elem stbe 
        JOIN siac_t_bil stb ON stbe.bil_id = stb.bil_id 
        JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
        JOIN siac_d_bil_elem_tipo sdbet ON stbe.elem_tipo_id = sdbet.elem_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = stbe.ente_proprietario_id 
        WHERE stbe.elem_code = v_elem_code 
        AND stbe.elem_code2 = v_elem_code2
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND stp.anno = p_anno_bilancio::VARCHAR
        AND sdbet.elem_tipo_code = 'CAP-EP'
        AND stbe.data_cancellazione IS NULL INTO v_uid_capitolo_previsione;
        
        IF v_uid_capitolo_previsione IS NOT NULL THEN
            v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - UID: [' || v_uid_capitolo_previsione || '] TROVATO.';
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	    END IF;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti DEFINTIVI precedenti in PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'PREVISIONE';

        SELECT 
            CASE 
				WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
				else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  
			end end end end end
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
        WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
        AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'DEFINITIVA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;
    
    END IF;

    -- PREVISIONE BOZZA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO DEFINITIVA - PREVISIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti in BOZZA in PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT 
         CASE 
				WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
				else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  
			end end end end end
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
        WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
        AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'BOZZA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    END IF;   

    -- GESTIONE BOZZA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO BOZZA - PREVISIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti in BOZZA in GESTIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'GESTIONE';

        SELECT 
        CASE 
				WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
				else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  
			end end end end end
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
        WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
        AND tafdeEquiv.elem_id = p_uid_elem_gestione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'BOZZA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    END IF;   

    IF v_perc_media_confronto IS NULL THEN
        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO BOZZA - GESTIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
    END IF;

    IF v_perc_media_confronto IS NOT NULL THEN
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - MEDIA DI CONFRONTO: [' || v_perc_media_confronto || ' - ' || v_tipo_media_confronto || ' ]';
--	ELSE 
--		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA';
    END IF;

    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

	-- [0, 1] => [0] percentuale incasso precedente, [1] => tipoMedia
    RETURN QUERY VALUES (v_perc_media_confronto::VARCHAR), (v_tipo_media_confronto);

    EXCEPTION
        WHEN RAISE_EXCEPTION THEN
            v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;
        WHEN others THEN
            v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
 -- 18.01.2023 Alessandra SIAC-8890 - fine   
 

 -- 31.01.2023 Alessandra SIAC-8897 - inizio    
DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_soggetto (integer,  varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_soggetto(_uid_soggetto integer, _annoesercizio character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, ord_numero numeric, ord_desc character varying, ord_emissione_data timestamp without time zone, ord_soggetto_code character varying, ord_soggetto_desc character varying, ord_stato_desc character varying, importo numeric, ord_ts_code character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, uid_capitolo integer, num_capitolo character varying, num_articolo character varying, num_ueb character varying, capitolo_desc character varying, provc_anno integer, provc_numero numeric, provc_data_convalida timestamp without time zone, ord_quietanza_data timestamp without time zone, sog_codice_fiscale character varying, sog_partita_iva character varying, ord_accredito_tipo_code character varying, ord_accredito_tipo_desc character varying, ord_iban character varying, ord_bic character varying, ord_contocorrente character varying, ord_contocorrente_intestazione character varying, ord_banca_denominazione character varying, ord_quietanzante character varying, ord_quietanzante_codice_fiscale character varying, ord_soggetto_cessione_code character varying, ord_soggetto_cessione_desc character varying, ord_relaz_tipo_code character varying, ord_relaz_tipo_desc character varying, ord_accredito_tipo_code_cess character varying, ord_accredito_tipo_desc_cess character varying, ord_iban_cess character varying, ord_bic_cess character varying, ord_contocorrente_cess character varying, ord_contocorrente_intestazione_cess character varying, ord_banca_denominazione_cess character varying, ord_quietanzante_cess character varying, ord_quietanzante_codice_fiscale_cess character varying, liq_attoamm_desc character varying, liq_attoalg_data_inserimento timestamp without time zone, liq_attoalg_data_scad timestamp without time zone, liq_attoalg_stato_desc character varying, ord_split character varying, ord_split_importo numeric, ord_ritenute character varying, ord_ritenute_importo numeric, carte_contabili character varying, ord_copertura character varying, ord_conto_tesoreria character varying, ord_distinta_codice character varying, ord_distinta_desc character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;

    enteProprietarioId integer=null;

BEGIN

	-- 11.07.2018 Sofia jira siac-6193
    select s.ente_proprietario_id into enteProprietarioId
    from siac_t_soggetto s
    where s.soggetto_id=_uid_soggetto;

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
            	--8,7 sec --> 4,7
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code,
                    -- 11.07.2018 Sofia jira siac-6193
                    f.ord_ts_id,
                    a.contotes_id,
                    a.dist_id
				from
					 siac_t_ordinativo a
					,siac_r_ordinativo_stato d
					,siac_d_ordinativo_stato e
					,siac_t_ordinativo_ts f
					,siac_t_ordinativo_ts_det g
					,siac_d_ordinativo_ts_det_tipo h
					,siac_d_ordinativo_tipo i
                    ,siac_t_bil tbil
					,siac_t_periodo tper

				where d.ord_id=a.ord_id
                    and d.ord_stato_id=e.ord_stato_id
                    and f.ord_id=a.ord_id
                    and g.ord_ts_id=f.ord_ts_id
                    and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
                    and a.bil_id = tbil.bil_id
                    and tbil.periodo_id	= tper.periodo_id
                    and i.ord_tipo_id=a.ord_tipo_id
					and tbil.ente_proprietario_id = enteProprietarioId                    
                    and tper.anno = _annoEsercizio
                    and h.ord_ts_det_tipo_code = 'A'
                    and i.ord_tipo_code='P'
                    and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
                    and a.data_cancellazione is null
                    and d.data_cancellazione is null
                    and e.data_cancellazione is null
                    and f.data_cancellazione is null
                    and g.data_cancellazione is null
                    and h.data_cancellazione is null
                    and i.data_cancellazione is null
                    and tbil.data_cancellazione is null
                    and tper.data_cancellazione is null

			),
			soggetto as (--ok
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc,
                    -- 11.07.2018 Sofia jira siac-6193
                    c.codice_fiscale::varchar sog_codice_fiscale,
				    c.partita_iva    sog_partita_iva,
                    c.soggetto_id
				from
					siac_t_soggetto c,
					siac_r_ordinativo_soggetto b
				where c.soggetto_id=b.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
            --40 sec -->11
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_r_ordinativo_atto_amm m
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
                and n.ente_proprietario_id = enteProprietarioId
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE (m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
            --56 sec -->18
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_t_bil_elem s,
					siac_r_ordinativo_bil_elem r
				where s.elem_id=r.elem_id
                and s.ente_proprietario_id = enteProprietarioId
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as
            (
				with modpag_noncessione as
                (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc,
                        -- 11.07.2018 Sofia jira siac-6193
                        null::varchar soggetto_cessione_code,
                        null::varchar soggetto_cessione_desc,
                        null::varchar relaz_tipo_code,
                        null::varchar relaz_tipo_desc,
                        d2.iban,
                        d2.bic,
                        d2.contocorrente,
                        d2.contocorrente_intestazione,
                        d2.banca_denominazione,
                        d2.quietanziante,
                        d2.quietanziante_codice_fiscale::varchar
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
                    and d2.ente_proprietario_id = enteProprietarioId                    
                    and d2.soggetto_id = _uid_soggetto					
                    and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null--??forse da commentare siac-5670
					and e2.data_cancellazione is null
				),
				modpag_cessione as --ok
                (
					select
						c2.ord_id,
						-- 11.07.2018 Sofia jira siac-6193
                        accre.accredito_tipo_code,
                        accre.accredito_tipo_desc,
                        sog.soggetto_code soggetto_cessione_code,
                        sog.soggetto_desc soggetto_cessione_desc,
						e2.relaz_tipo_code,
						e2.relaz_tipo_desc,
                        -- 11.07.2018 Sofia jira siac-6193
                        mdp.iban,
                        mdp.bic,
                        mdp.contocorrente,
                        mdp.contocorrente_intestazione,
                        mdp.banca_denominazione,
                        mdp.quietanziante,
                        mdp.quietanziante_codice_fiscale::varchar
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
                        siac_t_soggetto sog,
						siac_d_relaz_tipo e2,
                        siac_d_oil_relaz_tipo oil, 
                        siac_r_oil_relaz_tipo roil, -- 13.07.2018 Sofia jira siac-6193
                        siac_r_soggrel_modpag rel,
                        siac_t_modpag mdp,
                        siac_d_accredito_tipo accre
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and   e2.relaz_tipo_id = d2.relaz_tipo_id
                    -- 13.07.2017 Sofia jira siac-6193
                    and   roil.relaz_tipo_id=e2.relaz_tipo_id
                    and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
                    and   oil.oil_relaz_tipo_code='CSI'
                    and   rel.soggetto_relaz_id=d2.soggetto_relaz_id
                    and   mdp.modpag_id=rel.modpag_id
                    and   accre.accredito_tipo_id=mdp.accredito_tipo_id
                    and   sog.soggetto_id=d2.soggetto_id_a  
                    
                    and   d2.soggetto_id_da = _uid_soggetto
                  
                    and   sog.ente_proprietario_id = enteProprietarioId        
                    and   mdp.soggetto_id = _uid_soggetto                    
                    -- 13.07.2017 Sofia jira siac-6193
					and   c2.data_cancellazione is null
					and   d2.data_cancellazione is null
                    and   sog.data_cancellazione is null
					and   e2.data_cancellazione is null
                    and   oil.data_cancellazione is null
                    and   roil.data_cancellazione is null
                    and   rel.data_cancellazione is null
                    and   mdp.data_cancellazione is null
                    and   accre.data_cancellazione is null
                    and   roil.validita_fine is null
					and   now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
                    and   now() BETWEEN d2.validita_inizio and coalesce (d2.validita_fine,now())
                    and   now() BETWEEN rel.validita_inizio and coalesce (rel.validita_fine,now())
                    and   now() BETWEEN mdp.validita_inizio and coalesce (mdp.validita_fine,now())
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
			),
            -- 11.07.2018 Sofia jira siac-6193
            liquidazione as
            (
              with
              liq as
              (
				select r.sord_id ord_ts_id,
					   r.liq_id
				from  siac_r_liquidazione_ord r
				where r.ente_proprietario_id=enteProprietarioId
                and   r.data_cancellazione is null
				and   now() BETWEEN r.validita_inizio and COALESCE(r.validita_fine,now())
              ),
              liq_atto as --15 sec
              (
              	select rliq.liq_id,
                       coalesce(alg.attoal_causale , atto.attoamm_oggetto) liq_attoamm_desc,
                  	   alg.data_creazione liq_attoalg_data_inserimento,
                       alg.attoal_data_scadenza liq_attoalg_data_scad,
                       algstato.attoal_stato_desc liq_attoalg_stato_desc
        	    from siac_r_liquidazione_atto_amm rliq,
            	     siac_t_atto_amm atto
                	 left join siac_t_atto_allegato alg
                     join siac_r_atto_allegato_stato rsalg
                     join siac_d_atto_allegato_stato algstato on (algstato.attoal_stato_id=rsalg.attoal_stato_id and algstato.attoal_stato_code!='A')
                     on (rsalg.attoal_id=alg.attoal_id and rsalg.data_cancellazione is null and now() between rsalg.validita_inizio and coalesce(rsalg.validita_fine, now()))
                     on ( alg.attoamm_id=atto.attoamm_id )
	             where atto.ente_proprietario_id= enteProprietarioId
                 and   rliq.attoamm_id=atto.attoamm_id
	             and   rliq.data_cancellazione is null
     		     and   rliq.validita_fine is null
            	 and   atto.data_cancellazione is null
	             and   now() between atto.validita_inizio and coalesce(atto.validita_fine, now())
              )
              select liq.*,
                     liq_atto.liq_attoamm_desc,
                     liq_atto.liq_attoalg_data_inserimento,
                     liq_atto.liq_attoalg_data_scad,
                     liq_atto.liq_attoalg_stato_desc
              from liq left join liq_atto on (liq.liq_id=liq_atto.liq_id)
			),
            -- 11.07.2018 Sofia jira siac-6193
            split as
            (
              select distinct
                     rsub.ord_ts_id
              from 	siac_r_subdoc_ordinativo_ts rsub,
                    siac_t_subdoc sub,siac_r_subdoc_splitreverse_iva_tipo rsplit,
                    siac_d_splitreverse_iva_tipo tipo
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.sriva_tipo_code!='ES'
              and   rsplit.sriva_tipo_id=tipo.sriva_tipo_id
              and   sub.subdoc_id=rsplit.subdoc_id
              and   rsub.subdoc_id=sub.subdoc_id
              and   rsub.data_cancellazione is null
              and   rsub.validita_fine is null
              and   sub.data_cancellazione is null
              and   sub.validita_fine is null
              and   rsplit.data_cancellazione is null
              and   rsplit.validita_fine is null
            ),
            -- 11.07.2018 Sofia jira siac-6193
            split_importo as
            (
            	select rord.ord_id_da ord_id,
                	   coalesce(sum(coalesce(det.ord_ts_det_importo,0)),0) importo
                from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                     siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato,
                     siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
				where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.relaz_tipo_code='SPR'
                and   tipo.relaz_tipo_id=rord.relaz_tipo_id
			    and   rstato.ord_id=rOrd.ord_id_a
                and   stato.ord_stato_id=rstato.ord_stato_id
				and   stato.ord_stato_code!='A'
                and   ts.ord_id=rstato.ord_id
                and   det.ord_ts_id=ts.ord_ts_id
       	        and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
                and   tipod.ord_ts_det_tipo_code='A'
                and   rord.data_cancellazione is null
			    and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   				and   rstato.data_cancellazione is null
				and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
   				and   ts.data_cancellazione is null
                and   ts.validita_fine is null
   				and   det.data_cancellazione is null
                and   det.validita_fine is null
                group by rord.ord_id_da
            ),
            -- 11.07.2018 Sofia jira siac-6193
            ritenute as
            (
             select distinct ts.ord_ts_id
             from siac_r_doc_onere  rdoc, siac_t_subdoc doc, siac_r_subdoc_ordinativo_ts ts,
                  siac_d_onere_tipo tipo,siac_d_onere onere
	  		 where   tipo.ente_proprietario_id=enteProprietarioId
               and   tipo.onere_tipo_code not in ('SP','ES')
               and   onere.onere_tipo_id=tipo.onere_tipo_id
               and   rdoc.onere_id=onere.onere_id
               and   doc.doc_id=rdoc.doc_id
               and   ts.subdoc_id=doc.subdoc_id
			   and   rdoc.data_cancellazione is null
               and   now() between rdoc.validita_inizio and coalesce(rdoc.validita_fine, now())
               and   doc.data_cancellazione is null
	     	   and   doc.validita_fine is null
               and   ts.data_cancellazione is null
               and   now() between ts.validita_inizio and coalesce(ts.validita_fine, now())
            ),
            -- 11.07.2018 Sofia jira siac-6193
            ritenute_importo as --ok
            (
             select rOrd.ord_id_da ord_id,coalesce(sum(coalesce(det.ord_ts_det_importo,0)),0)  importo
             from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                  siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato,
  	              siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
			 where  tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.relaz_tipo_code='RIT_ORD'
			  and   tipo.relaz_tipo_id=rord.relaz_tipo_id
			  and   rstato.ord_id=rOrd.ord_id_a
	          and   stato.ord_stato_id=rstato.ord_stato_id
	    	  and   stato.ord_stato_code!='A'
	          and   ts.ord_id=rstato.ord_id
    	      and   det.ord_ts_id=ts.ord_ts_id
        	  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
              and   tipod.ord_ts_det_tipo_code='A'
	          and   rord.data_cancellazione is null
 		  	  and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   			  and   rstato.data_cancellazione is null
			  and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
	   		  and   ts.data_cancellazione is null
    	      and   ts.validita_fine is null
   			  and   det.data_cancellazione is null
              and   det.validita_fine is null
              group by rOrd.ord_id_da
            ),
            -- 11.07.2018 Sofia jira siac-6193
            conto_tesoreria as
            (
             select d.contotes_id, d.contotes_code
             from siac_d_contotesoreria d
             where d.ente_proprietario_id=enteProprietarioId
            ),
            -- 11.07.2018 Sofia jira siac-6193
            distinta as
            (
             select dist.dist_id,
                    dist.dist_code,
                    dist.dist_desc
             from siac_d_distinta dist
             where dist.ente_proprietario_id=enteProprietarioId
            )
			select ordinativo.*,
                   soggetto.*,
                   attoamm.*,
                   capitolo.*,
                   modpag.*,
                   liquidazione.*,
                   -- 11.07.2018 Sofia jira siac-6193
                   ( case when split.ord_ts_id is not null then 'S' else 'N' end)::varchar ord_split,
                   split_importo.importo ord_split_importo,
                   -- 11.07.2018 Sofia jira siac-6193
                   ( case when ritenute.ord_ts_id is not null then 'S' else 'N' end)::varchar ord_ritenute,
                   ritenute_importo.importo ord_ritenute_importo,
                   conto_tesoreria.contotes_code ord_conto_tesoreria,
                   distinta.dist_code ord_distinta_codice,
                   distinta.dist_desc ord_distinta_desc
			from
				           ordinativo
				CROSS JOIN soggetto
				CROSS JOIN attoamm
				CROSS JOIN capitolo
				LEFT OUTER JOIN modpag on  (ordinativo.uid=modpag.ord_id)
                -- 11.07.2018 Sofia jira siac-6193
                left join liquidazione on (ordinativo.ord_ts_id=liquidazione.ord_ts_id)
                left join split on (ordinativo.ord_ts_id=split.ord_ts_id)
                left join split_importo on (ordinativo.uid=split_importo.ord_id)
                left join ritenute on (ordinativo.ord_ts_id=ritenute.ord_ts_id)
                left join ritenute_importo on (ordinativo.uid=ritenute_importo.ord_id)
                left join  conto_tesoreria on (conto_tesoreria.contotes_id=ordinativo.contotes_id)
                left join  distinta on (distinta.dist_id=ordinativo.dist_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
            and y.ente_proprietario_id = enteProprietarioId
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		),
        -- 11.07.2018 Sofia jira siac-6193
        carte_contabili as
        (
           select  distinct rcs.soggetto_id
           from  siac_r_cartacont_det_soggetto rcs,
                 siac_t_cartacont_det det, siac_t_cartacont carta,
                 siac_r_cartacont_stato rs,siac_d_cartacont_stato stato
	       where   det.ente_proprietario_id=enteProprietarioId
             and   det.cartac_det_id=rcs.cartac_det_id
             and   carta.cartac_id=det.cartac_id
             and   rs.cartac_id=carta.cartac_id
             and   stato.cartac_stato_id=rs.cartac_stato_id
             and   stato.cartac_stato_code!='A'
             and   rcs.data_cancellazione is null
             and   now() between rcs.validita_inizio and coalesce(rcs.validita_fine, now())
             and   rs.data_cancellazione is null
             and   now() between rs.validita_inizio and coalesce(rs.validita_fine, now())
             and   carta.data_cancellazione is null
             and   carta.validita_fine is null
             and   det.data_cancellazione is null
             and   det.validita_fine is null
        )
		select ord_join.*,
        	   sac_attoamm.*,
               (case when carte_contabili.soggetto_id is not null then 'S' else 'N' end ) sog_carte_contabili
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
        -- 11.07.2018 Sofia jira siac-6193
        left outer join carte_contabili on ord_join.soggetto_id=carte_contabili.soggetto_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
        and b2.ente_proprietario_id = enteProprietarioId
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	),quietanza AS(
     --SIAC-5899
      SELECT
          siac_T_Ordinativo.ord_id,
          siac_r_ordinativo_quietanza.ord_quietanza_data
      FROM
          siac_t_oil_ricevuta
          ,siac_T_Ordinativo
          ,siac_d_oil_ricevuta_tipo
          ,siac_r_ordinativo_quietanza
      WHERE
              siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
          AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
		  --SIAC-8897
		  AND siac_t_oil_ricevuta.oil_ricevuta_id =siac_r_ordinativo_quietanza.oil_ricevuta_id
          AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
          and siac_T_Ordinativo.ente_proprietario_id = enteProprietarioId
          AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
          AND siac_t_oil_ricevuta.data_cancellazione is null
          AND siac_T_Ordinativo.data_cancellazione is null
          AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
          AND siac_r_ordinativo_quietanza.data_cancellazione is null
    )
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
        -- 12.07.2018 Sofia siac-6193
		ord_join_outer.soggetto_code ord_soggetto_code,
		ord_join_outer.soggetto_desc ord_soggetto_desc,
        -- 11.07.2018 Sofia jira siac-6193
        --		ord_join_outer.accredito_tipo_code,
        --		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida,
		quietanza.ord_quietanza_data,
        -- 11.07.2018 Sofia jira siac-6193
        ord_join_outer.sog_codice_fiscale,
  		ord_join_outer.sog_partita_iva,
        -- MDP  - no cessione
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.accredito_tipo_code else null end ) ord_accredito_tipo_code,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.accredito_tipo_desc else null end ) ord_accredito_tipo_desc,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.iban else null end ) ord_iban,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.bic else null end ) ord_bic,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.contocorrente else null end ) ord_contocorrente,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.contocorrente_intestazione else null end ) ord_contocorrente_intestazione,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.banca_denominazione else null end ) ord_banca_denominazione,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.quietanziante else null end ) ord_quietanzante,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.quietanziante_codice_fiscale else null end ) ord_quietanzante_codice_fiscale,
        -- estremi cessione
	    ord_join_outer.soggetto_cessione_code ord_soggetto_cessione_code,
        ord_join_outer.soggetto_cessione_desc ord_soggetto_cessione_desc,
        ord_join_outer.relaz_tipo_code ord_relaz_tipo_code,
        ord_join_outer.relaz_tipo_desc ord_relaz_tipo_desc,
        -- MDP - cessione
		(case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.accredito_tipo_code else null end ) ord_accredito_tipo_code_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.accredito_tipo_desc else null end ) ord_accredito_tipo_desc_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.iban else null end ) ord_iban_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.bic else null end ) ord_bic_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.contocorrente else null end ) ord_contocorrente_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.contocorrente_intestazione else null end ) ord_contocorrente_intestazione_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.banca_denominazione else null end ) ord_banca_denominazione_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.quietanziante else null end ) ord_quietanzante_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.quietanziante_codice_fiscale else null end ) ord_quietanzante_codice_fiscale_cess,
		ord_join_outer.liq_attoamm_desc,
        ord_join_outer.liq_attoalg_data_inserimento,
        ord_join_outer.liq_attoalg_data_scad,
        ord_join_outer.liq_attoalg_stato_desc,
        ord_join_outer.ord_split,
        ord_join_outer.ord_split_importo,
        ord_join_outer.ord_ritenute,
        ord_join_outer.ord_ritenute_importo,
        ord_join_outer.sog_carte_contabili::varchar carte_contabili,
        (case when provv_cassa.provc_numero is not null then 'S' else 'N' end )::varchar ord_copertura,
        ord_join_outer.ord_conto_tesoreria,
        ord_join_outer.ord_distinta_codice,
        ord_join_outer.ord_distinta_desc


	from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
    	left outer join quietanza on ord_join_outer.uid=quietanza.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$function$
;
 -- 31.01.2023 Alessandra SIAC-8897 - fine  
 
 -- 31.01.2023 Sofia SIAC-8898 - inizio 
 DROP  FUNCTION IF EXISTS
fnc_fasi_bil_gest_ribaltamento_vincoli
(
  p_tipo_ribaltamento varchar, --'GEST-GEST' 'PREV-GEST'
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_ribaltamento_vincoli (
  p_tipo_ribaltamento varchar, --'GEST-GEST' 'PREV-GEST'
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
) returns RECORD
AS
  $body$
  DECLARE
    strmessaggio       			VARCHAR(1500)	:='';
    strmessaggiofinale 			VARCHAR(1500)	:='';
    bilelemidret           		INTEGER  		:=NULL;
    codresult              		INTEGER  		:=NULL;
    datainizioval 				timestamp		:=NULL;
    fasebilelabid    			INTEGER  		:=NULL;
    categoriacapcode 			VARCHAR  		:=NULL;
    bilelemstatoanid 			INTEGER  		:=NULL;
    ape_prev_da_gest            CONSTANT VARCHAR:='APE_PREV';
    --v_dataprimogiornoanno 		timestamp		:=NULL;
    rec_vincoli_prev            RECORD;
    rec_vincoli_gest  			RECORD;
    rec_capitoli_gest 			RECORD;
    rec_capitoli_prev 			RECORD;
    _row_count 					INTEGER;

    --v_vincolo_tipo_id_prev      INTEGER;
    v_vincolo_tipo_id_gest      INTEGER;

    v_bilancio_id          		INTEGER;
    v_bilancio_id_prec     		INTEGER;

    v_periodo_id           		INTEGER;
    v_periodo_id_prec      		INTEGER;

    v_vincolo_id                INTEGER;
    v_elem_id                   INTEGER;
    v_elem_tipo_code            VARCHAR;
    v_elem_tipo_id              INTEGER;
  BEGIN
    messaggiorisultato:='';
    codicerisultato:=0;
    fasebilelabidret:=0;
    datainizioval:= clock_timestamp();
    --v_dataprimogiornoanno:= (p_annobilancio||'-01-01')::timestamp;
    strmessaggiofinale:='Ribaltamento Vincoli.';

    -- inserimento fase_bil_t_elaborazione
    strmessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    INSERT INTO fase_bil_t_elaborazione
    (
      fase_bil_elab_esito,
      fase_bil_elab_esito_msg,
      fase_bil_elab_tipo_id,
      ente_proprietario_id,
      validita_inizio,
      login_operazione
    )
    (
    SELECT 'IN', 'ELABORAZIONE FASE BILANCIO  IN CORSO : RIBALTAMENTO VINCOLI.',
        tipo.fase_bil_elab_tipo_id,
        p_enteproprietarioid,
        datainizioval,
        p_loginoperazione
    FROM
    	fase_bil_d_elaborazione_tipo tipo
    WHERE  tipo.ente_proprietario_id=p_enteproprietarioid
    AND    tipo.fase_bil_elab_tipo_code='APE_GEST_VINCOLI'
    AND    tipo.data_cancellazione IS NULL
    AND    tipo.validita_fine IS NULL)
    returning   fase_bil_elab_id
    INTO        fasebilelabid;


    IF fasebilelabid IS NULL THEN
      RAISE EXCEPTION ' Inserimento non effettuato.';
    END IF;

    faseBilElabIdRet:= fasebilelabid;
    codresult:=NULL;
    INSERT INTO fase_bil_t_elaborazione_log
    (
      fase_bil_elab_id,
      fase_bil_elab_log_operazione,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )VALUES(
      fasebilelabid,
      strmessaggio,
      clock_timestamp(),
      p_loginoperazione,
      p_enteproprietarioid
    ) returning   fase_bil_elab_log_id INTO        codresult;

    IF codresult IS NULL THEN
      RAISE EXCEPTION ' Errore in inserimento LOG.';
    END IF;




	--inizio procedura
    strmessaggio:='estraggo il periodo del bilancio in esame = anno-->'||p_annobilancio||'.';
    begin
      select per.periodo_id,bil.bil_id
      into strict v_periodo_id ,v_bilancio_id
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( previsione) anno'||p_annobilancio||'.';
		 return;
	end;

    strmessaggio:='estraggo il periodo del bilancio anno precedente periodo_code = anno'||p_annobilancio-1||'.';
    begin
      select per.periodo_id,bil.bil_id
      into strict v_periodo_id_prec ,v_bilancio_id_prec
      from siac_t_periodo per, siac_t_bil bil
      where  bil.ente_proprietario_id=p_enteproprietarioid
      and    per.periodo_id=bil.periodo_id
      and    per.anno::integer = p_annobilancio-1;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' periodo inesistente siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' troppi periodi x siac_t_periodo ( prec gestione) anno'||p_annobilancio-1||'.';
		 return;
	end;


    strmessaggio:='vincolo_tipo_id dei vincoli nuovi di gestione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_gest
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'G'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code G.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code G.';
		 return;
	end;
/*
    strmessaggio:='vincolo_tipo_id dei vincoli di previsione .';
	begin
      select siac_d_vincolo_tipo.vincolo_tipo_id
      into  strict v_vincolo_tipo_id_prev
      from  siac_d_vincolo_tipo
      where siac_d_vincolo_tipo.ente_proprietario_id = p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_code    = 'P'
      and   siac_d_vincolo_tipo.data_cancellazione is null;
    exception
		when NO_DATA_FOUND then
		 messaggiorisultato:=' vincolo_tipo_id inesistente con code P.';
		 return;
		when TOO_MANY_ROWS THEN
		 messaggiorisultato:=' vincolo_tipo_id troppi con code P.';
		 return;
	end;
*/

   /* execute 'CREATE TABLE IF NOT EXISTS siac_t_vincolo_tmp(id INTEGER);';

    strmessaggio:='cancello eventuale ribaltamento fatto precedentemente';
    delete from siac_r_vincolo_bil_elem using siac_t_vincolo_tmp 	where  siac_r_vincolo_bil_elem.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_genere using siac_t_vincolo_tmp 		where  siac_r_vincolo_genere.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_attr using siac_t_vincolo_tmp 		where  siac_r_vincolo_attr.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_stato using siac_t_vincolo_tmp 		where  siac_r_vincolo_stato.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_t_vincolo using siac_t_vincolo_tmp 			where  siac_t_vincolo.vincolo_id = siac_t_vincolo_tmp.id ;

    -- pulisco la tabella di bck
    execute 'delete from siac_t_vincolo_tmp;';*/


    -- pulizia dati presenti
    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_bil_elem.';
    update siac_r_vincolo_bil_elem r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_attr.';
    update siac_r_vincolo_attr r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_genere.';
    update siac_r_vincolo_genere r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - inizio
	strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_risorse_vincolate.';
    update siac_r_vincolo_risorse_vincolate r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;
 	-- 05.03.2021 Sofia Jira SIAC-790 - fine


    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_r_vincolo_stato.';
    update siac_r_vincolo_stato r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di gestione. Cancellazione logica siac_t_vincolo.';
    update siac_t_vincolo v
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=v.login_operazione||'-'||p_loginoperazione
    from siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='G'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id
    and   v.data_cancellazione is null
    and   v.validita_fine is null;

	strmessaggio:='ribalto da gestione anno precedente a gestione anno in esame';
	if p_tipo_ribaltamento = 'GEST-GEST' THEN

            strmessaggio:='inizio ciclo sui vincoli di gestione anno precedente';
            FOR rec_vincoli_gest IN(
               select
                   siac_t_vincolo.vincolo_id
                  ,siac_t_vincolo.vincolo_code
                  ,siac_t_vincolo.vincolo_desc
                  ,siac_t_vincolo.vincolo_tipo_id
                  ,siac_t_vincolo.periodo_id
    --              ,siac_d_vincolo_genere.vincolo_gen_id
              from
                   siac_t_vincolo
                  ,siac_d_vincolo_tipo
                  ,siac_r_vincolo_stato
                  ,siac_d_vincolo_stato
--                  ,siac_r_vincolo_genere
  --                ,siac_d_vincolo_genere
              where
                    siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
              and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
              and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
              and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--              and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id
--              and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id
              and   siac_d_vincolo_stato.vincolo_stato_code!='A'
              and   siac_d_vincolo_tipo.vincolo_tipo_code='G'
              and   siac_t_vincolo.periodo_id = v_periodo_id_prec
              and 	siac_r_vincolo_stato.data_cancellazione is null
              and 	siac_r_vincolo_stato.validita_fine is null
              and 	siac_t_vincolo.data_cancellazione is null
              and 	siac_t_vincolo.validita_fine is null
--              and   siac_r_vincolo_genere.data_cancellazione is null

            )LOOP

                strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_gest '||v_vincolo_tipo_id_gest||' v_periodo_id '||v_periodo_id||'.';

                insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
                )VALUES(
                   rec_vincoli_gest.vincolo_code
                  ,rec_vincoli_gest.vincolo_desc
                  ,v_vincolo_tipo_id_gest
                  ,v_periodo_id
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                ) returning   vincolo_id INTO v_vincolo_id;

                --mi tengo un bck per sicurezza
                -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

                strmessaggio:='inserimento del genere.';
                insert into siac_r_vincolo_genere
                ( vincolo_id,
                  vincolo_gen_id,
                  validita_inizio,
                  ente_proprietario_id,
                  login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_gen_id
                  ,now()
                  ,p_enteproprietarioid
                  ,p_loginoperazione
                from siac_r_vincolo_genere r
                where r.vincolo_id=rec_vincoli_gest.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );

                -- 05.03.2021 Sofia Jira SIAC-790 - inizio
                strmessaggio:='inserimento risorse.';
                insert into siac_r_vincolo_risorse_vincolate
                (vincolo_id,
                 vincolo_risorse_vincolate_id,
                 validita_inizio,
                 ente_proprietario_id,
                 data_creazione,
                 login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_risorse_vincolate_id
                  ,now()
                  ,p_enteproprietarioid
                  ,now()
                  ,p_loginoperazione
                from siac_r_vincolo_risorse_vincolate r
                where r.vincolo_id=rec_vincoli_gest.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
                -- 05.03.2021 Sofia Jira SIAC-790 - fine

                strmessaggio:='inserimento attributi sul vincolo.';
                insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
                select
                   v_vincolo_id
                  ,attr_id
                  ,tabella_id
                  ,boolean
                  ,percentuale
                  ,testo
                  ,numerico
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                from
                    siac_r_vincolo_attr
                where
                    siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
                and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_gest.vincolo_id
                and siac_r_vincolo_attr.data_cancellazione is null
                and siac_r_vincolo_attr.validita_fine is null;

                strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
                insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
                select
                   v_vincolo_id
                  ,vincolo_stato_id
                  ,now()
                  ,null
                  ,p_enteproprietarioid
                  ,now()
                  ,now()
                  ,null
                  ,p_loginoperazione
                from
                siac_r_vincolo_stato
                 where
                    siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
                and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_gest.vincolo_id
                and siac_r_vincolo_stato.data_cancellazione is null
                and siac_r_vincolo_stato.validita_fine is null;


                strmessaggio:='ciclo capitoli di gestione da ribaltare di  anno precedente .';
                FOR rec_capitoli_gest IN(
   /*               select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                  where
                      siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                  and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                  and siac_t_bil_elem.bil_id          =  v_bilancio_id_prec
                  and siac_r_vincolo_bil_elem.data_cancellazione is null
                  and siac_r_vincolo_bil_elem.validita_fine is null
                  and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_gest.vincolo_id
                  and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
SIAC-8099 Sofia 22.04.2021                  */
-- SIAC-8099 Sofia 22.04.2021
                  select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem r,
                       siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                       siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                  where r.ente_proprietario_id = p_enteproprietarioid
                  and   r.elem_id =  e.elem_id
                  and   e.elem_tipo_id    =  tipo.elem_tipo_id
                  and   e.bil_id          =  v_bilancio_id_prec
                  and   r.vincolo_id = rec_vincoli_gest.vincolo_id
                  and   rs.elem_id=e.elem_id
                  and   stato.elem_stato_id=rs.elem_stato_id
                  and   stato.elem_stato_code!='AN'
                  and   r.data_cancellazione is null
                  and   r.validita_fine is null
                  and   rs.data_cancellazione is null
                  and   rs.validita_fine is null
                  and   e.data_cancellazione is null
                  and   e.validita_fine is null
                )LOOP

                    strmessaggio:='estraggo il tipo nuovo di prev.';
                    raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_gest.elem_tipo_code,rec_capitoli_gest.elem_code,rec_capitoli_gest.elem_id;

                    select elem_tipo_id into strict v_elem_tipo_id
                    from siac_d_bil_elem_tipo
                    where
                    ente_proprietario_id = p_enteproprietarioid
                    and elem_tipo_code = rec_capitoli_gest.elem_tipo_code;

                    v_elem_id:=null;
                    strmessaggio:='estraggo elem_id v_elem_tipo_id '|| v_elem_tipo_id::varchar||' rec_capitoli_gest.elem_code '||rec_capitoli_gest.elem_code||' rec_capitoli_gest.elem_code2 '||rec_capitoli_gest.elem_code2||' rec_capitoli_gest.elem_code3 '||rec_capitoli_gest.elem_code3||'.';
--                    select siac_t_bil_elem.elem_id into strict v_elem_id
/* 29.04.2021 Sofia Jira SIAC-8099
                    select siac_t_bil_elem.elem_id into v_elem_id
                    FROM   siac_t_bil_elem,siac_t_bil
                    where
                        siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                    and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                    and siac_t_bil_elem.elem_code      = rec_capitoli_gest.elem_code
                    and siac_t_bil_elem.elem_code2     = rec_capitoli_gest.elem_code2
                    and siac_t_bil_elem.elem_code3     = rec_capitoli_gest.elem_code3
                    and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                    and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/

					-- 29.04.2021 Sofia Jira SIAC-8099
					select e.elem_id into v_elem_id
                    FROM   siac_t_bil_elem e,siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
                           siac_t_bil bil
                    where e.ente_proprietario_id = p_enteproprietarioid
                    and   e.elem_tipo_id   = v_elem_tipo_id
                    and   e.bil_id         = bil.bil_id
                    and   bil.bil_code     = 'BIL_'||p_annobilancio
                    and   e.elem_code      = rec_capitoli_gest.elem_code
                    and   e.elem_code2     = rec_capitoli_gest.elem_code2
                    and   e.elem_code3     = rec_capitoli_gest.elem_code3
                    and   rs.elem_id       = e.elem_id
                    and   stato.elem_stato_id=rs.elem_Stato_id
                    and   stato.elem_stato_code!='AN'
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null;

					if v_elem_id is not null then
                     strmessaggio:='inizio inserimenti per i capitoli .';
                     raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code,rec_capitoli_gest.elem_code,v_elem_id;

                     insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
                     )values(
                         v_vincolo_id
                        ,v_elem_id
                        ,now()
                        ,null
                        ,p_enteproprietarioid
                        ,now()
                        ,now()
                        ,null
                        ,p_loginoperazione
                     );
                    end if;


                end LOOP;
            end LOOP;
 	end if;

	--ribalto da previsione anno in esame a gestione anno in esame

	if p_tipo_ribaltamento = 'PREV-GEST' THEN
    	      strmessaggio:='ribaltamento da previsiione a gestione dello stesso anno';
              FOR rec_vincoli_prev IN(
                 select
                     siac_t_vincolo.vincolo_id
                    ,siac_t_vincolo.vincolo_code
                    ,siac_t_vincolo.vincolo_desc
                    ,siac_t_vincolo.vincolo_tipo_id
                    ,siac_t_vincolo.periodo_id
--                    ,siac_d_vincolo_genere.vincolo_gen_id
                from
                     siac_t_vincolo
                    ,siac_d_vincolo_tipo
                    ,siac_r_vincolo_stato
                    ,siac_d_vincolo_stato
--                    ,siac_r_vincolo_genere
--                    ,siac_d_vincolo_genere
                where
                      siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
                and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
                and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
                and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--                and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id
--                and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id
                and   siac_d_vincolo_stato.vincolo_stato_code!='A'
                and   siac_d_vincolo_tipo.vincolo_tipo_code='P'
                and   siac_t_vincolo.periodo_id = v_periodo_id
                and 	siac_r_vincolo_stato.data_cancellazione is null
                and 	siac_r_vincolo_stato.validita_fine is null
                and 	siac_t_vincolo.data_cancellazione is null
                and 	siac_t_vincolo.validita_fine is null
  --              and   siac_r_vincolo_genere.data_cancellazione is null

              )LOOP

                  strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_gest '||v_vincolo_tipo_id_gest||' v_periodo_id '||v_periodo_id||'.';
                  insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
                  )VALUES(
                     rec_vincoli_prev.vincolo_code
                    ,rec_vincoli_prev.vincolo_desc
                    ,v_vincolo_tipo_id_gest
                    ,v_periodo_id
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  ) returning   vincolo_id INTO v_vincolo_id;

                  --mi tengo un bck per sicurezza
                 -- execute 'insert into siac_t_vincolo_tmp (id) values('||v_vincolo_id||');';

                  strmessaggio:='inserimento del genere.';
                  insert into siac_r_vincolo_genere
                  ( vincolo_id,
                    vincolo_gen_id,
                    validita_inizio,
                    ente_proprietario_id,
                    login_operazione
                  )
                  (
                  select
                     v_vincolo_id
                    ,r.vincolo_gen_id
                    ,now()
                    ,p_enteproprietarioid
                    ,p_loginoperazione
                  from siac_r_vincolo_genere r
                  where r.vincolo_id=rec_vincoli_prev.vincolo_id
                  and   r.data_cancellazione is null
                  and   r.validita_fine is null
                  );

				-- 20.04.2021 Sofia Jira 	SIAC-8099 - inizio
                strmessaggio:='inserimento risorse.';
                insert into siac_r_vincolo_risorse_vincolate
                (vincolo_id,
                 vincolo_risorse_vincolate_id,
                 validita_inizio,
                 ente_proprietario_id,
                 data_creazione,
                 login_operazione
                )
                (
                select
                   v_vincolo_id
                  ,r.vincolo_risorse_vincolate_id
                  ,now()
                  ,p_enteproprietarioid
                  ,now()
                  ,p_loginoperazione
                from siac_r_vincolo_risorse_vincolate r
                where r.vincolo_id=rec_vincoli_prev.vincolo_id
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                );
                -- 20.04.2021 Sofia Jira 	SIAC-8099 - fine

                  strmessaggio:='inserimento attributi sul vincolo.';
                  insert into siac_r_vincolo_attr (vincolo_id,attr_id,tabella_id,boolean ,percentuale,testo,numerico,validita_inizio ,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione,login_operazione)
                  select
                     v_vincolo_id
                    ,attr_id
                    ,tabella_id
                    ,boolean
                    ,percentuale
                    ,testo
                    ,numerico
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  from
                      siac_r_vincolo_attr
                  where
                      siac_r_vincolo_attr.ente_proprietario_id = p_enteproprietarioid
                  and siac_r_vincolo_attr.vincolo_id =  rec_vincoli_prev.vincolo_id
                  and siac_r_vincolo_attr.data_cancellazione is null
                  and siac_r_vincolo_attr.validita_fine is null;

                  strmessaggio:='inserimento dello stato siac_r_vincolo_stato.';
                  insert into siac_r_vincolo_stato (vincolo_id,vincolo_stato_id,validita_inizio,validita_fine ,ente_proprietario_id ,data_creazione,data_modifica,data_cancellazione,login_operazione)
                  select
                     v_vincolo_id
                    ,vincolo_stato_id
                    ,now()
                    ,null
                    ,p_enteproprietarioid
                    ,now()
                    ,now()
                    ,null
                    ,p_loginoperazione
                  from
                  siac_r_vincolo_stato
                   where
                      siac_r_vincolo_stato.ente_proprietario_id = p_enteproprietarioid
                  and siac_r_vincolo_stato.vincolo_id =  rec_vincoli_prev.vincolo_id
                  and siac_r_vincolo_stato.data_cancellazione is null
                  and siac_r_vincolo_stato.validita_fine is null;


                  strmessaggio:='ciclo capitoli di previsione da ribaltare dello stesso anno .';
                  FOR rec_capitoli_prev IN(
/*
                    select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                    from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                    where
                        siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                    and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.bil_id          =  v_bilancio_id
                    and siac_r_vincolo_bil_elem.data_cancellazione is null
                    and siac_r_vincolo_bil_elem.validita_fine is null
                    and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_prev.vincolo_id
                    and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
SIAC-8099 Sofia 22.04.2021                    */
-- SIAC-8099 Sofia 22.04.2021
                    select e.elem_id,e.elem_code,e.elem_code2,e.elem_code3 ,tipo.elem_tipo_code
                    from siac_r_vincolo_bil_elem r, siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
                         siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                    where r.ente_proprietario_id = p_enteproprietarioid
                    and   r.elem_id =  e.elem_id
                    and   e.elem_tipo_id    =  tipo.elem_tipo_id
                    and   e.bil_id          =  v_bilancio_id
                    and   r.vincolo_id = rec_vincoli_prev.vincolo_id
					--    02.01.2023 Sofia SIAC-8878
                    --and   rs.elemid=e.elem_id
					and   rs.elem_id=e.elem_id
                    and   stato.elem_stato_id=rs.elem_stato_id
                    and   stato.elem_stato_code!='AN'
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   e.data_cancellazione is null
                    and   e.validita_fine is null
                  )LOOP

                      strmessaggio:='deduco il codice del capitolo di gestione nuovo.';

                      if rec_capitoli_prev.elem_tipo_code = 'CAP-UP' THEN
                          v_elem_tipo_code := 'CAP-UG';
                      elseif rec_capitoli_prev.elem_tipo_code = 'CAP-EP' THEN
                          v_elem_tipo_code := 'CAP-EG';
                      end if;

                      strmessaggio:='estraggo il tipo nuovo di prev.';
                      raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_prev.elem_tipo_code,rec_capitoli_prev.elem_code,rec_capitoli_prev.elem_id;
                      select elem_tipo_id into strict v_elem_tipo_id
                      from siac_d_bil_elem_tipo
                      where
                      ente_proprietario_id = p_enteproprietarioid
                      and elem_tipo_code = v_elem_tipo_code ;

                      strmessaggio:='estraggo elem_id v_elem_tipo_id '|| v_elem_tipo_id::varchar||' rec_capitoli_prev.elem_code '||rec_capitoli_prev.elem_code||' rec_capitoli_prev.elem_code2 '||rec_capitoli_prev.elem_code2||' rec_capitoli_prev.elem_code3 '||rec_capitoli_prev.elem_code3||'.';

--                      select siac_t_bil_elem.elem_id into strict v_elem_id
                      v_elem_id:=null;
/* 29.04.2021 Sofia Jira SIAC-8099
                      select siac_t_bil_elem.elem_id into v_elem_id
                      FROM   siac_t_bil_elem,siac_t_bil
                      where
                          siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                      and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                      and siac_t_bil_elem.elem_code      = rec_capitoli_prev.elem_code
                      and siac_t_bil_elem.elem_code2     = rec_capitoli_prev.elem_code2
                      and siac_t_bil_elem.elem_code3     = rec_capitoli_prev.elem_code3
                      and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                      and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;*/
					  -- 29.04.2021 Sofia Jira SIAC-8099
                      --select siac_t_bil_elem.elem_id into v_elem_id
					  -- 02.01.2023 Sofia Jira and   rs.elemid=e.elem_id
					  select e.elem_id into v_elem_id
                      FROM   siac_t_bil_elem e,siac_t_bil bil,
                             siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato
                      where e.ente_proprietario_id = p_enteproprietarioid
                      and   e.elem_tipo_id   = v_elem_tipo_id
                      and   e.bil_id         = bil.bil_id
                      and   bil.bil_code     = 'BIL_'||p_annobilancio
                      and   e.elem_code      = rec_capitoli_prev.elem_code
                      and   e.elem_code2     = rec_capitoli_prev.elem_code2
                      and   e.elem_code3     = rec_capitoli_prev.elem_code3
                      and   rs.elem_id       =e.elem_id
                      and   stato.elem_stato_id=rs.elem_stato_id
					  -- 31.01.2023 Sofia Jira SIAC-8898
                      --and   stato.elem_stato_code='AN'
					  -- 31.01.2023 Sofia Jira SIAC-8898
					  and   stato.elem_stato_code!='AN'
                      and   rs.data_cancellazione is null
                      and   rs.validita_fine is null
                      and   e.data_cancellazione is null
                      and   e.validita_fine is null;



                      if v_elem_id is not null then
                       strmessaggio:='inizio inserimenti per i capitoli .';
                       raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code,rec_capitoli_prev.elem_code,v_elem_id;

                       insert into siac_r_vincolo_bil_elem ( vincolo_id,elem_id,validita_inizio,validita_fine,ente_proprietario_id,data_creazione,data_modifica,data_cancellazione ,login_operazione
                       )values(
                           v_vincolo_id
                          ,v_elem_id
                          ,now()
                          ,null
                          ,p_enteproprietarioid
                          ,now()
                          ,now()
                          ,null
                          ,p_loginoperazione
                       );
                      end if;

                  end LOOP;
              end LOOP;
/*    ELSE
      	RAISE notice 'PAREAMETRO p_tipo_ribaltamento non valorizzato correttamente valori ammessi GEST-GEST PREV-GEST. ';
      	messaggiorisultato:='PAREAMETRO p_tipo_ribaltamento non valorizzato correttamente valori ammessi GEST-GEST PROV-GEST. ' ;
      	codicerisultato:=-1;
    	return;*/
    end if;
	--Fine procedura

	strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE RIBALTAMENTO VINCOLI TERMINATA.'
    where fase_bil_elab_id=faseBilElabId;

	codResult:=null;
   	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),p_loginoperazione,p_enteproprietarioid)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
       	raise exception ' Errore in inserimento LOG.';
    end if;


    messaggiorisultato := 'vincoli ribaltati correttamente';
    codicerisultato := 0 ;
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

 alter function siac.fnc_fasi_bil_gest_ribaltamento_vincoli (  varchar,  integer,  integer,  varchar,  timestamp,  out integer,  out integer,  out varchar) owner to siac;
 -- 31.01.2023 Sofia SIAC-8898 - fine 
 
 -- 07.02.2023 Sofia SIAC-8762 - inizio 
select * from fnc_dba_add_column_params('siac_dwh_ordinativo_pagamento'::text, 'cod_conto_tes_vincolato'::text, 'VARCHAR(200)'::text); 
select * from fnc_dba_add_column_params('siac_dwh_ordinativo_pagamento'::text, 'descri_conto_tes_vincolato'::text, 'VARCHAR(500)'::text); 
select * from fnc_dba_add_column_params('siac_dwh_ordinativo_incasso'::text, 'cod_conto_tes_vincolato'::text, 'VARCHAR(200)'::text); 
select * from fnc_dba_add_column_params('siac_dwh_ordinativo_incasso'::text, 'descri_conto_tes_vincolato'::text, 'VARCHAR(500)'::text); 

drop FUNCTION if exists siac.fnc_siac_dwh_ordinativo_pagamento 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);
drop  FUNCTION if exists siac.fnc_siac_dwh_ordinativo_incasso 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_pagamento (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

v_user_table varchar;
params varchar;


BEGIN


select fnc_siac_random_user()
into	v_user_table;


IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_ordinativo_pagamento',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico ordinativi in pagamento (fnc_siac_dwh_ordinativo_pagamento) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_pagamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_pagamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;

INSERT INTO siac.siac_dwh_ordinativo_pagamento
 (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_pag,
  num_ord_pag,
  desc_ord_pag,
  cod_stato_ord_pag,
  desc_stato_ord_pag,
  castelletto_cassa_ord_pag,
  castelletto_competenza_ord_pag,
  castelletto_emessi_ord_pag,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  tipo_cessione, -- 04.07.2017 Sofia SIAC-5036
  cod_cessione,  -- 04.07.2017 Sofia SIAC-5036
  desc_cessione, -- 04.07.2017 Sofia SIAC-5036
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_spesa_ricorrente,
  desc_spesa_ricorrente,
  cod_transazione_spesa_ue,
  desc_transazione_spesa_ue,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  --cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordpg,
  data_inizio_val_ordpg,
  data_creazione_ordpg,
  data_modifica_ordpg,
  data_trasmissione,
  cod_siope,
  desc_siope,
  soggetto_csc_id, -- SIAC-5228
  cod_siope_tipo_debito,
  desc_siope_tipo_debito,
  desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione,
  desc_siope_assenza_motivazione,
  desc_siope_assenza_motiv_bnkit,
  ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
  --  20.01.2023 Sofia Jira 	SIAC-8762
  ,cod_conto_tes_vincolato
  ,descri_conto_tes_vincolato
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante,
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban,
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
--tb.tipo_cessione, tb.cod_cessione, tb.desc_cessione, -- 04.07.2017 Sofia SIAC-5036
COALESCE(tb.tipo_cessione, tb.oil_relaz_tipo_code) tipo_cessione, -- SIAC-5228
COALESCE(tb.cod_cessione, tb.relaz_tipo_code) cod_cessione, -- SIAC-5228
COALESCE(tb.desc_cessione, tb.relaz_tipo_desc) desc_cessione, -- SIAC-5228
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
tb.v_codice_spesa_ricorrente, tb.v_descrizione_spesa_ricorrente,
tb.v_codice_transazione_spesa_ue, tb.v_descrizione_transazione_spesa_ue,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla21_classif_tipo_desc,tb.cla21_classif_code,tb.cla21_classif_desc,
tb.cla22_classif_tipo_desc,tb.cla22_classif_code,tb.cla22_classif_desc,
tb.cla23_classif_tipo_desc,tb.cla23_classif_code,tb.cla23_classif_desc,
tb.cla24_classif_tipo_desc,tb.cla24_classif_code,tb.cla24_classif_desc,
tb.cla25_classif_tipo_desc,tb.cla25_classif_code,tb.cla25_classif_desc,
tb.v_flagAllegatoCartaceo,tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo ,
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope,
tb.soggetto_id_da soggetto_csc_id, -- SIAC-5228
tb.siope_tipo_debito_code, tb.siope_tipo_debito_desc, tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code, tb.siope_assenza_motivazione_desc, tb.siope_assenza_motivazione_desc_bnkit,
tb.ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
--  20.01.2023 Sofia Jira 	SIAC-8762
,tb.contotes_code_vinc
,tb.contotes_desc_vinc
from (
with ordinativipag as (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data,
l.siope_tipo_debito_code, l.siope_tipo_debito_desc, l.siope_tipo_debito_desc_bnkit,
m.siope_assenza_motivazione_code, m.siope_assenza_motivazione_desc, m.siope_assenza_motivazione_desc_bnkit,
a.ord_da_trasmettere  -- 20.06.2018 Sofia siac-6175
FROM siac_t_ordinativo a
left join siac_d_siope_tipo_debito l on l.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and l.data_cancellazione is null
                                     and l.validita_fine is null
left join siac_d_siope_assenza_motivazione m on m.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
,siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'P'
--and  a.ord_numero in (6211,7848)
and a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
	   b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id,
	   b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
	   b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
	   c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
	   c.codice_fiscale v_codice_fiscale_soggetto_modpag,
	   c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag,
	   b.accredito_tipo_id,
       null tipo_cessione , -- 04.07.2017 Sofia SIAC-5036
       null cod_cessione  , -- 04.07.2017 Sofia SIAC-5036
       null desc_cessione   -- 04.07.2017 Sofia SIAC-5036
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null -- 13.05.2022 Sofia JIRA SIAC-8599 and b.data_cancellazione is null
and c.data_cancellazione is null
UNION -- 04.07.2017 Sofia SIAC-5036
select a.ord_id, b.modpag_id ,
	   b.soggetto_id v_soggetto_id_modpag,
	   b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
	   b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
	   c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
	   c.codice_fiscale v_codice_fiscale_soggetto_modpag,
	   c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag,
	   b.accredito_tipo_id,
       oil.oil_relaz_tipo_code tipo_cessione,
       tipo.relaz_tipo_code cod_cessione,
       tipo.relaz_tipo_desc desc_cessione
from siac_r_ordinativo_modpag a,siac_r_soggetto_relaz rel, siac_r_soggrel_modpag rmdp,
	 siac_r_oil_relaz_tipo roil,siac_d_oil_relaz_tipo oil,siac_d_relaz_tipo tipo,
	 siac_t_modpag b,siac_t_soggetto c
where a.ente_proprietario_id=p_ente_proprietario_id
and   a.modpag_id is NULL
and   rel.soggetto_relaz_id=a.soggetto_relaz_id
and   rmdp.soggetto_relaz_id=rel.soggetto_relaz_id
and   b.modpag_id=rmdp.modpag_id
and   c.soggetto_id=b.soggetto_id
and   roil.relaz_tipo_id=rel.relaz_tipo_id
and   tipo.relaz_tipo_id=roil.relaz_tipo_id
and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND   p_data BETWEEN rmdp.validita_inizio AND COALESCE(rmdp.validita_fine, p_data)
AND   p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
and   a.data_cancellazione is null
--and   b.data_cancellazione is null -- 13.05.2022 Sofia JIRA SIAC-8599
and   c.data_cancellazione is null
and   rel.data_cancellazione is null
and   rmdp.data_cancellazione is null
and   roil.data_cancellazione is null
),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select mod.*,acc.v_codice_tipo_accredito, acc.v_descrizione_tipo_accredito
 from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as
(
  -- 30.10.2018 Sofia Jira siac-6488 - gestione sedi secondarie
  SELECT c.ord_id,d.soggetto_id,
         d.soggetto_code, da.soggetto_desc||' - '|| d.soggetto_desc soggetto_desc, da.codice_fiscale, da.codice_fiscale_estero, da.partita_iva
  FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d,
	   siac_t_soggetto da
  WHERE  a.ente_proprietario_id=p_ente_proprietario_id
  and    a.relaz_tipo_id = b.relaz_tipo_id
  AND    b.relaz_tipo_code  = 'SEDE_SECONDARIA'
  and    c.soggetto_id=a.soggetto_id_a
  and    da.soggetto_id=a.soggetto_id_da
  and    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and    d.soggetto_id=c.soggetto_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND    da.data_cancellazione IS NULL
  union
  select b.ord_id,a.soggetto_id,
		 a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
  from siac_t_soggetto a, siac_r_ordinativo_soggetto b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.soggetto_id=b.soggetto_id
  and   not exists
  (
  select 1
  from siac_r_soggetto_relaz rel , siac_d_relaz_tipo tipo
  where tipo.ente_proprietario_id=a.ente_proprietario_id
  and   tipo.relaz_tipo_code='SEDE_SECONDARIA'
  and   rel.relaz_tipo_id=tipo.relaz_tipo_id
  and   rel.soggetto_id_a=a.soggetto_id
  AND    p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
  and   rel.data_cancellazione is null
  )
  and   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
select ord_pag.*, bollo.codbollo_code, bollo.codbollo_desc,
--bollo.codbollo_id,
contotes.contotes_code, contotes.contotes_desc,--contotes.contotes_id,
dist.dist_code, dist.dist_desc,--dist.dist_id,
commis.comm_tipo_code, commis.comm_tipo_desc,
--commis.comm_tipo_id ,
bilelem.v_codice_capitolo, bilelem.v_codice_articolo,
bilelem.v_codice_ueb, bilelem.v_descrizione_capitolo ,
bilelem.v_descrizione_articolo,
modpag.modpag_id,modpag.v_soggetto_id_modpag,modpag.v_quietanziante,modpag.v_data_nascita_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic,modpag.v_contocorrente, modpag.v_intestazione_contocorrente,
modpag.v_iban,
modpag.v_note_modalita_pagamento,modpag.v_data_scadenza_modalita_pagamento,
modpag.v_codice_soggetto_modpag, modpag.v_descrizione_soggetto_modpag,
modpag.v_codice_fiscale_soggetto_modpag,
modpag.v_codice_fiscale_estero_soggetto_modpag,modpag.v_partita_iva_soggetto_modpag,
modpag.accredito_tipo_id,
modpag.tipo_cessione, modpag.cod_cessione,modpag.desc_cessione,
modpag.v_codice_tipo_accredito, modpag.v_descrizione_tipo_accredito,
sogg.soggetto_id,sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva
,tipoavviso.v_codice_tipo_avviso, tipoavviso.v_descrizione_tipo_avviso,
ricspesa.v_codice_spesa_ricorrente, ricspesa.v_descrizione_spesa_ricorrente,
transue.v_codice_transazione_spesa_ue, transue.v_descrizione_transazione_spesa_ue
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
)
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla21_classif_tipo_desc,
b.classif_code cla21_classif_code, b.classif_desc cla21_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class22 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla22_classif_tipo_desc,
b.classif_code cla22_classif_code, b.classif_desc cla22_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class23 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla23_classif_tipo_desc,
b.classif_code cla23_classif_code, b.classif_desc cla23_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class24 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla24_classif_tipo_desc,
b.classif_code cla24_classif_code, b.classif_desc cla24_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class25 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla25_classif_tipo_desc,
b.classif_code cla25_classif_code, b.classif_desc cla25_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
	   a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE a.ente_proprietario_id=p_ente_proprietario_id
and   a.ord_ts_id = b.ord_ts_id
AND   c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia jira siac-6499
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
       a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  a.ente_proprietario_id=p_ente_proprietario_id
and    a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia jira siac-6499
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL
AND    a.data_cancellazione IS NULL
and    c.ord_ts_det_tipo_code='A'
GROUP BY
a.ord_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_spesa a,  mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero::integer
      from mif_t_ordinativo_spesa a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero::integer
    ),
      descsiope as (
      select replace(substring(a.classif_code from p_ente_proprietario_id),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'U'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_SPESA_I'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno
    and  mif1.mif_ord_numero::integer=mifmax.mif_ord_numero) as tb
    ),
modpagcsc as ( -- SIAC-5228
SELECT  ordts.ord_id, rel.soggetto_id_da, oil.oil_relaz_tipo_code, tipo.relaz_tipo_code, tipo.relaz_tipo_desc
FROM  siac_t_ordinativo_ts ordts, siac_r_subdoc_ordinativo_ts subdocordts, siac_r_subdoc_modpag subdocmodpag, siac_r_soggrel_modpag sogrel,
      siac_r_soggetto_relaz rel, siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil
WHERE  ordts.ente_proprietario_id = p_ente_proprietario_id
AND    oil.oil_relaz_tipo_code = 'CSC'
AND    ordts.ord_ts_id = subdocordts.ord_ts_id
AND    subdocordts.subdoc_id = subdocmodpag.subdoc_id
AND    sogrel.modpag_id = subdocmodpag.modpag_id
AND    sogrel.soggetto_relaz_id = rel.soggetto_relaz_id
AND    rel.relaz_tipo_id = roil.relaz_tipo_id
AND    tipo.relaz_tipo_id = roil.relaz_tipo_id
AND    oil.oil_relaz_tipo_id = roil.oil_relaz_tipo_id
AND    p_data BETWEEN subdocordts.validita_inizio AND COALESCE(subdocordts.validita_fine, p_data)
AND    p_data BETWEEN subdocmodpag.validita_inizio AND COALESCE(subdocmodpag.validita_fine, p_data)
AND    p_data BETWEEN sogrel.validita_inizio AND COALESCE(sogrel.validita_fine, p_data)
AND    p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND    p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
-- 06.11.2018 Sofia siac-6499
AND    p_data BETWEEN ordts.validita_inizio AND COALESCE(ordts.validita_fine, p_data)
AND    ordts.data_cancellazione is null
AND    subdocordts.data_cancellazione is null
AND    subdocmodpag.data_cancellazione is null
AND    sogrel.data_cancellazione is null
AND    rel.data_cancellazione is null
AND    roil.data_cancellazione is null
AND    tipo.data_cancellazione is null
AND    oil.data_cancellazione is null
),
-- 20.01.2023 Sofia Jira SIAC-8762
contotes_vincolato as  
(select  r.ord_id, conto.contotes_code, conto.contotes_desc,conto.contotes_id 
from siac_d_contotesoreria conto ,siac_r_ordinativo_contotes_nodisp  r
where conto.ente_proprietario_id=p_ente_proprietario_id
and     r.contotes_id=conto.contotes_id 
and     conto.data_cancellazione is null
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
)
select ordinativipag.ente_proprietario_id, ordinativipag.ente_denominazione, ordinativipag.anno,
ordinativipag.fase_operativa_code, ordinativipag.fase_operativa_desc,
ordinativipag.ord_anno, ordinativipag.ord_numero, ordinativipag.ord_desc, ordinativipag.ord_stato_code,
ordinativipag.ord_stato_desc, ordinativipag.ord_cast_cassa, ordinativipag.ord_cast_competenza,
ordinativipag.ord_cast_emessi, ordinativipag.ord_emissione_data, ordinativipag.ord_riduzione_data,
ordinativipag.ord_spostamento_data, ordinativipag.ord_variazione_data,ordinativipag.ord_beneficiariomult
,ordinativipag.ord_id, ordinativipag.bil_id, ordinativipag.comm_tipo_id,
ordinativipag.data_inizio_val_stato_ordpg,
ordinativipag.data_inizio_val_ordpg,
ordinativipag.data_creazione_ordpg,
ordinativipag.data_modifica_ordpg,
ordinativipag.codbollo_id,ordinativipag.contotes_id,
ordinativipag.dist_id,
ordinativipag.ord_trasm_oil_data,ordinativipag.siope_tipo_debito_code, ordinativipag.siope_tipo_debito_desc,
ordinativipag.siope_tipo_debito_desc_bnkit,ordinativipag.siope_assenza_motivazione_code,
ordinativipag.siope_assenza_motivazione_desc, ordinativipag.siope_assenza_motivazione_desc_bnkit,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ordinativipag.codbollo_code, ordinativipag.codbollo_desc,
ordinativipag.codbollo_id,
ordinativipag.comm_tipo_code, ordinativipag.comm_tipo_desc, ordinativipag.comm_tipo_id,
ordinativipag.contotes_code, ordinativipag.contotes_desc,ordinativipag.contotes_id,
ordinativipag.dist_code, ordinativipag.dist_desc,ordinativipag.dist_id,
--ordinativipag.ord_id,
ordinativipag.modpag_id ,
ordinativipag.v_soggetto_id_modpag,
ordinativipag.v_quietanziante,
ordinativipag.v_data_nascita_quietanziante,
ordinativipag.v_luogo_nascita_quietanziante,
ordinativipag.v_stato_nascita_quietanziante,
ordinativipag.v_bic, ordinativipag.v_contocorrente, ordinativipag.v_intestazione_contocorrente,
ordinativipag.v_iban,
ordinativipag.v_note_modalita_pagamento, ordinativipag.v_data_scadenza_modalita_pagamento,
ordinativipag.v_codice_soggetto_modpag, ordinativipag.v_descrizione_soggetto_modpag,
ordinativipag.v_codice_fiscale_soggetto_modpag,
ordinativipag.v_codice_fiscale_estero_soggetto_modpag, ordinativipag.v_partita_iva_soggetto_modpag,
ordinativipag.tipo_cessione ,
ordinativipag.cod_cessione  ,
ordinativipag.desc_cessione,
ordinativipag.accredito_tipo_id,
ordinativipag.v_codice_tipo_accredito,
ordinativipag.v_descrizione_tipo_accredito,
--ordinativipag.ord_id,
ordinativipag.soggetto_id,
ordinativipag.soggetto_code, ordinativipag.soggetto_desc, ordinativipag.codice_fiscale,
ordinativipag.codice_fiscale_estero, ordinativipag.partita_iva,
--ordinativipag.ord_id ,
ordinativipag.v_codice_tipo_avviso, ordinativipag.v_descrizione_tipo_avviso,
--ordinativipag.ord_id ,
ordinativipag.v_codice_spesa_ricorrente,
ordinativipag.v_descrizione_spesa_ricorrente,
--ordinativipag.ord_id ,
ordinativipag.v_codice_transazione_spesa_ue,
ordinativipag.v_descrizione_transazione_spesa_ue,
class21.*,class22.*,class23.*,class24.*,class25.*,
ordinativipag.v_codice_capitolo, ordinativipag.v_codice_articolo,
ordinativipag.v_codice_ueb, ordinativipag.v_descrizione_capitolo ,
ordinativipag.v_descrizione_articolo,
mif.mif_ord_class_codice_cge, mif.descr_siope,
modpagcsc.soggetto_id_da,      -- SIAC-5228
modpagcsc.oil_relaz_tipo_code, -- SIAC-5228
modpagcsc.relaz_tipo_code,     -- SIAC-5228
modpagcsc.relaz_tipo_desc,     -- SIAC-5228
ordinativipag.ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
-- 20.01.2023 Sofia Jira 	SIAC-8762
,contotes_vincolato.contotes_code contotes_code_vinc 
,contotes_vincolato.contotes_desc contotes_desc_vinc
from ordinativipag
left join class21
on ordinativipag.ord_id=class21.ord_id
left join class22
on ordinativipag.ord_id=class22.ord_id
left join class23
on ordinativipag.ord_id=class23.ord_id
left join class24
on ordinativipag.ord_id=class24.ord_id
left join class25
on ordinativipag.ord_id=class25.ord_id
left join cofog
on ordinativipag.ord_id=cofog.ord_id
left join pdc5
on ordinativipag.ord_id=pdc5.ord_id
left join pdc4
on ordinativipag.ord_id=pdc4.ord_id
left join pce5
on ordinativipag.ord_id=pce5.ord_id
left join pce4
on ordinativipag.ord_id=pce4.ord_id
left join attoamm
on ordinativipag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ordinativipag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ordinativipag.ord_id=t_noteordinativo.ord_id
left join impiniziale
on ordinativipag.ord_id=impiniziale.ord_id
left join impattuale
on ordinativipag.ord_id=impattuale.ord_id
left join firma
on ordinativipag.ord_id=firma.ord_id
left join mif on ordinativipag.ord_id = mif.mif_ord_ord_id
left join modpagcsc on ordinativipag.ord_id = modpagcsc.ord_id
-- 20.01.2023 Sofia Jira  SIAC-8762
left join  contotes_vincolato on (ordinativipag.ord_id=contotes_vincolato.ord_id)
) as tb;

esito:= 'Fine inserimento ordinativi in pagamento (siac_dwh_ordinativo_pagamento) - '||clock_timestamp();
RETURN NEXT;

 INSERT INTO siac.siac_dwh_subordinativo_pagamento
    (ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_pag,
    num_ord_pag,
    desc_ord_pag,
    cod_stato_ord_pag,
    desc_stato_ord_pag,
    castelletto_cassa_ord_pag,
    castelletto_competenza_ord_pag,
    castelletto_emessi_ord_pag,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_pag,
    desc_subord_pag,
    data_esecuzione_pagamento,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_liquidazione,
    num_liquidazione,
    desc_liquidazione,
    data_emissione_liquidazione,
    importo_liquidazione,
    liquidazione_automatica,
    liquidazione_convalida_manuale,
    cup,
    cig,
    data_inizio_val_stato_ordpg,
    data_inizio_val_subordpg,
    data_creazione_subordpg,
    data_modifica_subordpg,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc,
    doc_id -- SIAC-5573
    )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end ord_beneficiariomult,

tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.v_liq_anno,tb.v_liq_numero, tb.v_liq_desc, tb.v_liq_emissione_data,
tb.v_liq_importo, tb.v_liq_automatica, tb.liq_convalida_manuale,
tb.cup,tb.cig,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code,
tb.doc_id
-- SIAC-5573
from (
with suball as (
with subordinativipag as (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
       a.ord_beneficiariomult,a.ord_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
        l.validita_inizio as data_inizio_val_subordpg,
         l.data_creazione as data_creazione_subordpg,
         l.data_modifica as data_modifica_subordpg
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id and
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'P' and
--a.ord_numero in (6211,7848) and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
-- 06.11.2018 Sofia siac-6499
AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
and l.data_cancellazione is null
-- 06.11.2018 Sofia siac-6499
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id,
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag,
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null -- -- 13.05.2022 Sofia JIRA SIAC-8599 and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
select ord_pag.*,
bollo.codbollo_code, bollo.codbollo_desc,
contotes.contotes_code, contotes.contotes_desc,
dist.dist_code, dist.dist_desc,
commis.comm_tipo_code, commis.comm_tipo_desc,
bilelem.v_codice_capitolo,bilelem.v_codice_articolo,
bilelem.v_codice_ueb,bilelem.v_descrizione_capitolo ,
bilelem.v_descrizione_articolo,
modpag.modpag_id,modpag.v_soggetto_id_modpag, modpag.v_accredito_tipo_id,
modpag.v_quietanziante,modpag.v_data_nascita_quietanziante,
modpag.v_luogo_nascita_quietanziante,modpag.v_stato_nascita_quietanziante,modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,modpag.v_iban,
modpag.v_note_modalita_pagamento,modpag.v_data_scadenza_modalita_pagamento,
modpag.v_codice_soggetto_modpag,modpag.v_descrizione_soggetto_modpag,
modpag.v_codice_fiscale_soggetto_modpag,modpag.v_codice_fiscale_estero_soggetto_modpag,
modpag.v_partita_iva_soggetto_modpag,--modpag.accredito_tipo_id,
modpag.v_codice_tipo_accredito,modpag.v_descrizione_tipo_accredito,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
tipoavviso.v_codice_tipo_avviso,tipoavviso.v_descrizione_tipo_avviso,
ricspesa.v_codice_spesa_ricorrente, ricspesa.v_descrizione_spesa_ricorrente,
transue.v_codice_transazione_spesa_ue, transue.v_descrizione_transazione_spesa_ue
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
)--fine sub ordinativipag
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class22 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class23 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class24 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class25 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
select
subordinativipag.ente_proprietario_id, subordinativipag.ente_denominazione, subordinativipag.anno, subordinativipag.fase_operativa_code,
subordinativipag.fase_operativa_desc,subordinativipag.ord_anno, subordinativipag.ord_numero, subordinativipag.ord_desc,
 subordinativipag.ord_stato_code, subordinativipag.ord_stato_desc, subordinativipag.ord_cast_cassa, subordinativipag.ord_cast_competenza,
subordinativipag.ord_cast_emessi, subordinativipag.ord_emissione_data, subordinativipag.ord_riduzione_data,
subordinativipag.ord_spostamento_data, subordinativipag.ord_variazione_data, subordinativipag.ord_beneficiariomult,
subordinativipag.ord_ts_code, subordinativipag.ord_ts_desc, subordinativipag.ord_ts_data_scadenza,
subordinativipag.ord_id,subordinativipag.bil_id, subordinativipag.comm_tipo_id,
subordinativipag.data_inizio_val_stato_ordpg,subordinativipag.data_inizio_val_ordpg,subordinativipag.data_creazione_ordpg,
subordinativipag.data_modifica_ordpg,subordinativipag.codbollo_id,subordinativipag.contotes_id,subordinativipag.dist_id,
subordinativipag.ord_ts_id,
subordinativipag.data_inizio_val_subordpg,subordinativipag.data_creazione_subordpg,subordinativipag.data_modifica_subordpg,
cofog.codice_cofog_gruppo,cofog.descrizione_cofog_gruppo,cofog.codice_cofog_divisione,cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo
from subordinativipag
left join class21
on subordinativipag.ord_id=class21.ord_id
left join class22
on subordinativipag.ord_id=class22.ord_id
left join class23
on subordinativipag.ord_id=class23.ord_id
left join class24
on subordinativipag.ord_id=class24.ord_id
left join class25
on subordinativipag.ord_id=class25.ord_id
left join cofog
on subordinativipag.ord_id=cofog.ord_id
left join pdc5
on subordinativipag.ord_id=pdc5.ord_id
left join pdc4
on subordinativipag.ord_id=pdc4.ord_id
left join pce5
on subordinativipag.ord_id=pce5.ord_id
left join pce4
on subordinativipag.ord_id=pce4.ord_id
left join attoamm
on subordinativipag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on subordinativipag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on subordinativipag.ord_id=t_noteordinativo.ord_id
)
select suball.*
,
t_cig.cig,
t_cup.cup,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,liq.*, elenco_doc.*
 from suball
 left join
 (
SELECT
a.sord_id
, c.testo cig
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id
 and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL) t_cig on t_cig.sord_id=suball.ord_ts_id
  left join (SELECT a.sord_id, c.testo cup
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE b.attr_code='cup' and a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL) t_cup on t_cup.sord_id=suball.ord_ts_id
left join (SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE a.ente_proprietario_id=p_ente_proprietario_id and a.ord_ts_id = b.ord_ts_id
AND   c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia jira siac-6499
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY b.ord_ts_id) impiniziale on suball.ord_ts_id=impiniziale.ord_ts_id
left join (SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
b.ord_ts_id FROM siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE a.ente_proprietario_id=p_ente_proprietario_id and a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia jira siac-6499
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
b.ord_ts_id) impattuale on suball.ord_ts_id=impattuale.ord_ts_id
left join (select a.ord_id, a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
firma  on suball.ord_id=firma.ord_id
left join (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
),
 causale as (SELECT
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id
    AND doa.data_cancellazione IS NULL)
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt
on onere.onere_att_id=onatt.onere_att_id) ons
on suball.ord_ts_id=ons.ord_ts_id
left join (select a.sord_id,
b.liq_anno v_liq_anno, b.liq_numero v_liq_numero, b.liq_desc v_liq_desc, b.liq_emissione_data v_liq_emissione_data,
         b.liq_importo v_liq_importo, b.liq_automatica v_liq_automatica, b.liq_convalida_manuale
 FROM siac_r_liquidazione_ord a, siac_t_liquidazione b
  WHERE a.liq_id = b.liq_id
  AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL ) liq
  on suball.ord_ts_id=liq.sord_id
left join   (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id,
        t_doc.doc_id -- SIAC-5573
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc,
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data))
 --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc on elenco_doc.ord_ts_id=suball.ord_ts_id
) as tb;


esito:= 'Fine funzione carico ordinativi in pagamento (fnc_siac_dwh_ordinativo_pagamento) - '||clock_timestamp();
RETURN NEXT;



update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()- fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (fnc_siac_dwh_ordinativo_pagamento) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_incasso 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
        p_data := now();
END IF;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_ordinativo_incasso',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico ordinativi in incasso (FNC_SIAC_DWH_ORDINATIVO_INCASSO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;


INSERT INTO siac.siac_dwh_ordinativo_incasso
  (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_inc,
  num_ord_inc,
  desc_ord_inc,
  cod_stato_ord_inc,
  desc_stato_ord_inc,
  castelletto_cassa_ord_inc,
  castelletto_competenza_ord_inc,
  castelletto_emessi_ord_inc,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordin,
  data_inizio_val_ordin,
  data_creazione_ordin,
  data_modifica_ordin,
  data_trasmissione,
  cod_siope,
  desc_siope,
  caus_id -- SIAC-5522
  , cod_causale -- SIAC-5897
  , desc_causale
  , cod_tipo_causale -- SIAC-5897
  , desc_tipo_causale
  , ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
    --  23.01.2023 Sofia Jira 	SIAC-8762
  ,  cod_conto_tes_vincolato
  ,  descri_conto_tes_vincolato
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante,
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban,
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla26_classif_tipo_desc,tb.cla26_classif_code,tb.cla26_classif_desc,
tb.cla27_classif_tipo_desc,tb.cla27_classif_code,tb.cla27_classif_desc,
tb.cla28_classif_tipo_desc,tb.cla28_classif_code,tb.cla28_classif_desc,
tb.cla29_classif_tipo_desc,tb.cla29_classif_code,tb.cla29_classif_desc,
tb.cla30_classif_tipo_desc,tb.cla30_classif_code,tb.cla30_classif_desc,
tb.v_flagAllegatoCartaceo,
tb.v_cup,
tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo ,
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope,
tb.caus_id -- SIAC-5522
--SIAC-5897
,tb.caus_code
,tb.caus_desc
,tb.caus_tipo_code
,tb.caus_tipo_desc
,tb.ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
--  23.01.2023 Sofia Jira 	SIAC-8762
,tb.contotes_code_vinc
,tb.contotes_desc_vinc
from (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data,
a.caus_id, -- SIAC-5522,
a.ord_da_trasmettere -- 20.06.2018 Sofia siac-6175
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i
where  d.ente_proprietario_id = p_ente_proprietario_id
and
c.anno = p_anno_bilancio
--and  a.ord_numero in (3917, 3920)
AND e.ord_tipo_code = 'I' and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id,
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag,
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,d.soggetto_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,a.soggetto_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla26_classif_tipo_desc,
b.classif_code cla26_classif_code, b.classif_desc cla26_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_26'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla27_classif_tipo_desc,
b.classif_code cla27_classif_code, b.classif_desc cla27_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_27'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla28_classif_tipo_desc,
b.classif_code cla28_classif_code, b.classif_desc cla28_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_28'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla29_classif_tipo_desc,
b.classif_code cla29_classif_code, b.classif_desc cla29_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_29'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla30_classif_tipo_desc,
b.classif_code cla30_classif_code, b.classif_desc cla30_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_30'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_cup as (
SELECT
a.ord_id
, a.testo v_cup
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia siac-6499
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia siac-6499
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
a.ord_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_entrata a,  mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero::integer
      from mif_t_ordinativo_entrata a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero::integer
    ),
      descsiope as (
      select replace(substring(a.classif_code from 2),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'E'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_ENTRATA_I'
      and   a.classif_code not in ('XXXX','YYYY')
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno
    and  mif1.mif_ord_numero::integer=mifmax.mif_ord_numero) as tb
    )
-- JIRA 5897
, causale as (
      select c.caus_id, c.caus_code,c.caus_desc, ct.caus_tipo_code, ct.caus_tipo_desc
      from
      siac_d_causale c
      , siac_d_causale_tipo ct
      , siac_r_causale_tipo r
      where
      p_data between r.validita_inizio and coalesce (r.validita_fine,p_data)
      and    r.data_cancellazione is null
      and    r.validita_fine is null
      and    r.caus_id = c.caus_id
      and    r.caus_tipo_id = ct.caus_tipo_id
      and    r.ente_proprietario_id = p_ente_proprietario_id)
 -- 23.01.2023 Sofia Jira SIAC-8762
,contotes_vincolato as  
(select  r.ord_id, conto.contotes_code, conto.contotes_desc,conto.contotes_id 
from siac_d_contotesoreria conto ,siac_r_ordinativo_contotes_nodisp  r
where conto.ente_proprietario_id=p_ente_proprietario_id
and     r.contotes_id=conto.contotes_id 
and     conto.data_cancellazione is null
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
)
select ord_pag.*,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo, t_cup.v_cup,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,bollo.*,commis.*,contotes.*,dist.*,modpag.*,sogg.*,
tipoavviso.*,ricspesa.*,transue.*,
class26.*,class27.*,class28.*,class29.*,class30.*,
bilelem.*,
mif.mif_ord_class_codice_cge, mif.descr_siope
--SIAC-5897
, causale.caus_code,causale.caus_desc,causale.caus_tipo_code, causale.caus_tipo_desc
-- 23.01.2023 Sofia Jira 	SIAC-8762
,contotes_vincolato.contotes_code contotes_code_vinc
,contotes_vincolato.contotes_desc contotes_desc_vinc
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id
left join pdc5
on ord_pag.ord_id=pdc5.ord_id
left join pdc4
on ord_pag.ord_id=pdc4.ord_id
left join pce5
on ord_pag.ord_id=pce5.ord_id
left join pce4
on ord_pag.ord_id=pce4.ord_id
left join attoamm
on ord_pag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_cup
on ord_pag.ord_id=t_cup.ord_id
left join t_noteordinativo
on
ord_pag.ord_id=t_noteordinativo.ord_id
left join impiniziale
on ord_pag.ord_id=impiniziale.ord_id
left join impattuale
on ord_pag.ord_id=impattuale.ord_id
left join firma
on ord_pag.ord_id=firma.ord_id
left join mif on ord_pag.ord_id = mif.mif_ord_ord_id
-- JIRA 5897
left join causale on ord_pag.caus_id = causale.caus_id
-- 23.01.2023 Sofia Jira  SIAC-8762
left join contotes_vincolato on (ord_pag.ord_id=contotes_vincolato.ord_id)
) as tb;



     INSERT INTO siac.siac_dwh_subordinativo_incasso
    (
    ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_inc,
    num_ord_inc,
    desc_ord_inc,
    cod_stato_ord_inc,
    desc_stato_ord_inc,
    castelletto_cassa_ord_inc,
    castelletto_competenza_ord_inc,
    castelletto_emessi_ord_inc,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_inc,
    desc_subord_inc,
    data_scadenza,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_accertamento,
    num_accertamento,
    desc_accertamento,
    cod_subaccertamento,
    importo_quietanziato,
    data_inizio_val_stato_ordin,
    data_inizio_val_subordin,
    data_creazione_subordin,
    data_modifica_subordin,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc,
    caus_id, -- SIAC-5522
    doc_id, -- SIAC-5573
    cod_causale_ord, --SIAC-5897
    desc_causale_ord,
    cod_tipo_causale_ord, --SIAC-5897
    desc_tipo_causale_ord --SIAC-5897
    )
    select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.movgest_anno,tb.movgest_numero,tb.movgest_desc,tb.movgest_ts_code,
case when tb.ord_stato_code='Q' then tb.importo_attuale else null end importo_quietanziato,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code,
tb.caus_id_ord, -- SIAC-5522
tb.doc_id, -- SIAC-5573
tb.caus_code_ord, --SIAC-5897
tb.caus_desc_ord,
tb.caus_tipo_code_ord, --SIAC-5897
tb.caus_tipo_desc_ord
from (
--subord
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
       a.ord_beneficiariomult
           ,  a.ord_id, --q.elem_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
       l.validita_inizio as data_inizio_val_subordpg,
       l.data_creazione as data_creazione_subordpg,
       l.data_modifica as data_modifica_subordpg,
       a.caus_id as caus_id_ord-- SIAC-5522
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio--p_anno_bilancio
--and  a.ord_numero in (3917, 3920)
AND e.ord_tipo_code = 'I' and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
-- 06.11.2018 Sofia siac-6499
AND    p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
and l.data_cancellazione is null
-- 06.11.2018 Sofia siac-6499
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id,
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag,
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia siac-6499
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
b.ord_ts_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
-- 06.11.2018 Sofia siac-6499
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
b.ord_ts_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)),
ons as (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
),
 causale as (SELECT
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id
    AND doa.data_cancellazione IS NULL)
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt
on onere.onere_att_id=onatt.onere_att_id)
,
movgest as (
select a.ord_ts_id, c.movgest_anno,c.movgest_numero,c.movgest_desc,
case when d.movgest_ts_tipo_code = 'T' then
     	null
     else
     	b.movgest_ts_code
end movgest_ts_code
from
siac_r_ordinativo_ts_movgest_ts a,siac_t_movgest_ts b,siac_t_movgest c,siac_d_movgest_ts_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_id=b.movgest_ts_id
and c.movgest_id=b.movgest_id
and d.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and p_data BETWEEN a.validita_inizio and COALESCE (a.validita_fine,p_data)
)  ,
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc as (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id,
        t_doc.doc_id -- SIAC-5573
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc,
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data))
-- JIRA 5897
, causale_ord as (
      select c.caus_id, c.caus_code,c.caus_desc,ct.caus_tipo_code, ct.caus_tipo_desc
      from
      siac_d_causale c
      , siac_d_causale_tipo ct
      , siac_r_causale_tipo r
      where
      p_data between r.validita_inizio and coalesce (r.validita_fine,p_data)
      and    r.data_cancellazione is null
      and    r.validita_fine is null
      and    r.caus_id = c.caus_id
      and    r.caus_tipo_id = ct.caus_tipo_id
      and    r.ente_proprietario_id = p_ente_proprietario_id)
select ord_pag.*,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,
movgest.ord_ts_id, movgest.movgest_anno,movgest.movgest_numero,movgest.movgest_desc,movgest.movgest_ts_code,
elenco_doc.*
--SIAC-5897
, causale_ord.caus_code as caus_code_ord,causale_ord.caus_desc as caus_desc_ord, causale_ord.caus_tipo_code as caus_tipo_code_ord,causale_ord.caus_tipo_desc as caus_tipo_desc_ord
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id
left join pdc5
on ord_pag.ord_id=pdc5.ord_id
left join pdc4
on ord_pag.ord_id=pdc4.ord_id
left join pce5
on ord_pag.ord_id=pce5.ord_id
left join pce4
on ord_pag.ord_id=pce4.ord_id
left join attoamm
on ord_pag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ord_pag.ord_id=t_noteordinativo.ord_id
left join impiniziale
on ord_pag.ord_ts_id=impiniziale.ord_ts_id
left join impattuale
on ord_pag.ord_ts_id=impattuale.ord_ts_id
left join firma
on ord_pag.ord_id=firma.ord_id
left join ons
on ord_pag.ord_ts_id=ons.ord_ts_id
left join movgest
on ord_pag.ord_ts_id=movgest.ord_ts_id
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
left join elenco_doc
on elenco_doc.ord_ts_id=ord_pag.ord_ts_id
--SIAC-5897
left join causale_ord on causale_ord.caus_id=ord_pag.caus_id_ord
) as tb;


esito:= 'Fine funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter function  siac.fnc_siac_dwh_ordinativo_pagamento (  varchar, integer, timestamp) owner to siac;
alter function  siac.fnc_siac_dwh_ordinativo_incasso (  varchar, integer, timestamp) owner to siac;

 -- 07.02.2023 Sofia SIAC-8762 - fine 
 -- 07.02.2023 Sofia SIAC-8895 - inizio 
 drop  FUNCTION if exists siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar);
 
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
-- SIAC-6997 ---------------- INIZIO --------------------
	DAREANNO_ATTR CONSTANT varchar:='flagDaReanno';
    v_flagdareanno_attr_id  integer:=null;
-- SIAC-6997 ---------------- FINE --------------------
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;

	-- 07.02.2018 Sofia siac-5368
    movGestStatoId INTEGER:=null;
    movGestStatoPId INTEGER:=null;
	MOVGEST_STATO_CODE_P CONSTANT VARCHAR:='P';

  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- INIZIO --------------------

    SELECT attr.attr_id
    INTO   v_flagdareanno_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code = DAREANNO_ATTR
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- FINE --------------------

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

	-- 07.02.2018 Sofia siac-5368
    strMessaggio:='Lettura identificativo per stato='||MOVGEST_STATO_CODE_P||'.';
	select stato.movgest_stato_id
    into   strict movGestStatoPId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteproprietarioid
    and   stato.movgest_stato_code=MOVGEST_STATO_CODE_P;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  attoamm_id,       -- 07.02.2018 Sofia siac-5368
                  movgest_stato_id, -- 07.02.2018 Sofia siac-5368
                  importo_reimputato, -- 05.06.2020 Sofia SIAC-7593
                  importo_modifica_entrata, -- 05.06.2020 Sofia SIAC-7593
                  coll_mod_entrata,  -- 05.06.2020 Sofia SIAC-7593
                  elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N'
           order by  1) -- 19.04.2019 Sofia JIRA SIAC-6788
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
			movgest_numero,
			movgest_desc,
			movgest_tipo_id,
			bil_id,
			validita_inizio,
			ente_proprietario_id,
			login_operazione,
			parere_finanziario,
			parere_finanziario_data_modifica,
			parere_finanziario_login_operazione
        )
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          -- 05.06.2020 Sofia SIAC-7593
          (case when p_movgest_tipo_code='I' then movgestrec.elem_det_comp_tipo_id else null end ),
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and   fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and   fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
       and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
---                  then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
	 				 --- Sofia 27.04.2021  modifica per sbloccare sub	SIAC-8175
	                 then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end);

 --       raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and    fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and    fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre

        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
	    and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
--                      then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
				     --- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175
                     then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end)
        order by fase_bil_t_reimputazione.fasebilelabid  -- Sofia 27.04.2021 modifica per sbloccare sub
        limit 1;   -- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175

   --  raise notice 'strMessaggio anno=% numero=% movgestidret=%', movgestrec.movgest_anno, movgestrec.movgest_numero,movgestidret;
        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
        movgest_ts_desc,
        movgest_id,
        movgest_ts_tipo_id,
        movgest_ts_id_padre,
        movgest_ts_scadenza_data,
        ordine,
        livello,
        validita_inizio,
        ente_proprietario_id,
        login_operazione,
        login_creazione,
		siope_tipo_debito_id,
		siope_assenza_motivazione_id
      )
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      -- 07.02.2018 Sofia siac-5368
      /*INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;*/

      -- 07.02.2018 Sofia siac-5368
	  if impostaProvvedimento=true then
      	     movGestStatoId:=movGestRec.movgest_stato_id;
      else   movGestStatoId:=movGestStatoPId;
      end if;

      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
      values
      (
      	movgesttsidret,
        movGestStatoId,
        datainizioval,
        enteProprietarioId,
        loginoperazione
      )
      returning   movgest_stato_r_id INTO        codresult;


      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      -- 05.06.2020 Sofia Jira SIAC-7593
      --v_importomodifica := movgestrec.importomodifica * -1;
      -- 05.06.2020 Sofia Jira SIAC-7593
      v_importomodifica:= movgestrec.importo_reimputato;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato',
									   'flagDaReanno') ); -- 02.10.2020 SIAC-7593

-- SIAC-6997 ---------------- INIZIO --------------------
    if motivo = 'REIMP' then
-- SIAC-6997 ---------------- FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
-- SIAC-6997 ---------------- INIZIO --------------------
    else
      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdareanno_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
    end if;
-- SIAC-6997 ----------------  FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      /*strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );*/
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

	   -- 07.02.2018 Sofia siac-5368
	   if impostaProvvedimento=true then
       	strmessaggio:='Inserimento   movgest_ts_id='
	      ||movgestrec.movgest_ts_id::VARCHAR
    	  || ' [siac_r_movgest_ts_atto_amm].';
       	INSERT INTO siac_r_movgest_ts_atto_amm
	  	(
		 movgest_ts_id,
	     attoamm_id,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione
	  	)
        values
        (
         movgesttsidret,
         movgestrec.attoamm_id,
         datainizioval,
	 	 enteproprietarioid,
	 	 loginoperazione
        );
       end if;


      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      -- 07.02.2023 Sofia Jira SIAC-8895
      if motivo = 'REANNO' then
       INSERT INTO siac_r_movgest_ts_programma
 	   (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	   )
	   (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL 
	  );
	 else -- 07.02.2023 Sofia Jira SIAC-8895
	  INSERT INTO siac_r_movgest_ts_programma
 	   (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	   )
	   (
			 SELECT movgesttsidret,
					           pNew.programma_id,
		  					   datainizioval,
					           enteproprietarioid,
					           loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
			  			    siac_t_programma prog,siac_t_programma pNew,siac_r_programma_stato rs,siac_d_programma_stato stato
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND         prog.programma_id=r.programma_id
			 and           pNew.bil_id =bilancioId 
			 and           pNew.programma_tipo_id =prog.programma_tipo_id 
			 and           pNew.programma_code =prog.programma_code 
			 and           rs.programma_id=pNew.programma_id 
			 and           stato.programma_stato_id=rs.programma_stato_id 
			 and           stato.programma_stato_code ='VA'
			 AND         prog.data_cancellazione IS NULL
			 AND         prog.validita_fine IS NULL
			 AND         r.data_cancellazione IS NULL
			 AND         r.validita_fine IS NULL 
			 AND         pNew.data_cancellazione IS NULL
			 AND         pNew.validita_fine IS null
			 AND         rs.data_cancellazione IS NULL
			 AND         rs.validita_fine IS NULL
	  );
	 end if;

     --- 18.06.2019 Sofia SIAC-6702
	 if p_movgest_tipo_code=imp_movgest_tipo then
      -- siac_r_movgest_ts_storico_imp_acc
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_storico_imp_acc].';
      INSERT INTO siac_r_movgest_ts_storico_imp_acc
	  (
			movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.movgest_anno_acc,
             		r.movgest_numero_acc,
		            r.movgest_subnumero_acc,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_storico_imp_acc r
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );
      end if;

      -- siac_r_mutuo_voce_movgest
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function  siac.fnc_fasi_bil_gest_reimputa_elabora 
(   integer, integer, integer, boolean, varchar, timestamp, varchar,varchar,
    out  integer,  out integer, out  varchar) owner to siac;

 -- 07.02.2023 Sofia SIAC-8895 - fine  
 
 -- 16.03.2023 Sofia SIAC-TASK-#44 -- inizio 
drop function if exists fnc_stilo_siac_atto_amm_verifica_annullabilita
(
  attoamm_id_in integer
);

CREATE OR REPLACE FUNCTION fnc_stilo_siac_atto_amm_verifica_annullabilita
(
  attoamm_id_in integer
)
RETURNS boolean AS
$body$
DECLARE

annullabile boolean;
codResult integer:=null;


test_data timestamp;

begin
test_data:=now();
annullabile:= true;



  select 1 into codResult
  from siac_r_atto_amm_stato rsAtto, siac_d_atto_amm_stato stato
  where rsAtto.attoamm_id=attoamm_id_in
  and   stato.attoamm_stato_id=rsatto.attoamm_stato_id
  and   stato.attoamm_stato_code='ANNULLATO'
  and   test_data between rsAtto.validita_inizio and coalesce(rsAtto.validita_fine, test_data)
  and   rsAtto.data_cancellazione is null
  limit 1;
  if codResult is not null  then annullabile:=false; end if;
  raise notice ' Atto annullabile : atto annullato %',(not annullabile);

  if annullabile=true then


    select 1  into codResult
    from siac_r_bil_stato_op_atto_amm
    where attoamm_id=attoamm_id_in
    and data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste bil_stato_op %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_causale_atto_amm rAtto
    where rAtto.attoamm_id=attoamm_id_in
    and test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and rAtto.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;   end if;
    raise notice ' Atto annullabile : esiste causale_atto_amm %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_liquidazione_atto_amm  rAtto, siac_t_liquidazione liq
    where rAtto.attoamm_id=attoamm_id_in
    and   liq.liq_id=rAtto.liq_id
    and   test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and   rAtto.data_cancellazione is null
    and   liq.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste liquidazione_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN


    -- solo impegni-accertamenti definitivi
    select 1 into codResult
    from siac_r_movgest_ts_atto_amm rAtto ,siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
    where rAtto.attoamm_id=attoamm_id_in
    and   ts.movgest_ts_id=ratto.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
    and   test_data between rAtto.validita_inizio and coalesce(ratto.validita_fine,test_data)
    and   rs.data_cancellazione is null
    and   rAtto.data_cancellazione is null
    and   ts.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste movgest_ts_atto_amm  %',(not annullabile);
  end if;


  /*15.03.2023 Sofia SIAC-TASK-#44
  * if annullabile = true THEN



    select 1 into codResult
    from siac_r_mutuo_atto_amm rAtto, siac_t_mutuo m
    where rAtto.attoamm_id=attoamm_id_in
    and   m.mut_id=rAtto.mut_id
    and   test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and   rAtto.data_cancellazione is null
    and   m.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;    end if;
    raise notice ' Atto annullabile : esiste mutuo_atto_amm  %',(not annullabile);

  end if;*/		   

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_ordinativo_atto_amm ra, siac_t_ordinativo o
    where ra.attoamm_id=attoamm_id_in
    and   o.ord_id=ra.ord_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   o.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste ordinativo_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_predoc_atto_amm ra, siac_t_predoc p
    where  ra.attoamm_id=attoamm_id_in
    and    p.predoc_id=ra.predoc_id
    and    test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and    ra.data_cancellazione is null
    and    p.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste predoc_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN



	select 1 into codResult
    from siac_r_programma_atto_amm ra, siac_t_programma p
    where ra.attoamm_id=attoamm_id_in
    and   p.programma_id=ra.programma_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   p.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste programma_atto_amm  %',(not annullabile);


  end if;


  if annullabile = true THEN


    select 1 into codResult
    from siac_r_subdoc_atto_amm ra, siac_t_subdoc sub, siac_t_doc doc
    where ra.attoamm_id=attoamm_id_in
    and   sub.subdoc_id=ra.subdoc_id
    and   doc.doc_id=sub.doc_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   sub.data_cancellazione is null
    and   doc.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste subdoc_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN


    select 1  into codResult
    from siac_r_variazione_stato ra, siac_t_bil_elem_det_var dvar,siac_t_variazione var
    where ra.attoamm_id=attoamm_id_in
    and   dvar.variazione_stato_id=ra.variazione_stato_id
    and   var.variazione_id=ra.variazione_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   dvar.data_cancellazione is null
    and   var.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste variazione_atto_amm  %',(not annullabile);



  end if;

  if annullabile = true THEN


    select 1 into codResult
    from siac_t_atto_allegato ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste atto_allegato_atto_amm  %',(not annullabile);



  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_t_cartacont ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste cartacont_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_t_cassa_econ_operaz ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste cassa_econ_operaz_atto_amm  %',(not annullabile);


  end if;

  if annullabile = true THEN

    select 1 into codResult
    from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null limit 1;
    /* 31.03.2020 Sofia jira siac-7491
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste modifica_atto_amm  %',(not annullabile);*/

    --- 31.03.2020 Sofia jira siac-7491
    raise notice ' Atto annullabile : esiste modifica_atto_amm  %',coalesce(codResult,0)::boolean;
    if codResult is not null then
     codResult :=null;
     select 1 into codResult
     from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta,
          siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
          siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase
     where ra.attoamm_id=attoamm_id_in
     and   st.mod_id=ra.mod_id
     and   sta.mod_stato_id=st.mod_stato_id
     and   sta.mod_stato_code<>'A'
     and   dmod.mod_stato_r_id=st.mod_stato_r_id
     and   ts.movgest_ts_id=dmod.movgest_ts_id
     and   mov.movgest_id=ts.movgest_id
     and   rfase.bil_id=mov.bil_Id
     and   fase.fase_operativa_id=rfase.fase_operativa_id
     and   fase.fase_operativa_code='O'
     and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
     and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
     and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
     and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
     and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
     and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
     and   st.data_cancellazione is null
     and   ra.data_cancellazione is null
     and   dmod.data_cancellazione is null
     and   ts.data_cancellazione is null
     and   mov.data_cancellazione is null
     and   rfase.data_cancellazione is null
     limit 1;
     if codResult is not null then annullabile:=false; end if;
     raise notice ' Atto annullabile : esiste modifica_atto_amm su esercizio pred.consuntivo %',(not annullabile);

     if annullabile=true then
       codResult :=null;
       select 1 into codResult
       from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta,
            siac_t_movgest_ts_det_mod dmod
       where ra.attoamm_id=attoamm_id_in
       and   st.mod_id=ra.mod_id
       and   sta.mod_stato_id=st.mod_stato_id
       and   sta.mod_stato_code<>'A'
       and   dmod.mod_stato_r_id=st.mod_stato_r_id
       and   exists
       (
       select 1
       from siac_t_movgest_ts_det_mod dmod_prec,siac_r_modifica_stato  rs_prec,
            siac_d_modifica_Stato stato_prec,siac_t_modifica modif_prec
       where dmod_prec.movgest_ts_id=dmod.movgest_ts_id
       and   rs_Prec.mod_stato_r_id=dmod_prec.mod_stato_r_id
       and   stato_prec.mod_stato_id=rs_Prec.mod_Stato_id
       and   stato_prec.mod_stato_Code!='A'
       and   modif_prec.mod_id=rs_Prec.mod_id
       and   modif_prec.mod_id<ra.mod_id
  --     and   modif_prec.attoamm_Id=ra.attoamm_id
       and   test_data between dmod_prec.validita_inizio and coalesce(dmod_prec.validita_fine,test_data)
       and   test_data between rs_Prec.validita_inizio and coalesce(rs_Prec.validita_fine,test_data)
       and   test_data between modif_prec.validita_inizio and coalesce(modif_prec.validita_fine,test_data)
       and   dmod_prec.data_cancellazione is null
       and   rs_Prec.data_cancellazione is null
       and   modif_prec.data_cancellazione is null
       )
       and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
       and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
       and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
       and   st.data_cancellazione is null
       and   ra.data_cancellazione is null
       and   dmod.data_cancellazione is null
       limit 1;
       if codResult is not null then annullabile:=false; end if;
       raise notice ' Atto annullabile : esiste modifica_atto_amm non ultima %',(not annullabile);
     end if;
    end if;

    --- 31.03.2020 Sofia jira siac-7491
    raise notice ' Atto annullabile : esiste modifica_atto_amm annullabile %', annullabile;
  end if;


  raise notice ' Atto annullabile : %',annullabile::varchar;
return annullabile;

exception
    when no_data_found then
        return false;
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function  siac.fnc_stilo_siac_atto_amm_verifica_annullabilita(   integer) owner to siac;

drop function if exists siac.fnc_siac_atto_amm_verifica_annullabilita (
  attoamm_id_in integer
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_atto_amm_verifica_annullabilita (
  attoamm_id_in integer
)
RETURNS boolean AS
$body$
DECLARE

annullabile boolean;
rec0 record;
rec1 record;
rec2 record;
rec3 record;
rec4 record;
rec5 record;
rec6 record;
rec7 record;
rec8 record;
rec9 record;
rec10 record;
rec11 record;
rec12 record;
rec13 record;
rec14 record;

test_data timestamp;

/*table_fk
siac_r_predoc_atto_amm
siac_r_ordinativo_atto_amm
siac_r_programma_atto_amm
siac_r_liquidazione_atto_amm
siac_r_bil_stato_op_atto_amm
siac_t_cartacont
siac_r_atto_amm_class
siac_r_movgest_ts_atto_amm
siac_r_subdoc_atto_amm
siac_r_causale_atto_amm
siac_t_modifica
siac_r_variazione_stato
siac_t_atto_allegato
siac_r_atto_amm_stato
siac_t_cassa_econ_operaz
siac_r_mutuo_atto_amm*/




begin
test_data:=now();
annullabile:= true;

for rec0 in
select * from siac_r_atto_amm_stato s, siac_d_atto_amm_stato da
where
da.attoamm_stato_id=s.attoamm_id and s.attoamm_id=attoamm_id_in
and now() between s.validita_inizio and coalesce(s.validita_fine, now())
and da.attoamm_stato_code='ANNULLATO'
and da.data_cancellazione is null
and s.data_cancellazione is null
 limit 1
loop
annullabile:= false;
end loop;


for rec1 in
select * from siac_r_bil_stato_op_atto_amm
where attoamm_id=attoamm_id_in
 and data_cancellazione is null limit 1
loop
annullabile:= false;
end loop;

if annullabile = true THEN

  for rec2 in
  select * from siac_r_causale_atto_amm ra where ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec3 in
  select * from siac_r_liquidazione_atto_amm  ra, siac_t_liquidazione l, siac_r_liquidazione_stato ls, siac_d_liquidazione_stato lt
  where
  ra.liq_id=l.liq_id
  and ls.liq_id=l.liq_id
  and lt.liq_stato_id=ls.liq_stato_id
  and lt.liq_stato_code<>'A'
  and test_data between ls.validita_inizio and coalesce(ls.validita_fine,test_data)
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec4 in
  select * from siac_r_movgest_ts_atto_amm ra ,siac_t_movgest_ts ts, siac_r_movgest_ts_stato tss, siac_d_movgest_stato sta
  where
  ts.movgest_ts_id=ra.movgest_ts_id
  and ts.movgest_ts_id=tss.movgest_ts_id
  and tss.movgest_stato_id=sta.movgest_stato_id
  and sta.movgest_stato_code<>'A'
  and test_data between tss.validita_inizio and coalesce(tss.validita_fine,test_data)
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


/* 15.03.2024 Sofia SIAC-TASK-#44
if annullabile = true THEN

  for rec5 in
  select * from siac_r_mutuo_atto_amm ra, siac_t_mutuo m, siac_r_mutuo_stato ms, siac_d_mutuo_stato sta
  where
  m.mut_id=ra.mut_id
  and m.mut_id=ms.mut_id
  and ms.mut_stato_id=sta.mut_stato_id
  and sta.mut_stato_code<>'A'
  and test_data between ms.validita_inizio and coalesce(ms.validita_fine,test_data)
 and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;
*/

if annullabile = true THEN

  for rec6 in
  select * from siac_r_ordinativo_atto_amm ra, siac_t_ordinativo o, siac_r_ordinativo_stato os, siac_d_ordinativo_stato sta
  where
  o.ord_id=ra.ord_id
  and os.ord_id=o.ord_id
  and os.ord_stato_id=sta.ord_stato_id
  and sta.ord_stato_code<>'A'
  and  test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec7 in
  select * from siac_r_predoc_atto_amm ra, siac_t_predoc p, siac_r_predoc_stato ps, siac_d_predoc_stato sta
  where
  p.predoc_id=ra.predoc_id
  and ps.predoc_id=p.predoc_id
  and ps.predoc_stato_id=sta.predoc_stato_id
  and sta.predoc_stato_code<>'A'
  and  test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec8 in
  select * from siac_r_programma_atto_amm ra, siac_t_programma p, siac_r_programma_stato ps, siac_d_programma_stato sta
  where
  p.programma_id=ra.programma_id
  and p.programma_id=ps.programma_stato_id
  and ps.programma_stato_id=sta.programma_stato_id
  and sta.programma_stato_code<>'AN'
   and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec9 in
  select * from siac_r_subdoc_atto_amm ra, siac_t_subdoc sd, siac_t_doc d, siac_r_doc_stato sst, siac_d_doc_stato sta
  where
  sd.subdoc_id=ra.subdoc_id
  and d.doc_id=sd.doc_id
  and sst.doc_id=d.doc_id
  and sst.doc_stato_id=sta.doc_stato_id
  and sta.doc_stato_code<>'A'
  and test_data between sst.validita_inizio and coalesce(sst.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec10 in
  select * from siac_r_variazione_stato ra, siac_d_variazione_stato sta
  where
  sta.variazione_stato_tipo_id=ra.variazione_stato_tipo_id
  and sta.variazione_stato_tipo_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec11 in
  select * from siac_t_atto_allegato ra, siac_r_atto_allegato_stato st, siac_d_atto_allegato_stato sta
  where
  st.attoal_id=ra.attoal_id and
  st.attoal_stato_id=sta.attoal_stato_id
  and sta.attoal_stato_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec12 in
  select * from siac_t_cartacont ra ,siac_r_cartacont_stato st, siac_d_cartacont_stato sta
  where
  st.cartac_id=ra.cartac_id
  and st.cartac_stato_id=sta.cartac_stato_id
  and sta.cartac_stato_code<>'A'
  and ra.attoamm_id=attoamm_id_in
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec13 in
  select * from siac_t_cassa_econ_operaz ra, siac_r_cassa_econ_operaz_stato st, siac_d_cassa_econ_operaz_stato sta
  where
  st.cassaeconop_id=ra.cassaeconop_id
  and st.cassaeconop_stato_id=sta.cassaeconop_stato_id
  and sta.cassaeconop_stato_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
  and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec14 in
  select * from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
  where
  st.mod_id=ra.mod_id
  and st.mod_stato_id=sta.mod_stato_id
  and sta.mod_stato_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and  ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

return annullabile;

exception
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function  siac.fnc_siac_atto_amm_verifica_annullabilita( integer) owner to siac;

 drop  FUNCTION if exists siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar);
  
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_elabora (
  p_fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  impostaprovvedimento boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
			 
  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
-- SIAC-6997 ---------------- INIZIO --------------------
	DAREANNO_ATTR CONSTANT varchar:='flagDaReanno';
    v_flagdareanno_attr_id  integer:=null;
-- SIAC-6997 ---------------- FINE --------------------
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;

	-- 07.02.2018 Sofia siac-5368
    movGestStatoId INTEGER:=null;
    movGestStatoPId INTEGER:=null;
	MOVGEST_STATO_CODE_P CONSTANT VARCHAR:='P';

  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- INIZIO --------------------

    SELECT attr.attr_id
    INTO   v_flagdareanno_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code = DAREANNO_ATTR
    AND    attr.ente_proprietario_id = enteproprietarioid;

-- SIAC-6997 ---------------- FINE --------------------

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

	-- 07.02.2018 Sofia siac-5368
    strMessaggio:='Lettura identificativo per stato='||MOVGEST_STATO_CODE_P||'.';
	select stato.movgest_stato_id
    into   strict movGestStatoPId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteproprietarioid
    and   stato.movgest_stato_code=MOVGEST_STATO_CODE_P;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  attoamm_id,       -- 07.02.2018 Sofia siac-5368
                  movgest_stato_id, -- 07.02.2018 Sofia siac-5368
                  importo_reimputato, -- 05.06.2020 Sofia SIAC-7593
                  importo_modifica_entrata, -- 05.06.2020 Sofia SIAC-7593
                  coll_mod_entrata,  -- 05.06.2020 Sofia SIAC-7593
                  elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N'
           order by  1) -- 19.04.2019 Sofia JIRA SIAC-6788
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
			movgest_numero,
			movgest_desc,
			movgest_tipo_id,
			bil_id,
			validita_inizio,
			ente_proprietario_id,
			login_operazione,
			parere_finanziario,
			parere_finanziario_data_modifica,
			parere_finanziario_login_operazione
        )
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          elem_det_comp_tipo_id, -- 05.06.2020 Sofia SIAC-7593
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          -- 05.06.2020 Sofia SIAC-7593
          (case when p_movgest_tipo_code='I' then movgestrec.elem_det_comp_tipo_id else null end ),
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and   fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and   fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
       and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
---                  then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
	 				 --- Sofia 27.04.2021  modifica per sbloccare sub	SIAC-8175
	                 then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end);

 --       raise notice 'strMessaggio anno=% numero=% v_numero_el=%', movgestrec.movgest_anno, movgestrec.movgest_numero,v_numero_el;

        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
--        and    fase_bil_t_reimputazione.fasebilelabid=370 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre
--        and    fase_bil_t_reimputazione.fasebilelabid=369 -- Sofia 27.04.2021 Jira SIAC-8175 per elaborare solo sub impostare elabId dei movimenti padre

        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T'
        and    fase_bil_t_reimputazione.mtdm_reimputazione_anno=movgestrec.mtdm_reimputazione_anno -- 28.02.2018 Sofia jira siac-5964
	    and    (case when p_movgest_tipo_code='I'  -- 08.06.2020 Sofia Jira siac-7593
--                      then fase_bil_t_reimputazione.elem_det_comp_tipo_id= movgestrec.elem_det_comp_tipo_id - Sofia 27.04.2021 Jira SIAC-8175
				     --- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175
                     then fase_bil_t_reimputazione.elem_det_comp_tipo_id = fase_bil_t_reimputazione.elem_det_comp_tipo_id  
                     else p_movgest_tipo_code='A' end)
        order by fase_bil_t_reimputazione.fasebilelabid  -- Sofia 27.04.2021 modifica per sbloccare sub
        limit 1;   -- Sofia 27.04.2021 modifica per sbloccare sub Jira SIAC-8175

   --  raise notice 'strMessaggio anno=% numero=% movgestidret=%', movgestrec.movgest_anno, movgestrec.movgest_numero,movgestidret;
        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
        movgest_ts_desc,
        movgest_id,
        movgest_ts_tipo_id,
        movgest_ts_id_padre,
        movgest_ts_scadenza_data,
        ordine,
        livello,
        validita_inizio,
        ente_proprietario_id,
        login_operazione,
        login_creazione,
		siope_tipo_debito_id,
		siope_assenza_motivazione_id
      )
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      -- 07.02.2018 Sofia siac-5368
      /*INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;*/

      -- 07.02.2018 Sofia siac-5368
	  if impostaProvvedimento=true then
      	     movGestStatoId:=movGestRec.movgest_stato_id;
      else   movGestStatoId:=movGestStatoPId;
      end if;

      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
      values
      (
      	movgesttsidret,
        movGestStatoId,
        datainizioval,
        enteProprietarioId,
        loginoperazione
      )
      returning   movgest_stato_r_id INTO        codresult;


      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      -- 05.06.2020 Sofia Jira SIAC-7593
      --v_importomodifica := movgestrec.importomodifica * -1;
      -- 05.06.2020 Sofia Jira SIAC-7593
      v_importomodifica:= movgestrec.importo_reimputato;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato',
									   'flagDaReanno') ); -- 02.10.2020 SIAC-7593

-- SIAC-6997 ---------------- INIZIO --------------------
    if motivo = 'REIMP' then
-- SIAC-6997 ---------------- FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
-- SIAC-6997 ---------------- INIZIO --------------------
    else
      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdareanno_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );
    end if;
-- SIAC-6997 ----------------  FINE --------------------

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      /*strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );*/
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

	   -- 07.02.2018 Sofia siac-5368
	   if impostaProvvedimento=true then
       	strmessaggio:='Inserimento   movgest_ts_id='
	      ||movgestrec.movgest_ts_id::VARCHAR
    	  || ' [siac_r_movgest_ts_atto_amm].';
       	INSERT INTO siac_r_movgest_ts_atto_amm
	  	(
		 movgest_ts_id,
	     attoamm_id,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione
	  	)
        values
        (
         movgesttsidret,
         movgestrec.attoamm_id,
         datainizioval,
	 	 enteproprietarioid,
	 	 loginoperazione
        );
       end if;


      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      -- 07.02.2023 Sofia Jira SIAC-8895
      if motivo = 'REANNO' then
       INSERT INTO siac_r_movgest_ts_programma
 	   (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	   )
	   (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL 
	  );
	 else -- 07.02.2023 Sofia Jira SIAC-8895
	  INSERT INTO siac_r_movgest_ts_programma
 	   (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	   )
	   (
			 SELECT movgesttsidret,
					           pNew.programma_id,
		  					   datainizioval,
					           enteproprietarioid,
					           loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
			  			    siac_t_programma prog,siac_t_programma pNew,siac_r_programma_stato rs,siac_d_programma_stato stato
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND         prog.programma_id=r.programma_id
			 and           pNew.bil_id =bilancioId 
			 and           pNew.programma_tipo_id =prog.programma_tipo_id 
			 and           pNew.programma_code =prog.programma_code 
			 and           rs.programma_id=pNew.programma_id 
			 and           stato.programma_stato_id=rs.programma_stato_id 
			 and           stato.programma_stato_code ='VA'
			 AND         prog.data_cancellazione IS NULL
			 AND         prog.validita_fine IS NULL
			 AND         r.data_cancellazione IS NULL
			 AND         r.validita_fine IS NULL 
			 AND         pNew.data_cancellazione IS NULL
			 AND         pNew.validita_fine IS null
			 AND         rs.data_cancellazione IS NULL
			 AND         rs.validita_fine IS NULL
	  );
	 end if;

     --- 18.06.2019 Sofia SIAC-6702
	 if p_movgest_tipo_code=imp_movgest_tipo then
      -- siac_r_movgest_ts_storico_imp_acc
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_storico_imp_acc].';
      INSERT INTO siac_r_movgest_ts_storico_imp_acc
	  (
			movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.movgest_anno_acc,
             		r.movgest_numero_acc,
		            r.movgest_subnumero_acc,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_storico_imp_acc r
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );
      end if;

      /* 16.03.2023 Sofia SIAC-TASK-#44
	  -- siac_r_mutuo_voce_movgest

      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );
	  */
	  
      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function  siac.fnc_fasi_bil_gest_reimputa_elabora 
(   integer, integer, integer, boolean, varchar, timestamp, varchar,varchar,
    out  integer,  out integer, out  varchar) owner to siac;

drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid         INTEGER,
                                                              enteproprietarioid      integer,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR );
															  
CREATE OR replace FUNCTION fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid         INTEGER,
                                                              enteproprietarioid      integer,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR ) returns RECORD
AS
  $body$
  DECLARE
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    reimputazioneRec  record;
  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio clean.';

    FOR reimputazionerec IN
    (
           SELECT reimputazione_id,
                  movgestnew_ts_id,
      		      movgestnew_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'X' )
    LOOP

        strmessaggio :='cancellazione [siac_r_movgest_bil_elem] con movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar||'.';
        DELETE from  siac_r_movgest_bil_elem where movgest_id = reimputazionerec.movgestnew_id  ;

        if reimputazionerec.movgestnew_ts_id IS not null then
          strmessaggio :='cancellazione [siac_r_movgest_ts_stato] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_stato where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_class] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_class where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_attr] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_attr where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_atto_amm] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_atto_amm where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_sog] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_sog where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_sogclasse] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_sogclasse where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_programma] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_programma where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

		  /** 	 16.03.2023 Sofia SIAC-TASK-#44
          strmessaggio :='cancellazione [siac_r_mutuo_voce_movgest] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_mutuo_voce_movgest where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;
		  **/

          strmessaggio :='cancellazione [siac_r_causale_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_causale_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_subdoc_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_subdoc_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_predoc_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_predoc_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_t_movgest_ts_det] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_t_movgest_ts_det where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_t_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_t_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;
        end if;

        strmessaggio :='cancellazione [siac_t_movgest] con movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar||'.';
        DELETE from  siac_t_movgest where movgest_id = reimputazionerec.movgestnew_id  ;

    END LOOP;
    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;
  
  alter function  fnc_fasi_bil_gest_reimputa_clean( INTEGER, integer, OUT  INTEGER, OUT  INTEGER,OUT  VARCHAR ) owner to siac;	
  
 drop function if exists siac.fnc_fasi_bil_gest_apertura_pluri_elabora
( enteproprietarioid integer, annobilancio integer, fasebilelabid integer, tipocapitologest character varying, tipomovgest character varying, tipomovgestts character varying, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_pluri_elabora
( enteproprietarioid integer, annobilancio integer, fasebilelabid integer, tipocapitologest character varying, tipomovgest character varying, tipomovgestts character varying, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;

    movGestRec        record;
    aggProgressivi    record;


	movgestTsTipoDetIniz integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetAtt  integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetUtil integer; -- 29.01.2018 Sofia siac-5830

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';
	SIM_MOVGEST_TS_TIPO CONSTANT varchar:='SIM';
    SAC_MOVGEST_TS_TIPO CONSTANT varchar:='SAC';


    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

	-- 14.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;


    INIZ_MOVGEST_TS_DET_TIPO  constant varchar:='I'; -- 29.01.2018 Sofia siac-5830
    ATT_MOVGEST_TS_DET_TIPO   constant varchar:='A'; -- 29.01.2018 Sofia siac-5830
    UTI_MOVGEST_TS_DET_TIPO   constant varchar:='U'; -- 29.01.2018 Sofia siac-5830

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

    -- 14.05.2020 Sofia SIAC-7593
    elemDetCompTipoId INTEGER:=null;
BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    raise notice 'fnc_fasi_bil_gest_apertura_pluri_elabora tipoCapitoloGest=%',tipoCapitoloGest;

	if tipoMovGest=IMP_MOVGEST_TIPO then
    	 movGestTsTipoCode=SIM_MOVGEST_TS_TIPO;
    else movGestTsTipoCode=SAC_MOVGEST_TS_TIPO;
    end if;

    dataInizioVal:= clock_timestamp();
--    dataEmissione:=((annoBilancio-1)::varchar||'-12-31')::timestamp; -- da capire che data impostare come data emissione
    -- 23.08.2016 Sofia in attesa di indicazioni diverse ho deciso di impostare il primo di gennaio del nuovo anno di bilancio
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;
--    raise notice 'fasbilElabId %',faseBilElabId;
	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora tipoMovGest='||tipoMovGest||' minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_pluri.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_pluri fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna movimento da creare.';
    end if;


    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_pluri].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_pluri_id) into maxId
        from fase_bil_t_gest_apertura_pluri fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null;
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;


     strMessaggio:='Lettura id identificativo per tipo capitolo='||tipoCapitoloGest||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=tipoCapitoloGest
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I,A
     strMessaggio:='Lettura id identificativo per tipoMovGest='||tipoMovGest||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=tipoMovGest
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
          movGestTsTipoId:=tipoMovGestTsTId;
     else movGestTsTipoId:=tipoMovGestTsSId;
     end if;

     if movGestTsTipoId is null then
      strMessaggio:='Lettura identificativo per tipoMovGestTs='||tipoMovGestTs||'.';
      select tipo.movgest_ts_tipo_id into strict movGestTsTipoId
      from siac_d_movgest_ts_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.movgest_ts_tipo_code=tipoMovGestTs
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
     end if;


	 -- 14.02.2017 Sofia SIAC-4425
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;
     end if;

	 -- 29.01.2018 Sofia siac-5830
     strMessaggio:='Lettura identificativo per tipo importo='||INIZ_MOVGEST_TS_DET_TIPO||'.';
     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetIniz
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=INIZ_MOVGEST_TS_DET_TIPO;

     strMessaggio:='Lettura identificativo per tipo importo='||ATT_MOVGEST_TS_DET_TIPO||'.';

     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetAtt
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=ATT_MOVGEST_TS_DET_TIPO;

--	 if tipoMovGest=ACC_MOVGEST_TIPO then
     	 strMessaggio:='Lettura identificativo per tipo importo='||UTI_MOVGEST_TS_DET_TIPO||'.';
		 select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetUtil
    	 from siac_d_movgest_ts_det_tipo tipo
	     where tipo.ente_proprietario_id=enteProprietarioId
    	 and   tipo.movgest_ts_det_tipo_code=UTI_MOVGEST_TS_DET_TIPO;
  --   end if;
     -- 29.01.2018 Sofia siac-5830

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- se impegno-accertamento verifico che i relativi capitoli siano presenti sul nuovo Bilancio
     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. INIZIO.';
	   	codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
       	 validita_inizio, login_operazione, ente_proprietario_id
      	)
      	values
      	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      	returning fase_bil_elab_log_id into codResult;

      	if codResult is null then
     		raise exception ' Errore in inserimento LOG.';
      	end if;

        update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='IMAC1',
            scarto_desc='Movimento impegno/accertamento pluriennale privo di capitolo nel nuovo bilancio'
      	from siac_t_bil_elem elem
      	where fase.fase_bil_elab_id=faseBilElabId
      	and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      	and   fase.movgest_tipo=movGestTsTipoCode
     	and   fase.fl_elab='N'
        and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
     	and   elem.ente_proprietario_id=fase.ente_proprietario_id
        and   elem.elem_id=fase.elem_orig_id
    	and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
     	and   elem.data_cancellazione is null
     	and   elem.validita_fine is null
        and   not exists (select 1 from siac_t_bil_elem elemnew
                          where elemnew.ente_proprietario_id=elem.ente_proprietario_id
                          and   elemnew.elem_tipo_id=elem.elem_tipo_id
                          and   elemnew.bil_id=bilancioId
                          and   elemnew.elem_code=elem.elem_code
                          and   elemnew.elem_code2=elem.elem_code2
                          and   elemnew.elem_code3=elem.elem_code3
                          and   elemnew.data_cancellazione is null
                          and   elemnew.validita_fine is null
                         );


        strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. FINE.';
	   	codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
       	 validita_inizio, login_operazione, ente_proprietario_id
      	)
      	values
      	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      	returning fase_bil_elab_log_id into codResult;

      	if codResult is null then
     		raise exception ' Errore in inserimento LOG.';
      	end if;

     end if;
     -- se sub, verifico prima se i relativi padri sono stati elaborati e creati
     -- se non sono stati ribaltati scarto  i relativi sub per escluderli da elaborazione

     if tipoMovGestTs=MOVGEST_TS_S_TIPO then
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. INIZIO.';
	  codResult:=null;
	  insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
       validita_inizio, login_operazione, ente_proprietario_id
      )
      values
      (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

      if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
      end if;

      update fase_bil_t_gest_apertura_pluri fase
      set fl_elab='X',
          scarto_code='SUB1',
          scarto_desc='Movimento sub impegno/accertamento pluriennale privo di impegno/accertamento pluri nel nuovo bilancio'
      from siac_t_movgest mprec
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   fase.movgest_tipo=movGestTsTipoCode
      and   fase.fl_elab='N'
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   mprec.ente_proprietario_id=fase.ente_proprietario_id
      and   mprec.movgest_id=fase.movgest_orig_id
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   mprec.data_cancellazione is null
      and   mprec.validita_fine is null
      and   not exists (select 1 from siac_t_movgest mnew
                        where mnew.ente_proprietario_id=mprec.ente_proprietario_id
                        and   mnew.movgest_tipo_id=mprec.movgest_tipo_id
                        and   mnew.bil_id=bilancioId
                        and   mnew.movgest_anno=mprec.movgest_anno
                        and   mnew.movgest_numero=mprec.movgest_numero
                        and   mnew.data_cancellazione is null
                        and   mnew.validita_fine is null
                        );
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. FINE.';
	  codResult:=null;
	  insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
       validita_inizio, login_operazione, ente_proprietario_id
      )
      values
      (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

      if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
      end if;

     end if;

     strMessaggio:='Inizio ciclo per tipoMovGest='||tipoMovGest||' tipoMovGestTs='||tipoMovGestTs||'.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     for movGestRec in
     (select tipo.movgest_tipo_code,
     		 m.*,
             tstipo.movgest_ts_tipo_code,
             ts.*,
             fase.fase_bil_gest_ape_pluri_id,
             fase.movgest_orig_id,
             fase.movgest_orig_ts_id,
             fase.elem_orig_id,
             mpadre.movgest_id movgest_id_new,
             tspadre.movgest_ts_id movgest_ts_id_padre_new
      from  fase_bil_t_gest_apertura_pluri fase
             join siac_t_movgest m
               left outer join
               ( siac_t_movgest mpadre join  siac_t_movgest_ts tspadre
                   on (tspadre.movgest_id=mpadre.movgest_id
                   and tspadre.movgest_ts_tipo_id=tipoMovGestTsTId
                   and tspadre.data_cancellazione is null
                   and tspadre.validita_fine is null)
                )
                on (mpadre.movgest_anno=m.movgest_anno
                and mpadre.movgest_numero=m.movgest_numero
                and mpadre.bil_id=bilancioId
                and mpadre.ente_proprietario_id=m.ente_proprietario_id
                and mpadre.movgest_tipo_id = tipoMovGestId
                and mpadre.data_cancellazione is null
                and mpadre.validita_fine is null)
             on   ( m.ente_proprietario_id=fase.ente_proprietario_id  and   m.movgest_id=fase.movgest_orig_id),
            siac_d_movgest_tipo tipo,
            siac_t_movgest_ts ts,
            siac_d_movgest_ts_tipo tstipo
      where fase.fase_bil_elab_id=faseBilElabId
          and   tipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tipo.movgest_tipo_code=tipoMovGest
          and   tstipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tstipo.movgest_ts_tipo_code=tipoMovGestTs
          and   m.ente_proprietario_id=fase.ente_proprietario_id
          and   m.movgest_id=fase.movgest_orig_id
          and   m.movgest_tipo_id=tipo.movgest_tipo_id
          and   ts.ente_proprietario_id=fase.ente_proprietario_id
          and   ts.movgest_ts_id=fase.movgest_orig_ts_id
          and   ts.movgest_ts_tipo_id=tstipo.movgest_ts_tipo_id
          and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
          and   fase.fl_elab='N'
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          order by fase_bil_gest_ape_pluri_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        codResult:=null;
		elemNewId:=null;

		-- 14.05.2020 Sofia SIAC-7593
        elemDetCompTipoId:=null;

        strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
         raise notice 'strMessaggio=%  movGestRec.movgest_id_new=%', strMessaggio, movGestRec.movgest_id_new;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

    	codResult:=null;
        if movGestRec.movgest_id_new is null then
      	 strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                       ' anno='||movGestRec.movgest_anno||
                       ' numero='||movGestRec.movgest_numero||' [siac_t_movgest].';
     	 insert into siac_t_movgest
         (movgest_anno,
		  movgest_numero,
		  movgest_desc,
		  movgest_tipo_id,
		  bil_id,
		  validita_inizio,
	      ente_proprietario_id,
	      login_operazione,
	      parere_finanziario,
	      parere_finanziario_data_modifica,
	      parere_finanziario_login_operazione)
         values
         (movGestRec.movgest_anno,
		  movGestRec.movgest_numero,
		  movGestRec.movgest_desc,
		  movGestRec.movgest_tipo_id,
		  bilancioId,
		  dataInizioVal,
	      enteProprietarioId,
	      loginOperazione,
	      movGestRec.parere_finanziario,
	      movGestRec.parere_finanziario_data_modifica,
	      movGestRec.parere_finanziario_login_operazione
         )
         returning movgest_id into movGestIdRet;
         if movGestIdRet is null then
           strMessaggioTemp:=strMessaggio;
           codResult:=-1;
         end if;
			raise notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movGestIdRet;
		 if codResult is null then
         strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';

         raise notice 'strMessaggio=%',strMessaggio;
         -- 14.05.2020 Sofia SIAC-7593
         --select  new.elem_id into elemNewId
         select  new.elem_id , r.elem_det_comp_tipo_id into  elemNewId,elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
         from siac_r_movgest_bil_elem r,
              siac_t_bil_elem prec, siac_t_bil_elem new
         where r.movgest_id=movGestRec.movgest_orig_id
         and   prec.elem_id=r.elem_id
         and   new.elem_code=prec.elem_code
         and   new.elem_code2=prec.elem_code2
         and   new.elem_code3=prec.elem_code3
         and   prec.elem_tipo_id=new.elem_tipo_id
         and   prec.bil_id=bilancioPrecId
         and   new.bil_id=bilancioId
         and   r.data_cancellazione is null
         and   r.validita_fine is null
         and   prec.data_cancellazione is null
         and   prec.validita_fine is null
         and   new.data_cancellazione is null
         and   new.validita_fine is null;
         if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
         end if;
		 raise notice 'elemNewId=%',elemNewId;
		 if codResult is null then
          	  strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
             	            ' anno='||movGestRec.movgest_anno||
                 	        ' numero='||movGestRec.movgest_numero||' [siac_r_movgest_bil_elem]';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_Det_comp_tipo_id, -- 14.05.2020 Sofia SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   elemNewId,
               elemDetCompTipoId, -- 14.05.2020 Sofia SIAC-7593
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
         end if;
        end if;
      else
        movGestIdRet:=movGestRec.movgest_id_new;
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';
        -- 14.05.2020 Sofia SIAC-7593
        --select  r.elem_id into elemNewId
        select  r.elem_id,r.elem_det_comp_tipo_id into elemNewId, elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
        from siac_r_movgest_bil_elem r
        where r.movgest_id=movGestIdRet
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;
      end if;


      if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts].';
		raise notice 'strMessaggio=% ',strMessaggio;
/*        dataEmissione:=( (2018::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;*/

        -- 21.02.2019 Sofia SIAC-6683
        dataEmissione:=( (annoBilancio::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;
        raise notice 'dataEmissione=% ',dataEmissione;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        values
        ( movGestRec.movgest_ts_code,
          movGestRec.movgest_ts_desc,
          movGestIdRet,    -- inserito se I/A, per SUB ricavato
          movGestRec.movgest_ts_tipo_id,
          movGestRec.movgest_ts_id_padre_new,  -- valorizzato se SUB
          movGestRec.movgest_ts_scadenza_data,
          movGestRec.ordine,
          movGestRec.livello,
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataInizioVal else dataEmissione end), -- 25.11.2016 Sofia
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataEmissione else dataInizioVal end), -- 25.11.2016 Sofia
--          dataEmissione, -- 12.04.2017 Sofia
          dataEmissione,   -- 09.02.2018 Sofia
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          movGestRec.siope_tipo_debito_id,
		  movGestRec.siope_assenza_motivazione_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;
        raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;
       -- siac_r_liquidazione_movgest --> x pluriennali non dovrebbe esserci legame e andrebbe ricreato cmq con il ribaltamento delle liq
       -- siac_r_ordinativo_ts_movgest_ts --> x pluriennali non dovrebbe esistere legame in ogni caso non deve essere  ribaltato
       -- siac_r_movgest_ts --> legame da creare alla conclusione del ribaltamento dei pluriennali e dei residui

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        -- 29.01.2018 Sofia siac-5830 - insert sostituita con le tre successive


        /*insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );*/
        --returning movgest_ts_det_id into  codResult;

        -- 29.01.2018 Sofia siac-5830 - iniziale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetIniz,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - attuale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - utilizzabile = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetUtil,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );
--        returning movgest_classif_id into  codResult;

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;


        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );
        --returning bil_elem_attr_id into  codResult;

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

        /*select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        --returning movgest_atto_amm_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
         end if;
       end if;*/

       -- se movimento provvisorio atto_amm potrebbe non esserci
	   select 1  into codResult
       from siac_r_movgest_ts_atto_amm det1
       where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
       and   det1.data_cancellazione is null
       and   det1.validita_fine is null
       and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
			             where det.movgest_ts_id=movGestTsIdRet
					       and   det.data_cancellazione is null
					       and   det.validita_fine is null
					       and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning movgest_ts_sog_id into  codResult;

        /*select 1 into codResult
        from siac_r_movgest_ts_sog det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
          and   classe.data_cancellazione is null
          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning soggetto_classe_id into  codResult;

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- 03.05.2019 Sofia siac-6255
       if codResult is null then
         -- siac_r_movgest_ts_programma
         if faseOp=G_FASE then
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );
          --returning movgest_ts_programma_id into  codResult;
          /*select 1 into codResult
          from siac_r_movgest_ts_programma det
          where det.movgest_ts_id=movGestTsIdRet
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   det.login_operazione=loginOperazione;*/

		  -- 03.05.2019 Sofia siac-6255
          /*
          insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
          select 1  into codResult
          from siac_r_movgest_ts_programma det1
          where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   det1.data_cancellazione is null
          and   det1.validita_fine is null
          and   not exists (select 1 from siac_r_movgest_ts_programma det
                            where det.movgest_ts_id=movGestTsIdRet
                              and   det.data_cancellazione is null
                              and   det.validita_fine is null
                              and   det.login_operazione=loginOperazione);

          if codResult is not null then
           codResult:=-1;
           strMessaggioTemp:=strMessaggio;
          else codResult:=null;
          end if;*/

          -- siac_r_movgest_ts_cronop_elem
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
            and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null;

          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
                 siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null;
         end if;
       end if;
       -- 03.05.2019 Sofia siac-6255

	/*	16.03.2023 Sofia SIAC-TASK-#44							
	   -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning mut_voce_movgest_id into  codResult;

        **select 1 into codResult
        from siac_r_mutuo_voce_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;**

		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
	  */ 

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa economale - da non ricreare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning gstmovgest_id into  codResult;

    *    select 1 into codResult
        from siac_r_giustificativo_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*

		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

        *select 1 into codResult
        from siac_r_cartacont_det_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_causale_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning caus_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_causale_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_fondo_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning liq_movgest_id into  codResult;

       /* select 1 into codResult
        from siac_r_fondo_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_richiesta_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning riceconsog_id into  codResult;

       /* select 1 into codResult
        from siac_r_richiesta_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_subdoc_movgest_ts].';

        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

       /* select 1 into codResult
        from siac_r_subdoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning predoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_predoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- cancellazione logica relazioni anno precedente
       -- siac_r_cartacont_det_movgest_ts
/*  non si gestisce in seguito ad indicazioni con Annalina
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' . Cancellazione siac_r_cartacont_det_movgest_ts anno bilancio precedente.';

        update siac_r_cartacont_det_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_cartacont_det_movgest_ts r,	siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if codResult is not null then
        	 strMessaggioTemp:=strMessaggio;
        	 codResult:=-1;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null and tipoMovGest=IMP_MOVGEST_TIPO then
		strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_storico_imp_acc].';
          insert into siac_r_movgest_ts_storico_imp_acc
          ( movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             r.movgest_anno_acc,
             r.movgest_numero_acc,
             r.movgest_subnumero_acc,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_storico_imp_acc r
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
          );


          select 1  into codResult
          from siac_r_movgest_ts_storico_imp_acc det1
          where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   det1.data_cancellazione is null
          and   det1.validita_fine is null
          and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
                            where det.movgest_ts_id=movGestTsIdRet
                              and   det.data_cancellazione is null
                              and   det.validita_fine is null
                              and   det.login_operazione=loginOperazione);
          raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

          if codResult is not null then
           codResult:=-1;
           strMessaggioTemp:=strMessaggio;
          else codResult:=null;
          end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_pluri per scarto
	   if codResult=-1 then
       	/*if movGestRec.movgest_id_new is null then
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        end if; spostato sotto */

        if movGestTsIdRet is not null then
         -- siac_t_movgest_ts
 	    /*strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet; spostato sotto */

         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
/*
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet;*/
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

		 -- 17.06.2019 Sofia SIAC-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if movGestRec.movgest_id_new is null then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;


        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='PLUR1',
            scarto_desc='Movimento impegno/accertamento sub  pluriennale non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

		continue;
       end if;

	   -- annullamento relazioni movimenti precedenti
       -- siac_r_subdoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             --strMessaggioTemp:=strMessaggio;
             raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
--             strMessaggioTemp:=strMessaggio;
               raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'. Aggiornamento fase_bil_t_gest_apertura_pluri per fine elaborazione.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='S',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet,
            elem_id=elemNewId,
            elem_Det_comp_tipo_id=elemDetCompTipoId, -- 14.05.2020 Sofia Jira SIAC-7593
            bil_id=bilancioId
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

       strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


     -- aggiornamento progressivi
	 if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	 strMessaggio:='Aggiornamento progressivi.';
		 select * into aggProgressivi
   		 from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGest, loginOperazione);
	     if aggProgressivi.codresult=-1 then
			RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
     	 end if;
     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     	INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'N',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
        and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null);

        -- insert S per impegni mov.movgest_anno::integer=annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
		INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'S',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::integer=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null)
        and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
						 where ra.movgest_ts_id=ts.movgest_ts_id
						 and   atto.attoamm_id=ra.attoamm_id
				 		 and   atto.attoamm_anno::integer < annoBilancio
		     			 and   ra.data_cancellazione is null
				         and   ra.validita_fine is null);

        -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
		update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
		and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atto amministrativo antecedente.';
        update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts,
		     siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::INTEGER=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   ra.movgest_ts_id=ts.movgest_ts_id
		and   atto.attoamm_id=ra.attoamm_id
		and   atto.attoamm_anno::integer < annoBilancio
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        and   ra.data_cancellazione is null
        and   ra.validita_fine is null;

     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-2.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_gest_apertura_pluri_elabora
(  integer,  integer,  integer,  character varying,  character varying,  character varying,  integer,  integer,  character varying,  timestamp without time zone, OUT  integer, OUT  character varying) owner to siac;

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_liq_elabora_liq 
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_liq(enteproprietarioid integer, annobilancio integer, fasebilelabid integer, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;


    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;

    movGestRec        record;


    liqIdRet          integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';


BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento liquidazioni  residue da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessuna liquidazione da creare.';
    end if;


/*    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti creati in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   not exists (select 1 from fase_bil_t_gest_apertura_liq_imp fase1
                  	  where fase1.fase_bil_elab_id=faseBilElabId
				      and   fase1.data_cancellazione is null
				      and   fase1.validita_fine is null
    	              and   fase1.movgest_orig_id=fase.movgest_orig_id
        	          and   fase1.movgest_orig_ts_id=fase.movgest_orig_ts_id
            	      and   fase1.fl_elab='I'
                     );
    if codResult is not null then
      raise exception ' Esistono liquidazioni da creare per cui non e'' stato creato il relativo movimento residuo.';
    end if;*/



    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_id) into maxId
        from fase_bil_t_gest_apertura_liq fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	 strMessaggio:='Verifica scarti in fase_bil_t_gest_apertura_liq per inesistenza movimento gestione nel nuovo bilancio.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	 update fase_bil_t_gest_apertura_liq fase
     set   fl_elab='X',
           scarto_code='LIQ1',
           scarto_desc='Movimento di gestione non esistente in nuovo bilancio'
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   not exists (select 1
                       from siac_t_movgest mov, siac_t_movgest_ts ts,
                            siac_t_movgest movprec, siac_t_movgest_ts tsprec
    			       where movprec.movgest_id=fase.movgest_orig_id
                       and   tsprec.movgest_ts_id=fase.movgest_orig_ts_id
                       and   tsprec.movgest_id=movprec.movgest_id
                       and   mov.bil_id=bilancioId
                       and   mov.movgest_tipo_id=movprec.movgest_tipo_id
                       and   mov.movgest_anno=movprec.movgest_anno
                       and   mov.movgest_numero=movprec.movgest_numero
                       and   ts.movgest_id=mov.movgest_id
                       and   ts.movgest_ts_code=tsprec.movgest_ts_code
                       and   mov.data_cancellazione is null
                       and   mov.validita_fine is null
                       and   ts.data_cancellazione is null
                       and   ts.validita_fine is null
                       )
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;


     strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_liq per estremi movimento gestione nel nuovo bilancio.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	 update fase_bil_t_gest_apertura_liq fase
     set   movgest_id=mov.movgest_id,
           movgest_ts_id=ts.movgest_ts_id
     from siac_t_movgest mov, siac_t_movgest_ts ts,
          siac_t_movgest movprec, siac_t_movgest_ts tsprec
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   fase.movgest_id is null
     and   fase.movgest_ts_id is null
     and   movprec.movgest_id=fase.movgest_orig_id
     and   tsprec.movgest_ts_id=fase.movgest_orig_ts_id
     and   tsprec.movgest_id=movprec.movgest_id
     and   mov.bil_id=bilancioId
     and   mov.movgest_tipo_id=movprec.movgest_tipo_id
     and   mov.movgest_anno=movprec.movgest_anno
     and   mov.movgest_numero=movprec.movgest_numero
     and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_code=tsprec.movgest_ts_code
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;

     codResult:=null;
	 select 1 into codResult
     from fase_bil_t_gest_apertura_liq fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   fase.movgest_id is null
     and   fase.movgest_ts_id is null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;
	 if codResult is not null then
     	raise exception ' Non tutti i record sono stati correttamente aggiornati.';
     end if;

	 strMessaggio:='Verifica scarti in fase_bil_t_gest_apertura_liq per liquidazione provvisoria senza documento.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	 update fase_bil_t_gest_apertura_liq fase
     set   fl_elab='X',
           scarto_code='LIQ3',
           scarto_desc='Liquidazione provvisoria senza documenti.'
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   exists (select 1 from siac_r_liquidazione_stato rstato
                                ,siac_d_liquidazione_stato dstato
    			       where rstato.liq_id=fase.liq_orig_id
                       and   rstato.liq_stato_id = dstato.liq_stato_id
                       and   dstato.liq_stato_code = 'P'
                       and   rstato.data_cancellazione is null
                       and   rstato.validita_fine is null)
     and   not exists (select 1
                       from siac_r_subdoc_liquidazione rsub
    			       where rsub.liq_id=fase.liq_orig_id
                       and   rsub.data_cancellazione is null
                       and   rsub.validita_fine is null
                       )
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;


     -- SIAC-8551 28.04.2022  Sofia - inizio  
     strMessaggio:='Verifica scarti in fase_bil_t_gest_apertura_liq per liquidazione riferita a documento collegato a prov.cassa di anno in chiusura.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	 update fase_bil_t_gest_apertura_liq fase
     set   fl_elab='X',
           scarto_code='LIQ4',
           scarto_desc='Liquidazione su documento collegato a prov. cassa su anno in chiusura.'
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fase_bil_gest_ape_liq_id between minId and maxId
     and   fase.fl_elab='N'
     and   exists (select 1
                   from siac_r_subdoc_liquidazione rsub,siac_r_subdoc_prov_cassa rprov,siac_t_prov_cassa p
    		       where rsub.liq_id=fase.liq_orig_id
    		       AND   rprov.subdoc_id=rsub.subdoc_id 
    		       AND   p.provc_id=rprov.provc_id
    		       AND   p.provc_anno::integer=(annoBilancio-1)
                   and   rsub.data_cancellazione is null
                   and   rsub.validita_fine is NULL
                   and   rprov.data_cancellazione is null
                   and   rprov.validita_fine is null
                   and   p.data_cancellazione is null
                   and   p.validita_fine is null
                   )
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null;
     -- SIAC-8551 28.04.2022  Sofia - fine 
    
     strMessaggio:='Inizio ciclo per generazione liquidazioni.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_liq_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
              fase.liq_orig_id,
		      fase.elem_orig_id,
              fase.elem_id,
              fase.movgest_id,
              fase.movgest_ts_id,
	          fase.liq_importo
      from  fase_bil_t_gest_apertura_liq fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      order by fase.fase_bil_gest_ape_liq_id
     )
     loop

     	liqIdRet:=null;
        codResult:=null;

        -- siac_t_liquidazione
        -- siac_r_liquidazione_stato
        -- siac_r_liquidazione_soggetto
        -- siac_r_liquidazione_movgest
        -- siac_r_liquidazione_atto_amm
		-- 16.03.2023 Sofia SIAC-TASK-#44 eliminata gestione mutuo_liq
		-- siac_r_mutuo_voce_liquidazione								 
        -- siac_r_liquidazione_class
        -- siac_r_liquidazione_attr
        -- siac_r_subdoc_liquidazione
		--raise notice 'Inizio ciclo';
        strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'.';
		--raise notice 'Inizio ciclo strMessaggio=%',strMessaggio;

 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

         codResult:=null;

         -- siac_t_liquidazione
		 strMessaggio:=strMessaggio||'Inseimento liquidazione [siac_t_liquidazione].';
         insert into siac_t_liquidazione
         (liq_anno,
		  liq_numero,
		  liq_desc,
		  liq_emissione_data,
		  liq_importo,
		  liq_automatica,
		  liq_convalida_manuale,
		  contotes_id,
		  dist_id,
		  bil_id,
		  modpag_id,
          soggetto_relaz_id,
		  validita_inizio,
		  ente_proprietario_id,
	      login_operazione,
	      siope_tipo_debito_id ,
		  siope_assenza_motivazione_id

         )
         (select
           liq.liq_anno,
		   liq.liq_numero,
		   liq.liq_desc,
		   liq.liq_emissione_data,
		   movGestRec.liq_importo,
		   liq.liq_automatica,
		   liq.liq_convalida_manuale,
		   liq.contotes_id,
		   liq.dist_id,
		   bilancioId,
		   liq.modpag_id,
           liq.soggetto_relaz_id,
		   dataInizioVal,
		   enteProprietarioId,
	       loginOperazione,
           liq.siope_tipo_debito_id,
		   liq.siope_assenza_motivazione_id

           from siac_t_liquidazione liq
           where liq.liq_id=movGestRec.liq_orig_id
         )
         returning liq_id into liqIdRet;

         if liqIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
         end if;

         raise notice 'dopo inserimento siac_t_liquidazione liqIdRet=%',liqIdRet;

         -- siac_r_liquidazione_stato
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_stato.';

            insert into siac_r_liquidazione_stato
            (liq_id,
             liq_stato_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select liqIdRet,
                    r.liq_stato_id,
                    dataInizioVal,
		  	 	    enteProprietarioId,
	                loginOperazione
             from siac_r_liquidazione_stato r
             where r.liq_id= movGestRec.liq_orig_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
            )
            returning liq_stato_r_id into codResult;

            raise notice 'dopo inserimento siac_r_liquidazione_stato codResult=%',codResult;

            if codResult is null then
      	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
            else codResult:=null;
	        end if;
         end if;

         -- siac_r_liquidazione_soggetto
		 if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_soggetto.';
            insert into siac_r_liquidazione_soggetto
            (liq_id,
             soggetto_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select liqIdRet,
                    r.soggetto_id,
                    dataInizioVal,
		  	 	    enteProprietarioId,
	                loginOperazione
             from siac_r_liquidazione_soggetto r
             where r.liq_id=movGestRec.liq_orig_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
            )
            returning liq_soggetto_id into codResult;

            raise notice 'dopo inserimento siac_r_liquidazione_soggetto codResult=%',codResult;

            if codResult is null then
      	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
            else codResult:=null;
	        end if;

         end if;

         -- siac_r_liquidazione_movgest
         if codResult is null then
             strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_movgest.';
             insert into siac_r_liquidazione_movgest
             (liq_id,
              movgest_ts_id,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
             )
             values
             (liqIdRet,
              movGestRec.movgest_ts_id,
              dataInizioVal,
 	 	      enteProprietarioId,
	          loginOperazione
             );

             select 1 into codResult
             from siac_r_liquidazione_movgest r
             where r.liq_id=liqIdRet
             and   r.data_cancellazione is null
             and   r.validita_fine is null;

             raise notice 'dopo inserimento siac_r_liquidazione_movgest codResult=%',codResult;

             if codResult is null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	         else codResult:=null;
             end if;

         end if;

		 -- siac_r_liquidazione_atto_amm
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                           ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                           ' movgest_orig_id='||movGestRec.movgest_orig_id||
                           ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                           ' elem_orig_id='||movGestRec.elem_orig_id||
                           ' elem_id='||movGestRec.elem_id||'. Inserimento siac_r_liquidazione_atto_amm.';
            insert into siac_r_liquidazione_atto_amm
            (liq_id,
             attoamm_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select  liqIdRet,
                     r.attoamm_id,
                     dataInizioVal,
	 	 	         enteProprietarioId,
	                 loginOperazione
             from siac_r_liquidazione_atto_amm r
             where r.liq_id=movGestRec.liq_orig_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
            )
            returning liq_atto_amm_id into codResult;
            raise notice 'dopo inserimento siac_r_liquidazione_atto_amm codResult=%',codResult;

            if codResult is null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	        else codResult:=null;
            end if;

         end if;



		 -- siac_r_liquidazione_class
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_class.';
            insert into  siac_r_liquidazione_class
            (liq_id,
             classif_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select  liqIdRet,
                     r.classif_id,
                     dataInizioVal,
	 	 	         enteProprietarioId,
	                 loginOperazione
             from siac_r_liquidazione_class r, siac_t_class c
             where r.liq_id=movGestRec.liq_orig_id
             and   c.classif_id=r.classif_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   c.data_cancellazione is null
             and   c.validita_fine is null
            );

            select 1 into codResult
            from siac_r_liquidazione_class r,siac_t_class c
            where r.liq_id=movGestRec.liq_orig_id
             and   c.classif_id=r.classif_id
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   c.data_cancellazione is null
             and   c.validita_fine is null
             and   not exists ( select 1
				                from siac_r_liquidazione_class r
				                where r.liq_id=liqIdRet
					            and   r.data_cancellazione is null
					            and   r.validita_fine is null
                               );
			raise notice 'dopo inserimento siac_r_liquidazione_class codResult=%',codResult;

            if codResult is not null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	        else codResult:=null;
            end if;

         end if;

         -- siac_r_liquidazione_attr
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_liquidazione_attr.';
             insert into siac_r_liquidazione_attr
             (liq_id,
              attr_id,
              tabella_id,
			  boolean,
		      percentuale,
		      testo,
			  numerico,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
             )
             (select liqIdRet,
                     r.attr_id,
                     r.tabella_id,
			         r.boolean,
		             r.percentuale,
		             r.testo,
			         r.numerico,
                     dataInizioVal,
	 	 	         enteProprietarioId,
	                 loginOperazione
              from siac_r_liquidazione_attr r, siac_t_attr attr
              where r.liq_id=movGestRec.liq_orig_id
              and   attr.attr_id=r.attr_id
              and   r.data_cancellazione is null
              and   r.validita_fine is null
              and   attr.data_cancellazione is null
              and   attr.validita_fine is null
             );

             select 1 into codResult
             from siac_r_liquidazione_attr r, siac_t_attr attr
              where r.liq_id=movGestRec.liq_orig_id
              and   attr.attr_id=r.attr_id
              and   r.data_cancellazione is null
              and   r.validita_fine is null
              and   attr.data_cancellazione is null
              and   attr.validita_fine is null
              and   not exists (select 1
				                from siac_r_liquidazione_attr r
					            where r.liq_id=liqIdRet
					            and   r.data_cancellazione is null
					            and   r.validita_fine is null
                                );
			raise notice 'dopo inserimento siac_r_liquidazione_attr codResult=%',codResult;

             if codResult is not null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	         else codResult:=null;
             end if;
         end if;


         -- siac_r_subdoc_liquidazione
         if codResult is null then
         	strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Inserimento siac_r_subdoc_liquidazione.';
            insert into siac_r_subdoc_liquidazione
            (liq_id,
             subdoc_id,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            (select liqIdRet,
                    r.subdoc_id,
                    dataInizioVal,
	 	 	        enteProprietarioId,
	                loginOperazione
             from siac_r_subdoc_liquidazione r, siac_t_subdoc sub
             where r.liq_id=movGestRec.liq_orig_id
             and   sub.subdoc_id=r.subdoc_id
             and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
        			    	  )
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   sub.data_cancellazione is null
             and   sub.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
              and   not exists (select 1
                                from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                                where doc.doc_id = sub.doc_id
                                and   doc.doc_id = rst.doc_id
                                and   rst.data_cancellazione is null
                                and   rst.validita_fine is null
                                and   st.doc_stato_id = rst.doc_stato_id
                                and   st.doc_stato_code = 'A')
             );

             select 1 into codResult
             from siac_r_subdoc_liquidazione r, siac_t_subdoc sub
             where r.liq_id=movGestRec.liq_orig_id
             and   sub.subdoc_id=r.subdoc_id
             and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
        			    	  )
             and   not exists (select 1
				               from siac_r_subdoc_liquidazione r
					           where r.liq_id=liqIdRet
				               and   r.data_cancellazione is null
					           and   r.validita_fine is null)
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   sub.data_cancellazione is null
             and   sub.validita_fine is null
        	 and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
             ;
			raise notice 'dopo inserimento siac_r_subdoc_liquidazione codResult=%',codResult;

             if codResult is not null then
    	      strMessaggioTemp:=strMessaggio;
        	  codResult:=-1;
	         else codResult:=null;
             end if;

       end if;

	   -- cancellazione logica relazioni anno precedente
       -- siac_r_subdoc_liquidazione
       /* spostato sotto
       if codResult is null then
	        strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Cancellazione relazioni liquidazione su gestione prec. [siac_r_subdoc_liquidazione].';
	        update siac_r_subdoc_liquidazione r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.liq_id=movGestRec.liq_orig_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_liquidazione r
        	where r.liq_id=movGestRec.liq_orig_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

        end if; */

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq per scarto
	   if codResult=-1 then

         -- siac_r_subdoc_liquidazione
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_liquidazione.';
         delete from siac_r_subdoc_liquidazione    where liq_id=liqIdRet;


         -- siac_r_liquidazione_class
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_class.';
         delete from siac_r_liquidazione_class    where liq_id=liqIdRet;


         -- siac_r_liquidazione_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_attr.';
         delete from siac_r_liquidazione_attr    where liq_id=liqIdRet;



		 -- siac_r_liquidazione_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_atto_amm.';
         delete from siac_r_liquidazione_atto_amm    where liq_id=liqIdRet;

		 -- siac_r_liquidazione_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_movgest.';
         delete from siac_r_liquidazione_movgest    where liq_id=liqIdRet;

         -- siac_r_liquidazione_soggetto
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_soggetto.';
         delete from siac_r_liquidazione_soggetto    where liq_id=liqIdRet;

         -- siac_r_liquidazione_stato
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_liquidazione_stato.';
         delete from siac_r_liquidazione_stato    where liq_id=liqIdRet;

         -- siac_t_liquidazione
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_liquidazione.';
         delete from siac_t_liquidazione    where liq_id=liqIdRet;



        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq per scarto.';
      	update fase_bil_t_gest_apertura_liq fase
        set fl_elab='X',
            scarto_code='LIQ2',
            scarto_desc='Liquidazione residua non inserita.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_id=movGestRec.fase_bil_gest_ape_liq_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.liq_orig_id=movGestRec.liq_orig_id
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       if codResult is null then
	        strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Cancellazione relazioni liquidazione su gestione prec. [siac_r_subdoc_liquidazione].';
            -- 12.01.2017 Sofia sistemazione subdoc per quote pagate
	        update siac_r_subdoc_liquidazione r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.liq_id=movGestRec.liq_orig_id
            and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
        			    	  )
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
			and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_liquidazione r
        	where r.liq_id=movGestRec.liq_orig_id
            and   not exists (select 1
                               from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                    siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
			                   where rord.subdoc_id=r.subdoc_id
		        		        and  tsord.ord_ts_id=rord.ord_ts_id
				                and  ord.ord_id=tsord.ord_id
				                and  ord.bil_id=bilancioPrecId
		    	        	    and  rstato.ord_id=ord.ord_id
		        	        	and  stato.ord_stato_id=rstato.ord_stato_id
			        	        and  stato.ord_stato_code!='A'
			            	    and  rord.data_cancellazione is null
			                	and  rord.validita_fine is null
			    	            and  rstato.data_cancellazione is null
			        	        and  rstato.validita_fine is null
        			    	  )
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
	    	    --strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	       end if;

      end if;

	  strMessaggio:='Movimento liq_orig_id='||movGestRec.liq_orig_id||
                      ' movGestTsTipo='||movGestRec.movgest_ts_tipo||
                      ' elem_orig_id='||movGestRec.elem_orig_id||
                      ' elem_id='||movGestRec.elem_id||
                      ' movgest_id='||movGestRec.movgest_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_id||'. Aggiornamento fase_bil_t_gest_apertura_liq per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq fase
        set fl_elab='S',
            liq_id=liqIdRet
        where fase.fase_bil_gest_ape_liq_id=movGestRec.fase_bil_gest_ape_liq_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.liq_orig_id=movGestRec.liq_orig_id
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;

	 strMessaggio:='Cancellazione logica liq provv anno precedente';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     update siac_t_liquidazione liq
     set data_cancellazione=now(),
         login_operazione=liq.login_operazione||'-'||loginOperazione
     from fase_bil_t_gest_apertura_liq fase,
          siac_r_liquidazione_stato rs, siac_d_liquidazione_stato stato
     where fase.fase_bil_elab_id=faseBilElabId
     and liq.liq_id=fase.liq_orig_id
     and rs.liq_id=liq.liq_id
     and stato.liq_stato_id=rs.liq_stato_id
     and stato.liq_stato_code='P'
     and rs.data_cancellazione is null
     and rs.validita_fine is null
     and fase.fl_elab = 'S'
     and fase.liq_id is not null;

     strMessaggio:='Aggiornamento stato fase bilancio IN-3.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-3',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_LIQ_RES||' IN CORSO IN-3.Elabora Liq.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION  siac.fnc_fasi_bil_gest_apertura_liq_elabora_liq 
(
  integer,
  integer,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  OUT varchar
 ) owner to siac;

drop function if exists 
siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp (
  enteproprietarioid integer,
  annobilancio integer,
  tipoelab varchar,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp(enteproprietarioid integer, annobilancio integer, tipoelab character varying, fasebilelabid integer, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;
    aggProgressivi    record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-UG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';

	-- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    -- 15.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';


	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

    if tipoElab=APE_GEST_LIQ_RES then
 	 strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui per ribaltamento liquidazioni res da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    else
     strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    end if;

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq_imp].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_imp_id) into maxId
        from fase_bil_t_gest_apertura_liq_imp fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

    -- 08.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_liq_imp per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_liq_imp fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where Fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;
    -- 08.11.2019 Sofia SIAC-7145 - fine


     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||IMP_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     -- 15.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 15.02.2017 Sofia HD-INC000001535447

     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

	 -- 15.02.2017 Sofia SIAC-4425
     strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
   	 select attr.attr_id into strict flagFrazAttrId
     from siac_t_attr attr
     where attr.ente_proprietario_id=enteProprietarioId
     and   attr.attr_code=FRAZIONABILE_ATTR
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;


     -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inizio ciclo per generazione impegni.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_liq_imp_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
              fase.elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              fase.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_liq_imp fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
/*      and   exists -- x test siac-6255
      (
      select 1
      from siac_r_movgest_ts_programma r
      where r.movgest_ts_id=fase.movgest_orig_ts_id
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      ) */
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Impegno [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione
		   )
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
               movGestRec.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo impegno.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subimpegno movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';
			strMessaggioTemp:=strMessaggio;
        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subimpegno movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id ,
  		  siope_assenza_motivazione_id
        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di impegno padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
		  ts.siope_tipo_debito_id ,
  		  ts.siope_assenza_motivazione_id
          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

       /* select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

       -- raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        -- 15.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	if faseOp=G_FASE then
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
--            and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN'			-- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );

		   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );

           strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
		         siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );
        end if;
       end if;


       /*if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_programma].';

        insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_programma movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

	   -- 16.03.2023 Sofia SIAC-TASK-#44
	   -- siac_r_mutuo_voce_movgest						   


       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_giustificativo_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/


       -- siac_r_cartacont_det_movgest_ts
       /* Non si ribalta in seguito ad indicazioni di Annalina
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_cartacont_det_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_fondo_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_fondo_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_richiesta_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_richiesta_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia correzione per esclusione quote pagate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=sub.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine                
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=det1.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=det1.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine                
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A');

        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
		and   det1.data_cancellazione is null
        and   det1.validita_fine is null;

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
      /*   spostato sotto dopo pulizia in caso di codResult null
           if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; */

       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
    	 	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
	                      ' movgest_orig_id='||movGestRec.movgest_orig_id||
                          ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                          ' elem_orig_id='||movGestRec.elem_orig_id||
                          ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_cartacont_det_movgest_ts].';
	        update siac_r_cartacont_det_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_cartacont_det_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;
       end if; */


	   -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null then
       	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_storico_imp_acc].';

        insert into siac_r_movgest_ts_storico_imp_acc
        ( movgest_ts_id,
          movgest_anno_acc,
          movgest_numero_acc,
          movgest_subnumero_acc,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_anno_acc,
           r.movgest_numero_acc,
           r.movgest_subnumero_acc,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_storico_imp_acc r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
        );


        select 1  into codResult
        from siac_r_movgest_ts_storico_imp_acc det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;

         -- siac_r_giustificativo_movgest
/*         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet; */
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

	     -- 17.06.2019 Sofia siac-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;




/*        strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';

      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento impegno/subimpegno residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
            --- 12.01.2017 Sofia - sistemazione update per escludere le quote pagate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
		   -- 04.05.2021 Sofia SIAC-8095
           and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
            -- 04.05.2021 Sofia SIAC-8095
			-- SIAC-8551 Sofia - inizio 
            and not exists 
            (
	          select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
	          where rp.subdoc_id=r.subdoc_id 
	          and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
	          and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
	          and   rp.validita_fine is null 
            )
     	    -- SIAC-8551 Sofia - fine                          
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub,siac_t_doc  doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
            -- 04.05.2021 Sofia SIAC-8095
            and  not exists (
                             select 1
                             from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                             where rord.subdoc_id=r.subdoc_id
                             and   ts.ord_ts_id=rord.ord_ts_id
                             and   ord.ord_id=ts.ord_id
                             and   ord.ord_anno>annoBilancio
                             and   rord.data_cancellazione is null
                             and   rord.validita_fine is null
                           )
            -- 04.05.2021 Sofia SIAC-8095
            -- SIAC-8551 Sofia - inizio 
	        and not exists 
            (
	          select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
	          where rp.subdoc_id=r.subdoc_id 
	          and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
	          and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
	          and   rp.validita_fine is null 
            )
     	    -- SIAC-8551 Sofia - fine               
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
	    	    --strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
        end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_liq_imp per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


	 -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni residui.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni residui.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atti amministrativi antecedenti.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=2017
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||tipoElab||' IN CORSO IN-2.Elabora Imp.'
    where fase_bil_elab_id=faseBilElabId;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp 
( integer, integer, varchar,integer, integer, integer, varchar, timestamp,
  out  integer,
  out varchar
) owner to siac;

drop FUNCTION if exists siac.fnc_aggiorna_progressivi(enteproprietarioid integer, elemento character varying, loginoperazione character varying, OUT codresult integer, OUT messaggiorisultato character varying);
CREATE OR REPLACE FUNCTION siac.fnc_aggiorna_progressivi(enteproprietarioid integer, elemento character varying, loginoperazione character varying, OUT codresult integer, OUT messaggiorisultato character varying)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	cursorSql varchar(1500) := null;
   	_curs refcursor;
    rec   record;

    v_count integer := 0;

    MOVGEST_IMPEGNI       CONSTANT varchar:='I';
    MOVGEST_ACCERTAMENTI  CONSTANT varchar:='A';
    SOGGETTI              CONSTANT varchar:='S';
    SIAC_D_AMBITO_CODE    CONSTANT varchar:='AMBITO_FIN';
    LIQUIDAZIONE 		  CONSTANT varchar:='L';

    SOGGETTI_KEY          CONSTANT varchar:='sog';
    LIQUIDAZIONE_KEY	  CONSTANT varchar:='liq_';
    siac_d_ambito_id integer := 0;

begin

	strMessaggioFinale := 'Aggiornamento progressivi per tipo movimento '||elemento||'.';
    codResult := 0;


    strMessaggio:=' Costruzione cursorSql.';
	IF elemento = MOVGEST_IMPEGNI OR elemento = MOVGEST_ACCERTAMENTI THEN
		cursorSql := 'select case when imp.movgest_tipo_code = '''||MOVGEST_IMPEGNI||''' then ''imp_''||imp.movgest_anno
        	when imp.movgest_tipo_code = '''||MOVGEST_ACCERTAMENTI||''' then ''acc_''||imp.movgest_anno
            end prog_key
            , imp.num prog_value
          from
            (select distinct t.movgest_tipo_code, m.movgest_anno, coalesce(max(m.movgest_numero),0) num  from siac_t_movgest m
            inner join siac_d_movgest_tipo t on (
                t.movgest_tipo_id = m.movgest_tipo_id and
                t.ente_proprietario_id=m.ente_proprietario_id and
                t.movgest_tipo_code='''||elemento||''' and
                t.data_cancellazione is null)
            where m.ente_proprietario_id='||enteProprietarioId||' group by t.movgest_tipo_code,m.movgest_anno)imp;';
	elsif elemento=SOGGETTI then
	    cursorSql := 'select '''||SOGGETTI_KEY||'''::varchar prog_key , sogg.num prog_value from
             (select soggetto_code::integer num  from siac_t_soggetto s
              where s.ente_proprietario_id='||enteProprietarioId||'
              and fnc_migr_isnumeric(soggetto_code)
			  order by  fnc_migr_sortnum(soggetto_code) desc limit 1)sogg;';
    elsif elemento=LIQUIDAZIONE then
	    cursorSql := 'select '''||LIQUIDAZIONE_KEY||'''||liq_anno prog_key , max(liq_numero) prog_value from
        			  siac_t_liquidazione where ente_proprietario_id='||enteProprietarioId||'group by liq_anno;';
    else
         RAISE EXCEPTION ' % ', 'elemento '||elemento||' non gestito.';
    end if;


 if cursorSql is not null then

    strMessaggio:='Lettura ambito_id';
    select ambito_id into strict siac_d_ambito_id
    from siac_d_ambito where ente_proprietario_id = enteProprietarioId
    and now() between validita_inizio and coalesce(validita_fine,now())
    and ambito_code = SIAC_D_AMBITO_CODE;

    strMessaggio:='Apertura cursorSql ';
    OPEN _curs FOR EXECUTE cursorSql;
    LOOP
        FETCH NEXT FROM _curs INTO rec;
        EXIT WHEN rec IS NULL;

        strMessaggio := 'Lettura progressivo Prog_key:'||rec.prog_key||'/prog_value:'||rec.prog_value;
        select coalesce (count(*),0) into v_count from siac_t_progressivo where ente_proprietario_id = enteProprietarioId
        and data_cancellazione is null and prog_key = rec.prog_key and ambito_id = siac_d_ambito_id;

        if v_count > 0 THEN
        	strMessaggio:='Aggiornamento progressivo';
            update siac_t_progressivo
            set prog_value = rec.prog_value
            , data_modifica = now()
            , login_operazione = loginOperazione
            where ente_proprietario_id = enteProprietarioId
            and data_cancellazione is null
            and prog_key = rec.prog_key
            and ambito_id = siac_d_ambito_id;
        --        	strMessaggio := strMessaggio|| 'Aggiornato.';
        else
        	strMessaggio:='Inserimento progressivo';
            insert into siac_t_progressivo
                (prog_key, prog_value, ambito_id, validita_inizio, ente_proprietario_id, login_operazione)
            values
                (rec.prog_key,rec.prog_value,siac_d_ambito_id,now(),enteProprietarioId,loginOperazione);
        --			strMessaggio := strMessaggio||'Inserito.';
        end if;
    END LOOP;
    messaggioRisultato:=strMessaggioFinale||'Ok.';
   END IF;
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := -1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := -1;
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_aggiorna_progressivi( integer,  character varying,  character varying, OUT  integer, OUT  character varying) owner to siac;

-- 16.03.2023 Sofia SIAC-TASK-#44 -- fine  -- 07.02.2023 Sofia SIAC-8895 - fine  
    

 -- 13.02.2023 - inizio    	
 ALTER TABLE siac_d_accredito_tipo_oil ADD COLUMN fl_pagopa bool NOT NULL DEFAULT false; 
 -- 13.02.2023 - fine  
 
 -- vecchi mutui
 delete from siac_r_ruolo_op_azione where azione_id in (select azione_id from siac_t_azione where azione_code in ('OP-MUT-leggiMutuo', 'OP-MUT-gestisciMutuo'));

delete from siac_t_parametro_azione_richiesta where azione_richiesta_id in (select azione_richiesta_id from siac_t_azione_richiesta 
where azione_id in (select azione_id from siac_t_azione where azione_code in ('OP-MUT-leggiMutuo', 'OP-MUT-gestisciMutuo')));

delete from siac_t_azione_richiesta where azione_id in (select azione_id from siac_t_azione where azione_code in ('OP-MUT-leggiMutuo', 'OP-MUT-gestisciMutuo'));
 
delete from siac_t_azione where azione_code in ('OP-MUT-leggiMutuo', 'OP-MUT-gestisciMutuo');




DO $$
  declare
	rec pg_tables%ROWTYPE;
  BEGIN
	for rec in SELECT * FROM pg_tables where schemaname='siac' and tablename like '%_mutu%' and tablename not like 'old_%'
	LOOP
		execute 'ALTER TABLE IF EXISTS '|| rec.tablename || ' RENAME TO old_' || rec.tablename;
	END LOOP;
end $$;



DO $$
  declare
	rec information_schema.table_constraints%ROWTYPE;
  BEGIN
	for rec in SELECT * FROM information_schema.table_constraints WHERE constraint_schema = 'siac' and constraint_name like '%_mutu%' and constraint_type ='FOREIGN KEY'
	LOOP
		execute 'ALTER TABLE '|| rec.table_name ||' DROP CONSTRAINT IF EXISTS '|| rec.constraint_name;
	END LOOP;
end $$;


DO $$
  declare
	rec information_schema.table_constraints%ROWTYPE;
  BEGIN
	for rec in SELECT * FROM information_schema.table_constraints WHERE constraint_schema = 'siac' and constraint_name like '%_mutu%' and constraint_name not like 'old_%' and constraint_type ='PRIMARY KEY'
	LOOP
		execute 'ALTER TABLE '|| rec.table_name ||' RENAME CONSTRAINT '|| rec.constraint_name ||' TO old_' || rec.constraint_name;
		
	END LOOP;
end $$;



DO $$
  declare
	rec pg_indexes%ROWTYPE;
  BEGIN
	for rec in SELECT * FROM pg_indexes WHERE schemaname = 'siac' and tablename like '%_mutu%' and tablename like 'old_%' and upper(indexdef) not like '%UNIQUE%'
	LOOP
		execute 'DROP INDEX IF EXISTS '|| rec.indexname;
	END LOOP;
end $$;



DO $$
  declare
	rec pg_class%ROWTYPE;
  BEGIN
	for rec in SELECT * FROM pg_class c WHERE c.relkind = 'S' and relname like '%_mutu%' and relname not like 'old_%'
	LOOP
		execute 'ALTER SEQUENCE IF EXISTS '||rec.relname||' RENAME TO old_'||rec.relname;
	END LOOP;
end $$;


--    


alter table siac_t_ente_proprietario add column if not exists in_uso boolean default false;

update siac_t_ente_proprietario set in_uso=true where
ente_proprietario_id in (2,3,4,5,10,16);


update siac_t_ente_proprietario set ente_code='CMTO'
where ente_proprietario_id=3;


insert into siac_r_accredito_tipo_oil 
(
	accredito_tipo_id,
	accredito_tipo_oil_id,
	validita_inizio, 
	ente_proprietario_id, 
	login_operazione 
)
select dat.accredito_tipo_id, dato.	accredito_tipo_oil_id, current_timestamp, tep.ente_proprietario_id, 'admin' 
from siac_t_ente_proprietario tep, siac_d_accredito_tipo dat,
siac_d_accredito_tipo_oil dato 
where dat.ente_proprietario_id = tep.ente_proprietario_id 
and dat.accredito_tipo_code = 'APA'
and dato.ente_proprietario_id = tep.ente_proprietario_id 
and accredito_tipo_oil_desc = 'AVVISO PAGOPA'
and not exists (
	select 1 from siac_r_accredito_tipo_oil rato, siac_d_accredito_tipo dat,
	siac_d_accredito_tipo_oil dato  
	where rato.ente_proprietario_id = tep.ente_proprietario_id 
	and dat.ente_proprietario_id = tep.ente_proprietario_id 
	and dat.accredito_tipo_code = 'APA'
	and dato.ente_proprietario_id = tep.ente_proprietario_id 
	and accredito_tipo_oil_desc = 'AVVISO PAGOPA'
);



insert into siac_r_accredito_tipo_oil 
(
	accredito_tipo_id,
	accredito_tipo_oil_id,
	validita_inizio, 
	ente_proprietario_id, 
	login_operazione 
)
select dat.accredito_tipo_id, dato.	accredito_tipo_oil_id, current_timestamp, tep.ente_proprietario_id, 'admin' 
from siac_t_ente_proprietario tep, siac_d_accredito_tipo dat,
siac_d_accredito_tipo_oil dato 
where dat.ente_proprietario_id = tep.ente_proprietario_id 
and tep.ente_code='CMTO'
and dat.accredito_tipo_code = 'PPAY'
and dato.ente_proprietario_id = tep.ente_proprietario_id 
and accredito_tipo_oil_desc = 'AVVISO PAGOPA'
and not exists (
	select 1 from siac_r_accredito_tipo_oil rato, siac_d_accredito_tipo dat,
	siac_d_accredito_tipo_oil dato  
	where rato.ente_proprietario_id = tep.ente_proprietario_id 
	and dat.ente_proprietario_id = tep.ente_proprietario_id 
	and dat.accredito_tipo_code = 'PPAY'
	and dato.ente_proprietario_id = tep.ente_proprietario_id 
	and accredito_tipo_oil_desc = 'AVVISO PAGOPA'
);





	

