/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- SIAC-7897

select fnc_siac_bko_inserisci_azione('OP-BKOF019-aggiornaProvvedimentoSistemaEsterno', 'Provvedimenti - Backoffice aggiorna provvedimento sistema esterno', 
	'/../siacbilapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');

-- fine SIAC-7897


-- SIAC-7902 -- Sofia 05.03.2021 - inizio 
drop function if exists
fnc_fasi_bil_prev_ribaltamento_vincoli
(
  p_annobilancio integer,
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  out faseBilElabIdRet integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);
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

CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_ribaltamento_vincoli (
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
    strmessaggio       			VARCHAR(1500):='';
    strmessaggiofinale 			VARCHAR(1500):='';
    bilelemidret           		INTEGER  :=NULL;
    codresult              		INTEGER  :=NULL;
    datainizioval 				timestamp:=NULL;
    fasebilelabid    			INTEGER  :=NULL;
    categoriacapcode 			VARCHAR  :=NULL;
    bilelemstatoanid 			INTEGER  :=NULL;
    --v_dataprimogiornoanno 		timestamp:=NULL;
    ape_prev_da_gest            CONSTANT VARCHAR:='APE_PREV';
    rec_vincoli_gest  			RECORD;
    rec_capitoli_gest 			RECORD;
    _row_count 					INTEGER;
    v_periodo_id_gest           INTEGER;
    v_periodo_id_prev           INTEGER;
    v_bilancio_id_gest           INTEGER;
    v_bilancio_id_prev           INTEGER;

    v_vincolo_id                INTEGER;
    v_vincolo_tipo_id_prev      INTEGER;
    v_elem_id                   INTEGER;
    v_elem_tipo_code_prev       VARCHAR;
    v_elem_tipo_id_prev         INTEGER;
  BEGIN
    messaggiorisultato:='';
    codicerisultato:=0;
    fasebilelabidret:=0;
    datainizioval:= clock_timestamp();
    --v_dataprimogiornoanno:= (p_annobilancio||'-01-01')::timestamp;
    strmessaggiofinale:='Ribaltamento Vincoli da gestione precedente.';





    strmessaggio:='estraggo il periodo del bilancio di previsione periodo_code = anno'||p_annobilancio||'.';
    begin
      select per.periodo_id,bil.bil_id  into strict v_periodo_id_prev ,v_bilancio_id_prev
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

    strmessaggio:='estraggo il periodo del bilancio di gestione anno prec periodo_code = anno'||p_annobilancio-1||'.';
    begin
      select per.periodo_id,bil.bil_id  into strict v_periodo_id_gest ,v_bilancio_id_gest
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


    strmessaggio:='vincolo_tipo_id dei vincoli nuovi di previsione .';
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

/*    execute 'CREATE TABLE IF NOT EXISTS siac_t_vincolo_tmp(id INTEGER);';

    --cancello l'eventuale ribaltamento fatto precedentemente
    delete from siac_r_vincolo_bil_elem using siac_t_vincolo_tmp 	where  siac_r_vincolo_bil_elem.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_genere using siac_t_vincolo_tmp 		where  siac_r_vincolo_genere.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_attr using siac_t_vincolo_tmp 		where  siac_r_vincolo_attr.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_r_vincolo_stato using siac_t_vincolo_tmp 		where  siac_r_vincolo_stato.vincolo_id = siac_t_vincolo_tmp.id ;
    delete from siac_t_vincolo using siac_t_vincolo_tmp 			where  siac_t_vincolo.vincolo_id = siac_t_vincolo_tmp.id ;

    -- pulisco la tabella di bck
    execute 'delete from siac_t_vincolo_tmp;';*/

    -- pulizia dati presenti
    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_bil_elem.';
    update siac_r_vincolo_bil_elem r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_attr.';
    update siac_r_vincolo_attr r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_genere.';
    update siac_r_vincolo_genere r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - inizio

    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_risorse_vincolate.';
    update siac_r_vincolo_risorse_vincolate r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

	-- 05.03.2021 Sofia Jira SIAC-790 - fine

    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_r_vincolo_stato.';
    update siac_r_vincolo_stato r
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=r.login_operazione||'-'||p_loginoperazione
    from siac_t_vincolo v,siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   r.vincolo_id=v.vincolo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;



    strMessaggio:='Pulizia vincoli di previsione. Cancellazione logica siac_t_vincolo.';
    update siac_t_vincolo v
    set    data_cancellazione=now(),
           validita_fine=now(),
           login_operazione=v.login_operazione||'-'||p_loginoperazione
    from siac_d_vincolo_tipo tipo
    where tipo.ente_proprietario_id=p_enteproprietarioid
    and   tipo.vincolo_tipo_code='P'
    and   v.vincolo_tipo_id=tipo.vincolo_tipo_id
    and   v.periodo_id=v_periodo_id_prev
    and   v.data_cancellazione is null
    and   v.validita_fine is null;

    strmessaggio:='inizio ciclo sui vincoli di gestione anno precedente';
    FOR rec_vincoli_gest IN(
       select
           siac_t_vincolo.vincolo_id
          ,siac_t_vincolo.vincolo_code
          ,siac_t_vincolo.vincolo_desc
          ,siac_t_vincolo.vincolo_tipo_id
          ,siac_t_vincolo.periodo_id
--          ,siac_d_vincolo_genere.vincolo_gen_id 07.12.2017 Sofia JIRA SIAC-5630
      from
           siac_t_vincolo
          ,siac_d_vincolo_tipo
          ,siac_r_vincolo_stato
          ,siac_d_vincolo_stato
--          ,siac_r_vincolo_genere 07.12.2017 Sofia JIRA SIAC-5630
--          ,siac_d_vincolo_genere 07.12.2017 Sofia JIRA SIAC-5630
      where
            siac_t_vincolo.ente_proprietario_id=p_enteproprietarioid
      and   siac_d_vincolo_tipo.vincolo_tipo_id=siac_t_vincolo.vincolo_tipo_id
      and   siac_t_vincolo.vincolo_id = siac_r_vincolo_stato.vincolo_id
      and   siac_r_vincolo_stato.vincolo_stato_id = siac_d_vincolo_stato.vincolo_stato_id
--     and   siac_t_vincolo.vincolo_id =  siac_r_vincolo_genere.vincolo_id 07.12.2017 Sofia
--     and   siac_r_vincolo_genere.vincolo_gen_id = siac_d_vincolo_genere.vincolo_gen_id 07.12.2017 Sofia
      and   siac_d_vincolo_stato.vincolo_stato_code!='A'
      and   siac_d_vincolo_tipo.vincolo_tipo_code='G'
      and   siac_t_vincolo.periodo_id = v_periodo_id_gest
      and 	siac_r_vincolo_stato.data_cancellazione is null
      and 	siac_r_vincolo_stato.validita_fine is null
      and   siac_t_vincolo.data_cancellazione is null
      and   siac_t_vincolo.validita_fine is null
--      and   siac_r_vincolo_genere.data_cancellazione is null JIRA SIAC-5630

    )LOOP

    	strmessaggio:='inserimento nuovo vincolo su siac_t_vincolo v_vincolo_tipo_id_prev '||v_vincolo_tipo_id_prev||' v_periodo_id_prev '||v_periodo_id_prev||'.';

		insert into siac_t_vincolo (vincolo_code ,vincolo_desc ,vincolo_tipo_id ,periodo_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_creazione ,data_modifica ,data_cancellazione ,login_operazione
        )VALUES(
           rec_vincoli_gest.vincolo_code
          ,rec_vincoli_gest.vincolo_desc
          ,v_vincolo_tipo_id_prev
          ,v_periodo_id_prev
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
        (vincolo_id,
         vincolo_gen_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione
        )
        (
        select
           v_vincolo_id
          ,r.vincolo_gen_id
          ,now()
          ,p_enteproprietarioid
          ,now()
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


        strmessaggio:='inserimento capitoli siac_r_vincolo_bil_elem capitoli di gestione vecchi.';
        FOR rec_capitoli_gest IN(
          select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
          from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
          where
              siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
          and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
          and siac_t_bil_elem.bil_id          =  v_bilancio_id_gest
          and siac_r_vincolo_bil_elem.data_cancellazione is null
          and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_gest.vincolo_id
          and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid
          and siac_r_vincolo_bil_elem.data_cancellazione is null
          and siac_r_vincolo_bil_elem.validita_fine is null

        )LOOP

        	strmessaggio:='deduco il codice del capitolo di previsione nuovo.';

			if rec_capitoli_gest.elem_tipo_code = 'CAP-UG' THEN
            	v_elem_tipo_code_prev := 'CAP-UP';
            elseif rec_capitoli_gest.elem_tipo_code = 'CAP-EG' THEN
                v_elem_tipo_code_prev := 'CAP-EP';
        	else
				--messaggiorisultato:=' Errore tipo capitolo '||rec_capitoli_gest.elem_tipo_code||'.';
            	--RAISE EXCEPTION ' Errore tipo capitolo % diverso da CAP-UG e CAP-EG .',rec_capitoli_gest.elem_tipo_code;
                --RETURN;
                continue;
            end if;

        	strmessaggio:='estraggo il tipo nuovo di prev.';
			raise notice 'tipo=% elem_code=% elem_id=%' ,rec_capitoli_gest.elem_tipo_code,rec_capitoli_gest.elem_code,rec_capitoli_gest.elem_id;
            select elem_tipo_id into strict v_elem_tipo_id_prev
            from siac_d_bil_elem_tipo
            where
            ente_proprietario_id = p_enteproprietarioid
            and elem_tipo_code = v_elem_tipo_code_prev ;

    		strmessaggio:='estraggo elem_id v_elem_tipo_id_prev '|| v_elem_tipo_id_prev::varchar||' rec_capitoli_gest.elem_code '||rec_capitoli_gest.elem_code||' rec_capitoli_gest.elem_code2 '||rec_capitoli_gest.elem_code2||' rec_capitoli_gest.elem_code3 '||rec_capitoli_gest.elem_code3||'.';



 --           select siac_t_bil_elem.elem_id into strict v_elem_id
 			v_elem_id:=null;
            select siac_t_bil_elem.elem_id into v_elem_id
            FROM   siac_t_bil_elem,siac_t_bil
            where
                siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
            and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
            and siac_t_bil_elem.elem_code      = rec_capitoli_gest.elem_code
            and siac_t_bil_elem.elem_code2     = rec_capitoli_gest.elem_code2
            and siac_t_bil_elem.elem_code3     = rec_capitoli_gest.elem_code3
            and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id_prev
        	and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;

            if 	v_elem_id is not null then
             strmessaggio:='inizio inserimenti per i capitoli .';
  			 raise notice 'tipo=% elem_code=% elem_id=%' ,v_elem_tipo_code_prev,rec_capitoli_gest.elem_code,v_elem_id;

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
                  select siac_t_bil_elem.elem_id,siac_t_bil_elem.elem_code,siac_t_bil_elem.elem_code2,siac_t_bil_elem.elem_code3 ,siac_d_bil_elem_tipo.elem_tipo_code
                  from siac_r_vincolo_bil_elem , siac_t_bil_elem ,siac_d_bil_elem_tipo
                  where
                      siac_r_vincolo_bil_elem.elem_id =  siac_t_bil_elem.elem_id
                  and siac_t_bil_elem.elem_tipo_id    =  siac_d_bil_elem_tipo.elem_tipo_id
                  and siac_t_bil_elem.bil_id          =  v_bilancio_id_prec
                  and siac_r_vincolo_bil_elem.data_cancellazione is null
                  and siac_r_vincolo_bil_elem.validita_fine is null
                  and siac_r_vincolo_bil_elem.vincolo_id = rec_vincoli_gest.vincolo_id
                  and siac_r_vincolo_bil_elem.ente_proprietario_id = p_enteproprietarioid


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
                    select siac_t_bil_elem.elem_id into v_elem_id
                    FROM   siac_t_bil_elem,siac_t_bil
                    where
                        siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                    and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                    and siac_t_bil_elem.elem_code      = rec_capitoli_gest.elem_code
                    and siac_t_bil_elem.elem_code2     = rec_capitoli_gest.elem_code2
                    and siac_t_bil_elem.elem_code3     = rec_capitoli_gest.elem_code3
                    and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                    and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;

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
                      select siac_t_bil_elem.elem_id into v_elem_id
                      FROM   siac_t_bil_elem,siac_t_bil
                      where
                          siac_t_bil_elem.bil_id         = siac_t_bil.bil_id
                      and siac_t_bil.bil_code            = 'BIL_'||p_annobilancio
                      and siac_t_bil_elem.elem_code      = rec_capitoli_prev.elem_code
                      and siac_t_bil_elem.elem_code2     = rec_capitoli_prev.elem_code2
                      and siac_t_bil_elem.elem_code3     = rec_capitoli_prev.elem_code3
                      and siac_t_bil_elem.elem_tipo_id   = v_elem_tipo_id
                      and siac_t_bil_elem.ente_proprietario_id = p_enteproprietarioid;


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
  
 alter function siac.fnc_fasi_bil_prev_ribaltamento_vincoli(integer,integer, varchar, timestamp,  out integer, out  integer,  out varchar ) owner to siac;
 alter function siac.fnc_fasi_bil_gest_ribaltamento_vincoli (  varchar,  integer,  integer,  varchar,  timestamp,  out integer,  out integer,  out varchar) owner to siac;
 
 -- SIAC-7902 -- Sofia 05.03.2021 - fine 


-- SIAC-7874 - Maurizio - INIZIO

CREATE TABLE if not exists siac.siac_rep_ce_sp_gsa (
  classif_id INTEGER,
  cod_voce VARCHAR,
  descrizione_voce VARCHAR,
  livello_codifica INTEGER,
  padre VARCHAR,
  foglia VARCHAR,
  classif_tipo_code VARCHAR(200),
  pdce_conto_code VARCHAR,
  pdce_conto_descr VARCHAR,
  pdce_conto_numerico VARCHAR,
  pdce_fam_code VARCHAR,
  imp_dare NUMERIC,
  imp_avere NUMERIC,
  imp_saldo NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);



create table if not exists siac.siac_t_config_rep_ce_sp_gsa (
voce_id SERIAL,
tipo_report VARCHAR(2) NOT NULL,
cod_voce  VARCHAR(200) NOT NULL,
segno INTEGER NOT NULL,
titolo varchar(1) NOT NULL,
bil_id INTEGER NOT NULL,
validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
validita_fine TIMESTAMP WITHOUT TIME ZONE,
ente_proprietario_id INTEGER NOT NULL,
data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione VARCHAR(200) NOT NULL,
CONSTRAINT pk_siac_t_config_rep_ce_sp_gsa PRIMARY KEY(voce_id),
CONSTRAINT siac_t_ente_proprietario_siac_t_config_rep_ce_sp_gsa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE)
WITH (oids = false);

DROP FUNCTION if exists siac."BILR248_conto_economico_allegato_A_gsa"(p_ente_prop_id integer, p_anno varchar, p_cod_bilancio varchar, p_data_pnota_da date, p_data_pnota_a date);
DROP FUNCTION if exists siac."BILR250_stato_patrimoniale_allegato_D_gsa"(p_ente_prop_id integer, p_anno varchar, p_cod_bilancio varchar, p_data_pnota_da date, p_data_pnota_a date);

CREATE OR REPLACE FUNCTION siac."BILR248_conto_economico_allegato_A_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cod_bilancio varchar,
  p_data_pnota_da date,
  p_data_pnota_a date
)
RETURNS TABLE (
  classif_id integer,
  codice_voce varchar,
  descrizione_voce varchar,
  livello_codifica integer,
  padre varchar,
  foglia varchar,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  pdce_conto_numerico varchar,
  pdce_fam_code varchar,
  importo_dare numeric,
  importo_avere numeric,
  importo_saldo numeric,
  segno integer,
  titolo varchar,
  display_error varchar
) AS
$body$
DECLARE

classifGestione record;
pdce            record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_saldo		 	 NUMERIC :=0;
v_imp_dare_meno 	 NUMERIC :=0;
v_imp_avere_meno	 NUMERIC :=0;
v_imp_saldo_meno	 NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;
conta_livelli integer;
maxLivello integer;
id_bil integer;
conta integer;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

classif_id:=0;
codice_voce := '';
descrizione_voce := '';
livello_codifica := 0;
padre := '';
foglia := '';
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;
display_error:='';

RTN_MESSAGGIO:='Inserimento nella tabella di appoggio.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';
    
if (p_data_pnota_da IS NOT NULL and p_data_pnota_a IS NULL) OR
	(p_data_pnota_da IS NULL and p_data_pnota_a IS NOT NULL) then
    display_error:='Specificare entrambe le date della prima nota.';
    return next;
    return;
end if;
    
if p_data_pnota_da > p_data_pnota_a THEN
	display_error:='La data Da della prima nota non puo'' essere successiva alla data A.';
    return next;
    return;
end if;

v_anno_int:=p_anno::integer;    
conta:=0;
if p_cod_bilancio is not null and p_cod_bilancio <> '' then
	select count(*)
    	into conta
    from siac_t_class class,
        siac_d_class_tipo tipo_class
	where class.classif_tipo_id=tipo_class.classif_tipo_id
    	and class.ente_proprietario_id=p_ente_prop_id
        and upper(right(class.classif_code,length(class.classif_code)-1))=
        	upper(p_cod_bilancio)
        and class.data_cancellazione IS NULL;       
    if conta = 0 then 
    	display_error:='Il codice bilancio '''||p_cod_bilancio|| ''' non esiste';
    	return next;
    	return;
    end if;
end if;

select a.bil_id
into id_bil
from siac_t_bil a,
	siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.data_cancellazione IS NULL
and a.ente_proprietario_id=p_ente_prop_id
and b.anno =p_anno;

--cerco le voci di conto economico e gli importi registrati sui conti
--solo per le voci "foglia".  
--I dati sono salvati sulla tabella di appoggio "siac_rep_ce_sp_gsa".
with voci as(select class.classif_id, 
 right(class.classif_code,length(class.classif_code)-1) classif_code,
class.classif_desc, r_class_fam.livello,
 	COALESCE(padre.classif_code,'') padre, 
 	case when figlio.classif_id_padre is null then 'S' else 'N' end foglia,
    case when figlio.classif_id_padre is null then class.classif_id 
    	else 0 end classif_id_foglia
    from siac_t_class class,
        siac_d_class_tipo tipo_class,
        siac_r_class_fam_tree r_class_fam
            left join (select r_fam1.classif_id, 
            	right(class1.classif_code,length(class1.classif_code)-1) classif_code
                        from siac_r_class_fam_tree r_fam1,
                            siac_t_class class1
                        where  r_fam1.classif_id=class1.classif_id
                            and r_fam1.ente_proprietario_id=p_ente_prop_id
                            and r_fam1.data_cancellazione IS NULL) padre
              on padre.classif_id=r_class_fam.classif_id_padre
             left join (select distinct r_tree2.classif_id_padre
                        from siac_r_class_fam_tree r_tree2
                        where r_tree2.ente_proprietario_id=p_ente_prop_id
                            and r_tree2.data_cancellazione IS NULL) figlio
                on r_class_fam.classif_id=figlio.classif_id_padre,
        siac_t_class_fam_tree t_class_fam        
    where class.classif_tipo_id=tipo_class.classif_tipo_id
    and class.classif_id=r_class_fam.classif_id
    and r_class_fam.classif_fam_tree_id=t_class_fam.classif_fam_tree_id
    and class.ente_proprietario_id=p_ente_prop_id
    and tipo_class.classif_tipo_code='CE_CODBIL_GSA'
    and class.data_cancellazione IS NULL
    AND v_anno_int BETWEEN date_part('year',class.validita_inizio) AND
           date_part('year',COALESCE(class.validita_fine,now())) 
    and r_class_fam.data_cancellazione IS NULL
    and r_class_fam.validita_fine IS NULL
    AND v_anno_int BETWEEN date_part('year',r_class_fam.validita_inizio) AND
           date_part('year',COALESCE(r_class_fam.validita_fine,now())) ),
conti AS( SELECT fam.pdce_fam_code,fam.pdce_fam_segno, r.classif_id,
                   conto.pdce_conto_code, conto.pdce_conto_desc,
                   conto.pdce_conto_id
            from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
                 siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
            where conto.pdce_conto_id=r.pdce_conto_id
            and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
            and   fam.pdce_fam_id=famtree.pdce_fam_id
            and   ambito.ambito_id=conto.ambito_id
            and   r.ente_proprietario_id=p_ente_prop_id
            and   ambito.ambito_code='AMBITO_GSA'
            and   r.data_cancellazione is null
            and   conto.data_cancellazione is null
            and   v_anno_int BETWEEN date_part('year',r.validita_inizio)::integer and  coalesce (date_part('year',r.validita_fine)::integer ,v_anno_int)
            and   v_anno_int BETWEEN date_part('year',conto.validita_inizio) AND date_part('year',COALESCE(conto.validita_fine,now()))
           ),
           movimenti as
           (
            select det.pdce_conto_id,
                   sum( case  when det.movep_det_segno='Dare' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_dare,
                   sum( case  when det.movep_det_segno='Avere' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_avere
            from  siac_t_periodo per,   siac_t_bil bil,
                  siac_t_prima_nota pn, siac_r_prima_nota_stato rs, siac_d_prima_nota_stato stato,
                  siac_t_mov_ep ep, siac_t_mov_ep_det det,siac_d_ambito ambito
            where per.periodo_id=bil.periodo_id            
            and   pn.bil_id=bil.bil_id
            and   rs.pnota_id=pn.pnota_id
            and   stato.pnota_stato_id=rs.pnota_stato_id
            and   ep.regep_id=pn.pnota_id
            and   det.movep_id=ep.movep_id           
            and   ambito.ambito_id=pn.ambito_id 
            and   bil.ente_proprietario_id=p_ente_prop_id
            and   per.anno::integer=v_anno_int
            and   stato.pnota_stato_code='D'            
            and   ambito.ambito_code='AMBITO_GSA'    
            and   ((p_data_pnota_da is NOT NULL and 
    				trunc(pn.pnota_dataregistrazionegiornale) between 
    					  p_data_pnota_da and p_data_pnota_a) OR
            p_data_pnota_da IS NULL)                  
            and   pn.data_cancellazione is null
            and   pn.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   ep.data_cancellazione is null
            and   ep.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            group by det.pdce_conto_id)      
insert into siac_rep_ce_sp_gsa                  
select voci.classif_id::integer, 
		voci.classif_code::varchar,
        voci.classif_desc::varchar,
        voci.livello::integer,
        voci.padre::varchar,
        voci.foglia::varchar,
        'CE_CODBIL_GSA'::varchar,
        COALESCE(conti.pdce_conto_code,'')::varchar,
        COALESCE(conti.pdce_conto_desc,'')::varchar,
        COALESCE(replace(conti.pdce_conto_code,'.',''),'')::varchar,
        COALESCE(conti.pdce_fam_code,'')::varchar,
        COALESCE(movimenti.importo_dare,0)::numeric,
        COALESCE(movimenti.importo_avere,0)::numeric,
        --PP OP RE = Avere
        	--'PP','OP','OA','RE' = Ricavi
        case when UPPER(conti.pdce_fam_segno) ='AVERE' then 
        	COALESCE(movimenti.importo_avere,0) - COALESCE(movimenti.importo_dare,0)
        	--AP OA CE = Dare
            --'AP','CE' = Costi 
        else COALESCE(movimenti.importo_dare,0) - COALESCE(movimenti.importo_avere,0)
        end ::numeric,
        p_ente_prop_id::integer,
        user_table::varchar
from voci 
	left join conti 
    	on voci.classif_id_foglia = conti.classif_id              
	left join movimenti
    	on conti.pdce_conto_id=movimenti.pdce_conto_id
order by voci.classif_code;

  
--inserisco il record per il totale finale
insert into siac_rep_ce_sp_gsa
values (0,'ZZ9999','RISULTATO DI ESERCIZIO',1,'CE_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
    
RTN_MESSAGGIO:='Lettura livello massimo.';
--leggo qual e' il massimo livello per le voci di conto NON "foglia".
maxLivello:=0;
SELECT max(a.livello_codifica) 
	into maxLivello
from siac_rep_ce_sp_gsa a
where a.foglia='N'
	and a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id;
    
raise notice 'maxLivello = %', maxLivello;

RTN_MESSAGGIO:='Ciclo sui livelli';
--ciclo sui livelli partendo dal massimo in quanto devo ricostruire
--al contrario gli importi per i conti che non sono "foglia".
for conta_livelli in reverse maxLivello..1
loop     
	RTN_MESSAGGIO:='Ciclo sui conti non foglia.';
	raise notice 'conta_livelli = %', conta_livelli;
    	--ciclo su tutti i conti non "foglia" del livello che sto gestendo.
    for classifGestione IN
    	select a.cod_voce, a.classif_id
        from siac_rep_ce_sp_gsa a
        where a.foglia='N'
          and a.livello_codifica=conta_livelli
          and a.utente = user_table
          and a.ente_proprietario_id = p_ente_prop_id
     	order by a.cod_voce
     loop
        v_imp_dare:=0;
        v_imp_avere:=0;
        RTN_MESSAGGIO:='Calcolo importi.';
        
        	--calcolo gli importi come somma dei suoi figli.
        select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
        	into v_imp_dare, v_imp_avere, v_imp_saldo
        from siac_rep_ce_sp_gsa a
        where a.padre=classifGestione.cod_voce
         	and a.utente = user_table
          	and a.ente_proprietario_id = p_ente_prop_id;
        
        raise notice 'codice_voce = % - importo_dare= %, importo_avere = %', 
        	classifGestione.cod_voce, v_imp_dare,v_imp_avere;
        RTN_MESSAGGIO:='Update importi.';
        
            --aggiorno gli importi 
        update siac_rep_ce_sp_gsa a
        	set imp_dare=v_imp_dare,
            	imp_avere=v_imp_avere,
                imp_saldo=v_imp_saldo
        where cod_voce=classifGestione.cod_voce
        	and utente = user_table
          	and ente_proprietario_id = p_ente_prop_id;
            
     end loop; --loop voci NON "foglie" del livello gestito.     
end loop; --loop livelli

--devo aggiornare alcuni importi totali secondo le seguenti formule.

--AZ9999= AA0010+AA0240+AA0270+AA0320+AA0750+AA0940+AA0980+AA1050+AA1060
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AA0010','AA0240','AA0270','AA0320','AA0750','AA0940','AA0980',
	'AA1050','AA1060')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'AZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
                   
--BZ9999= BA0010+BA0390+BA1910+BA1990+BA2080+BA2500+BA2560+BA2630+BA2660+BA2690
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('BA0010','BA0390','BA1910','BA1990','BA2080','BA2500','BA2560',
	'BA2630','BA2660','BA2690')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'BZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
    
--CZ9999= CA0010+CA0050-CA0110-CA0150    
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0010','CA0050')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0110','CA0150')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'CZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    
--DZ9999= DA0010-DA0020
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('DA0010')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('DA00200')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'DZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;      
      
--EZ9999= EA0010-EA0260
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0010')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0260')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'EZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;      
    
--XA0000= AZ9999-BZ9999+CZ9999+DZ9999+EZ9999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AZ9999','CZ9999','DZ9999','EZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('BZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'XA0000'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    
--YZ9999= YA0010+YA0060+YA0090
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('YA0010','YA0060','YA0090')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'YZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id; 
        
--ZZ9999= XA0000-YZ9999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('XA0000')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('YZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'ZZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
        
--restituisco i dati presenti sulla tabella di appoggio.
return query
select tutto.*, 
	COALESCE(config.segno,1)::integer segno, 
    COALESCE(config.titolo,'') titolo,
    ''::varchar
from (select a.classif_id::integer, 
  a.cod_voce::varchar cod_voce,
  a.descrizione_voce::varchar,
  a.livello_codifica::integer,
  a.padre::varchar,
  a.foglia::varchar,
  COALESCE(a.pdce_conto_code,'')::varchar,
  COALESCE(a.pdce_conto_descr,'')::varchar,
  COALESCE(a.pdce_conto_numerico,'')::varchar,
  COALESCE(a.pdce_fam_code,'')::varchar,
  COALESCE(a.imp_dare,0)::numeric,
  COALESCE(a.imp_avere,0)::numeric,
  COALESCE(a.imp_saldo,0)::numeric--,
  --case when a.pdce_fam_code in ('PP','OP','OA','RE') then 1
  --	else -1 end::integer,
--  ''::varchar
from siac_rep_ce_sp_gsa a
where a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (upper(a.cod_voce) = upper(p_cod_bilancio) OR 
          	upper(a.padre) = upper(p_cod_bilancio))))    
UNION
select b.classif_id::integer, 
  b.cod_voce::varchar cod_voce,
  b.descrizione_voce::varchar,
  b.livello_codifica::integer,
  b.padre::varchar,
  b.foglia::varchar,
  ''::varchar,
  ''::varchar,
  ''::varchar,
  ''::varchar,
  COALESCE(sum(b.imp_dare),0)::numeric,
  COALESCE(sum(b.imp_avere),0)::numeric,
  COALESCE(sum(b.imp_saldo),0)::numeric--,
 -- 0::integer,
 -- ''::varchar
from siac_rep_ce_sp_gsa b
where b.utente = user_table
	and b.ente_proprietario_id = p_ente_prop_id
    and b.foglia='S'
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (b.cod_voce = p_cod_bilancio OR b.padre = p_cod_bilancio)))
    and b.classif_id not in (select c.classif_id
    		from siac_rep_ce_sp_gsa c
            where c.utente = user_table
				and c.ente_proprietario_id = p_ente_prop_id
                and c.pdce_conto_code ='')
group by b.classif_id, b.cod_voce, b.descrizione_voce, b.livello_codifica,
  b.padre, b.foglia) tutto 
  left join (select conf.cod_voce, conf.titolo, conf.segno
  			 from siac_t_config_rep_ce_sp_gsa conf
             where conf.bil_id=id_bil
             and conf.tipo_report='CE'
             and conf.data_cancellazione IS NULL) config
  	on tutto.cod_voce=config.cod_voce   
order by 2,6;
    
delete from siac_rep_ce_sp_gsa where utente = user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'Nessun dato trovato per rendiconto gestione GSA';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR250_stato_patrimoniale_allegato_D_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cod_bilancio varchar,
  p_data_pnota_da date,
  p_data_pnota_a date
)
RETURNS TABLE (
  classif_id integer,
  codice_voce varchar,
  descrizione_voce varchar,
  livello_codifica integer,
  padre varchar,
  foglia varchar,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  pdce_conto_numerico varchar,
  pdce_fam_code varchar,
  importo_dare numeric,
  importo_avere numeric,
  importo_saldo numeric,
  segno integer,
  titolo varchar,
  tipo_stato varchar,
  ordinamento varchar,
  display_error varchar
) AS
$body$
DECLARE

classifGestione record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_saldo		 	 NUMERIC :=0;
v_imp_dare_meno 	 NUMERIC :=0;
v_imp_avere_meno	 NUMERIC :=0;
v_imp_saldo_meno	 NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;
conta_livelli integer;
maxLivello integer;
id_bil integer;
conta integer;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

classif_id:=0;
codice_voce := '';
descrizione_voce := '';
livello_codifica := 0;
padre := '';
foglia := '';
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;
display_error:='';

RTN_MESSAGGIO:='Inserimento nella tabella di appoggio.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';
    
if (p_data_pnota_da IS NOT NULL and p_data_pnota_a IS NULL) OR
	(p_data_pnota_da IS NULL and p_data_pnota_a IS NOT NULL) then
    display_error:='Specificare entrambe le date della prima nota.';
    return next;
    return;
end if;
    

if p_data_pnota_da > p_data_pnota_a THEN
	display_error:='La data Da della prima nota non puo'' essere successiva alla data A.';
    return next;
    return;
end if;
    
v_anno_int:=p_anno::integer; 
conta:=0;
if p_cod_bilancio is not null and p_cod_bilancio <> '' then
	select count(*)
    	into conta
    from siac_t_class class,
        siac_d_class_tipo tipo_class
	where class.classif_tipo_id=tipo_class.classif_tipo_id
    	and class.ente_proprietario_id=p_ente_prop_id
        and upper(right(class.classif_code,length(class.classif_code)-1))=
        	upper(p_cod_bilancio)
        and class.data_cancellazione IS NULL;       
    if conta = 0 then 
    	display_error:='Il codice bilancio '''||p_cod_bilancio|| ''' non esiste';
    	return next;
    	return;
    end if;
end if;

select a.bil_id
into id_bil
from siac_t_bil a,
	siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.data_cancellazione IS NULL
and a.ente_proprietario_id=p_ente_prop_id
and b.anno =p_anno;

--cerco le voci di stato patrimoniale attivo e passivo e gli importi registrati sui 
--conti solo per le voci "foglia".  
--I dati sono salvati sulla tabella di appoggio "siac_rep_ce_sp_gsa".
with voci as(select class.classif_id, 
class.classif_code,
class.classif_desc, r_class_fam.livello,
 	COALESCE(padre.classif_code,'') padre, 
 	case when figlio.classif_id_padre is null then 'S' else 'N' end foglia,
    case when figlio.classif_id_padre is null then class.classif_id 
    	else 0 end classif_id_foglia, tipo_class.classif_tipo_code
    from siac_t_class class,
        siac_d_class_tipo tipo_class,
        siac_r_class_fam_tree r_class_fam
            left join (select r_fam1.classif_id, class1.classif_code
                        from siac_r_class_fam_tree r_fam1,
                            siac_t_class class1
                        where  r_fam1.classif_id=class1.classif_id
                            and r_fam1.ente_proprietario_id=p_ente_prop_id
                            and r_fam1.data_cancellazione IS NULL) padre
              on padre.classif_id=r_class_fam.classif_id_padre
             left join (select distinct r_tree2.classif_id_padre
                        from siac_r_class_fam_tree r_tree2
                        where r_tree2.ente_proprietario_id=p_ente_prop_id
                            and r_tree2.data_cancellazione IS NULL) figlio
                on r_class_fam.classif_id=figlio.classif_id_padre,
        siac_t_class_fam_tree t_class_fam        
    where class.classif_tipo_id=tipo_class.classif_tipo_id
    and class.classif_id=r_class_fam.classif_id
    and r_class_fam.classif_fam_tree_id=t_class_fam.classif_fam_tree_id
    and class.ente_proprietario_id=p_ente_prop_id
    and tipo_class.classif_tipo_code in('SPA_CODBIL_GSA','SPP_CODBIL_GSA')
	AND v_anno_int BETWEEN date_part('year',class.validita_inizio) AND
           date_part('year',COALESCE(class.validita_fine,now())) 
    and r_class_fam.data_cancellazione IS NULL
    and r_class_fam.validita_fine IS NULL
    AND v_anno_int BETWEEN date_part('year',r_class_fam.validita_inizio) AND
           date_part('year',COALESCE(r_class_fam.validita_fine,now())) ),
conti AS( SELECT fam.pdce_fam_code,fam.pdce_fam_segno, r.classif_id,
                   conto.pdce_conto_code, conto.pdce_conto_desc,
                   conto.pdce_conto_id
            from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
                 siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
            where conto.pdce_conto_id=r.pdce_conto_id
            and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
            and   fam.pdce_fam_id=famtree.pdce_fam_id
            and   ambito.ambito_id=conto.ambito_id
            and   r.ente_proprietario_id=p_ente_prop_id
            and   ambito.ambito_code='AMBITO_GSA'
            and   r.data_cancellazione is null
            and   conto.data_cancellazione is null
            and   v_anno_int BETWEEN date_part('year',r.validita_inizio)::integer and  coalesce (date_part('year',r.validita_fine)::integer ,v_anno_int)
            and   v_anno_int BETWEEN date_part('year',conto.validita_inizio) AND date_part('year',COALESCE(conto.validita_fine,now()))
           ),
           movimenti as
           (
            select det.pdce_conto_id,
                   sum( case  when det.movep_det_segno='Dare' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_dare,
                   sum( case  when det.movep_det_segno='Avere' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_avere
            from  siac_t_periodo per,   siac_t_bil bil,
                  siac_t_prima_nota pn, siac_r_prima_nota_stato rs, siac_d_prima_nota_stato stato,
                  siac_t_mov_ep ep, siac_t_mov_ep_det det,siac_d_ambito ambito
            where per.periodo_id=bil.periodo_id            
            and   pn.bil_id=bil.bil_id
            and   rs.pnota_id=pn.pnota_id
            and   stato.pnota_stato_id=rs.pnota_stato_id
            and   ep.regep_id=pn.pnota_id
            and   det.movep_id=ep.movep_id           
            and   ambito.ambito_id=pn.ambito_id 
            and   bil.ente_proprietario_id=p_ente_prop_id
            and   per.anno::integer=v_anno_int
            and   stato.pnota_stato_code='D'            
            and   ambito.ambito_code='AMBITO_GSA'    
            and   ((p_data_pnota_da is NOT NULL and 
    				trunc(pn.pnota_dataregistrazionegiornale) between 
    					  p_data_pnota_da and p_data_pnota_a) OR
            p_data_pnota_da IS NULL)                  
            and   pn.data_cancellazione is null
            and   pn.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   ep.data_cancellazione is null
            and   ep.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            group by det.pdce_conto_id)      
insert into siac_rep_ce_sp_gsa                  
select voci.classif_id::integer, 
		voci.classif_code::varchar,
        voci.classif_desc::varchar,
        voci.livello::integer,
        voci.padre::varchar,
        voci.foglia::varchar,
        voci.classif_tipo_code::varchar,
        COALESCE(conti.pdce_conto_code,'')::varchar,
        COALESCE(conti.pdce_conto_desc,'')::varchar,
        COALESCE(replace(conti.pdce_conto_code,'.',''),'')::varchar,
        COALESCE(conti.pdce_fam_code,'')::varchar,
        COALESCE(movimenti.importo_dare,0)::numeric,
        COALESCE(movimenti.importo_avere,0)::numeric,
        --PP OP RE = Avere
        	--'PP','OP','OA','RE' = Ricavi
        case when UPPER(conti.pdce_fam_segno) ='AVERE' then 
        	COALESCE(movimenti.importo_avere,0) - COALESCE(movimenti.importo_dare,0)
        	--AP OA CE = Dare
            --'AP','CE' = Costi 
        else COALESCE(movimenti.importo_dare,0) - COALESCE(movimenti.importo_avere,0)
        end ::numeric,
        p_ente_prop_id::integer,
        user_table::varchar
from voci 
	left join conti 
    	on voci.classif_id_foglia = conti.classif_id              
	left join movimenti
    	on conti.pdce_conto_id=movimenti.pdce_conto_id
order by voci.classif_code;

  
--inserisco i record per i totali parziali
insert into siac_rep_ce_sp_gsa
values (0,'AZZ999',' D) TOTALE ATTIVO',1,'SPA_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
    
insert into siac_rep_ce_sp_gsa
values (0,'PZZ999',' F) TOTALE PASSIVO E PATRIMONIO NETTO',1,'SPP_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
        
    
RTN_MESSAGGIO:='Lettura livello massimo.';
--leggo qual e' il massimo livello per le voci di conto NON "foglia".
maxLivello:=0;
SELECT max(a.livello_codifica) 
	into maxLivello
from siac_rep_ce_sp_gsa a
where a.foglia='N'
	and a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id;
    
raise notice 'maxLivello = %', maxLivello;

RTN_MESSAGGIO:='Ciclo sui livelli';
--ciclo sui livelli partendo dal massimo in quanto devo ricostruire
--al contrario gli importi per i conti che non sono "foglia".
for conta_livelli in reverse maxLivello..1
loop     
	RTN_MESSAGGIO:='Ciclo sui conti non foglia.';
	raise notice 'conta_livelli = %', conta_livelli;
    	--ciclo su tutti i conti non "foglia" del livello che sto gestendo.
    for classifGestione IN
    	select a.cod_voce, a.classif_id
        from siac_rep_ce_sp_gsa a
        where a.foglia='N'
          and a.livello_codifica=conta_livelli
          and a.utente = user_table
          and a.ente_proprietario_id = p_ente_prop_id
     	order by a.cod_voce
     loop
        v_imp_dare:=0;
        v_imp_avere:=0;
        RTN_MESSAGGIO:='Calcolo importi.';
        
        	--calcolo gli importi come somma dei suoi figli.
        select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
        	into v_imp_dare, v_imp_avere, v_imp_saldo
        from siac_rep_ce_sp_gsa a
        where a.padre=classifGestione.cod_voce
         	and a.utente = user_table
          	and a.ente_proprietario_id = p_ente_prop_id;
        
        raise notice 'codice_voce = % - importo_dare= %, importo_avere = %', 
        	classifGestione.cod_voce, v_imp_dare,v_imp_avere;
        RTN_MESSAGGIO:='Update importi.';
        
            --aggiorno gli importi 
        update siac_rep_ce_sp_gsa a
        	set imp_dare=v_imp_dare,
            	imp_avere=v_imp_avere,
                imp_saldo=v_imp_saldo
        where cod_voce=classifGestione.cod_voce
        	and utente = user_table
          	and ente_proprietario_id = p_ente_prop_id;
            
     end loop; --loop voci NON "foglie" del livello gestito.     
end loop; --loop livelli

--devo aggiornare alcuni importi totali secondo le seguenti formule.

--AZZ999= AAZ999+ABZ999+ACZ999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AAZ999','ABZ999','ACZ999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'AZZ999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
                   
--PZZ999= PAZ999+PBZ999+PCZ999+PDZ999+PEZ999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('PAZ999','PBZ999','PCZ999','PDZ999','PEZ999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'PZZ999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
    
    /*
--CZ9999= CA0010+CA0050-CA0110-CA0150    
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0010','CA0050')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0110','CA0150')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'CZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    */
    
        
--restituisco i dati presenti sulla tabella di appoggio.
return query
select tutto.classif_id::integer, 
    tutto.cod_voce::varchar,
    tutto.descrizione_voce::varchar,
    tutto.livello_codifica::integer,
    tutto.padre::varchar,
    tutto.foglia::varchar,
    tutto.pdce_conto_code::varchar,
    tutto.pdce_conto_descr::varchar,
    tutto.pdce_conto_numerico::varchar,
    tutto.pdce_fam_code::varchar,
    tutto.imp_dare::numeric,
    tutto.imp_avere::numeric,
    tutto.imp_saldo::numeric,
	COALESCE(config.segno,1)::integer segno, 
    COALESCE(config.titolo,'') titolo,
    tutto.classif_tipo_code::varchar,
    case when tutto.livello_codifica = 1 then left(tutto.cod_voce,2)||'0000'
    	else tutto.cod_voce end::varchar,
    ''::varchar
  /*  case when tutto.cod_voce='AAZ999' then 'AA0000'
    	else case when tutto.cod_voce='ABZ999' then 'AB0000' 
        else case when tutto.cod_voce='ACZ999' then 'AC0000' 
        else case when tutto.cod_voce='ADZ999' then 'AD0000'
        else case when tutto.cod_voce='PAZ999' then 'PA0000' 
    	else case when tutto.cod_voce='PBZ999' then 'PB0000'
        else case when tutto.cod_voce='PZZ999' then 'PFA00' 
        else case when tutto.cod_voce='PEZ999' then 'PE0000'
        else case when tutto.cod_voce='PFZ999' then 'PF0000'        
        else tutto.cod_voce end end end end end end end end end::varchar */
from (select a.classif_id::integer, 
  a.cod_voce::varchar cod_voce,
  a.descrizione_voce::varchar,
  a.livello_codifica::integer,
  a.padre::varchar,
  a.foglia::varchar,
  a.classif_tipo_code,
  COALESCE(a.pdce_conto_code,'')::varchar pdce_conto_code,
  COALESCE(a.pdce_conto_descr,'')::varchar pdce_conto_descr,
  COALESCE(a.pdce_conto_numerico,'')::varchar pdce_conto_numerico,
  COALESCE(a.pdce_fam_code,'')::varchar pdce_fam_code,
  COALESCE(a.imp_dare,0)::numeric imp_dare,
  COALESCE(a.imp_avere,0)::numeric imp_avere,
  COALESCE(a.imp_saldo,0)::numeric imp_saldo
from siac_rep_ce_sp_gsa a
where a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (a.cod_voce = p_cod_bilancio OR a.padre = p_cod_bilancio)))    
UNION
select b.classif_id::integer, 
  b.cod_voce::varchar cod_voce,
  b.descrizione_voce::varchar,
  b.livello_codifica::integer,
  b.padre::varchar,
  b.foglia::varchar,
  b.classif_tipo_code::varchar,
  ''::varchar pdce_conto_code,
  ''::varchar pdce_conto_descr,
  ''::varchar pdce_conto_numerico,
  ''::varchar pdce_fam_code,
  COALESCE(sum(b.imp_dare),0)::numeric imp_dare,
  COALESCE(sum(b.imp_avere),0)::numeric imp_avere,
  COALESCE(sum(b.imp_saldo),0)::numeric imp_saldo
from siac_rep_ce_sp_gsa b
where b.utente = user_table
	and b.ente_proprietario_id = p_ente_prop_id
    and b.foglia='S'
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (b.cod_voce = p_cod_bilancio OR b.padre = p_cod_bilancio)))
    and b.classif_id not in (select c.classif_id
    		from siac_rep_ce_sp_gsa c
            where c.utente = user_table
				and c.ente_proprietario_id = p_ente_prop_id
                and c.pdce_conto_code ='')
group by b.classif_id, b.cod_voce, b.descrizione_voce, b.livello_codifica,
  b.padre, b.foglia, b.classif_tipo_code) tutto 
  left join (select conf.cod_voce, conf.titolo, conf.segno
  			 from siac_t_config_rep_ce_sp_gsa conf
             where conf.bil_id=id_bil
             and conf.tipo_report = 'SP'
             and conf.data_cancellazione IS NULL) config
  	on tutto.cod_voce=config.cod_voce   
order by 2,6;
    
delete from siac_rep_ce_sp_gsa where utente = user_table;


raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione GSA';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


-- SIAC-7874 - Maurizio - FINE