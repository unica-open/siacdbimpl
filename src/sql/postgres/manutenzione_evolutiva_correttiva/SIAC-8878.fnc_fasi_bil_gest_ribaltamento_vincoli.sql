/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


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