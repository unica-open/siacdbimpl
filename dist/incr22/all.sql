/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 08.01.2018 Sofia - INIZIO

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
  
  
  

--fnc_fasi_bil_gest_apertura_all
----fnc_fasi_bil_gest_apertura
------fnc_fasi_bil_provv_apertura_struttura
------fnc_fasi_bil_provv_apertura_importi

--fnc_fasi_bil_prev_approva_all
----fnc_fasi_bil_prev_approva
------fnc_fasi_bil_prev_approva_struttura
------fnc_fasi_bil_prev_approva_importi

/*
Creazione di una function plSql che in seguito ad apertura del nuovo bilancio di gestione esegua le seguenti operazioni :

- creazione delle anagrafiche dei vincoli di gestione per il nuovo annoBilancio partendo da
  - vincoli di gestione presenti nell'annoBilancio-1
  - vincoli di previsione presenti nell'annoBilancio

- creazione dei legami tra i vincoli creati e i capitoli di gestione di annoBilancio partendo da
  - capitoli equivalenti in gestione in annoBilancio-1 ( capitoli da cui il bilancio di gestione e' stato creato )
  - capitoli equivalenti in previsione in annoBilancio ( capitoli da cui il bilancio di gestione e' stato creato )
- agganciare la function creata alla function di
  - creazione del bilancio di gestione fnc_fasi_bil_gest_apertura_all
  - approvazione del bilancio di previsione fnc_fasi_bil_prev_approva_all ( in questo caso valutare se predisporre un paramentro per chiedere conferma )

fare riferimento alla jira siac-5298 per gli sviluppi gia' effettuati relativamente all'apertura del bilancio di previsione
*/
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

-- 08.01.2018 Sofia - FINE

-- SIAC-5772: aggiornamento da parte del CSI INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitadodicesimi (
  id_in integer,
  tipodisp_in varchar
)
RETURNS TABLE (
  codicerisultato integer,
  messaggiorisultato varchar,
  elemid integer,
  annocompetenza varchar,
  importodim numeric,
  importodpm numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG   constant varchar:='CAP-UG';
CL_PROGRAMMA  constant varchar:='PROGRAMMA';

TIPO_DISP_DIM constant varchar:='DIM';
TIPO_DISP_DPM constant varchar:='DPM';
TIPO_DISP_ALL constant varchar:='ENTRAMBI';

-- stati impegni
MOVGEST_TS_STATO_A  constant varchar:='A'; --- ANNULLATO

-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO

-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

-- stato capitolo annullato
AN_STATO_CAP   constant varchar:='AN';

-- stato capitolo annullato
STA_TIPOIMP_CAP   constant varchar:='STA';

-- stato variazioni per delta-meno
VAR_STATO_G    constant varchar:='G'; -- GIUNTA
VAR_STATO_C    constant varchar:='C'; -- CONSIGLIO
VAR_STATO_B    constant varchar:='B'; -- BOZZA
VAR_STATO_P    constant varchar:='P'; -- PRE-DEFINITIVA


MOVGEST_TS_T_TIPO     constant varchar:='T';
MOVGEST_TS_DET_A_TIPO constant varchar:='A';


bilancioId           integer:=0;
tipoCapitolo         varchar:=null;
strMessaggio         varchar(1500):=null;
strMessaggioFinale         varchar(1500):=null;
annoBilancio         varchar(10):=null;

enteProprietarioId   integer:=null;
idTipoCapitolo       integer:=null;
classifProgrammaCode VARCHAR(200):=null;
programmaClassId     integer:=null;
programmaClassTipoId integer:=null;

nMese                integer :=null;
dataelaborazione     timestamp;
dataFineValClass     timestamp;
periodoId            integer:=null;
elemStatoANId        integer:=null;
elemDetTipoStaId     integer:=null;
elemVarDetTipoStaId  integer:=null;
movGestTsTipoTId     integer:=null;
movGestTsStatoAId    integer:=null;
movGestTsDetATipoId  integer:=null;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;

stanziamentoTot      numeric:=null;
deltaMenoVarTot      numeric:=null;
importoIAP           numeric:=null;
importoImpCompetenza numeric:=null;
importoPagatoTot     numeric:=null;
LIC                  numeric:=0;
IAP                  numeric:=0;
LIM                  numeric:=0;

begin
    codicerisultato     :=0;
    messaggiorisultato  :=null;
    elemId              :=null;
    annocompetenza      :=null;
    importodim          :=null;
    importodpm          :=null;

    dataelaborazione    := now()::timestamp;


    strMessaggioFinale:='Calcolo disponibilità dodicesimi.';

	strMessaggio:='Controllo parametri tipo elaborazione='||tipoDisp_in||'.';
    if tipoDisp_in is null then
      raise exception ' Valore non ammesso.';
    end if;
    if tipoDisp_in not in (TIPO_DISP_DIM,TIPO_DISP_DPM,TIPO_DISP_ALL) then
   	  raise exception ' Valore non ammesso.';
    end if;

    strMessaggio:='Controllo parametri ricavati da elem_id.';
    if id_in  is null or id_in=0 then
    	raise exception ' Valore non ammesso.';
    end if;

    -- Leggo annoBilancio, bil_id e tipo capitolo
    select cap.bil_id, per.anno, tipcap.elem_tipo_code,
           cap.elem_tipo_id, cap.ente_proprietario_id,per.periodo_id
      into bilancioId, annoBilancio, tipoCapitolo, idTipoCapitolo, enteProprietarioId, periodoId
      from siac_t_bil_elem cap, siac_t_bil bila, siac_d_bil_elem_tipo tipcap, siac_t_periodo per
    where cap.elem_id=id_in
    and   bila.bil_id=cap.bil_id
    and   tipcap.elem_tipo_id=cap.elem_tipo_id
    and   per.periodo_id=bila.periodo_id
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null;

    if tipoCapitolo is null then
	    RAISE  EXCEPTION ' Errore in lettura dati capitolo.';
    end if;

    -- controllo che id_in sia un capitolo di tipo CAP-UG
    if tipoCapitolo <> TIPO_CAP_UG then
        RAISE  EXCEPTION ' Capitolo non del tipo CAP-UG.';
    end if;

    strMessaggio:='Lettura identificativo capitolo stato='||AN_STATO_CAP||'.';
	select stato.elem_stato_id into elemStatoANId
    from siac_d_bil_elem_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.elem_stato_code=AN_STATO_CAP;
    if elemStatoANId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

    strMessaggio:='Lettura identificativo capitolo tipo importo='||STA_TIPOIMP_CAP||'.';
	select tipo.elem_det_tipo_id into elemDetTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_TIPOIMP_CAP;
    if elemDetTipoStaId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

   strMessaggio:='Lettura identificativo dettaglio var capitolo tipo importo='||STA_TIPOIMP_CAP||'.';
   select bilElemDetVarTipo.elem_det_tipo_id into  elemVarDetTipoStaId
   from siac_d_bil_elem_det_tipo bilElemDetVarTipo
   where bilElemDetVarTipo.ente_proprietario_id=enteProprietarioId
   and   bilElemDetVarTipo.elem_det_tipo_code=STA_TIPOIMP_CAP;
   if elemVarDetTipoStaId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo movgest_ts_tipo='||MOVGEST_TS_T_TIPO||'.';
   select tstipo.movgest_ts_tipo_id into movGestTsTipoTId
   from siac_d_movgest_ts_tipo tstipo
   where tstipo.ente_proprietario_id=enteProprietarioId
   and   tstipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO;
   if movGestTsTipoTId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo movgest_ts_stato='||MOVGEST_TS_STATO_A||'.';
   select movstato.movgest_stato_id into movGestTsStatoAId
   from siac_d_movgest_stato movstato
   where movstato.ente_proprietario_id=enteProprietarioId
   and   movstato.movgest_stato_code=MOVGEST_TS_STATO_A;
   if movGestTsStatoAId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo movgest_ts_det_tipo='||MOVGEST_TS_DET_A_TIPO||'.';
   select dettipo.movgest_ts_det_tipo_id into movGestTsDetATipoId
   from siac_d_movgest_ts_det_tipo dettipo
   where dettipo.ente_proprietario_id=enteProprietarioId
   and   dettipo.movgest_ts_det_tipo_code=MOVGEST_TS_DET_A_TIPO;
   if movGestTsDetATipoId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo ord_stato_code='||STATO_ORD_A||'.';
   select ordstato.ord_stato_id into ordStatoAId
   from siac_d_ordinativo_stato ordstato
   where ordstato.ente_proprietario_id=enteProprietarioId
   and   ordstato.ord_stato_code=STATO_ORD_A;

   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
   from siac_d_ordinativo_ts_det_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;


   dataFineValClass    := (annoBilancio||'-12-31')::timestamp;

   strMessaggio:='Lettura dati classificatore='||CL_PROGRAMMA||'.';
   -- ricavare il programma collegato al id_in ( siac_t_class [PROGRAMMA])
   select k.classif_code, k.classif_id, k.classif_tipo_id
      into classifProgrammaCode, programmaClassId, programmaClassTipoId
   from siac_t_class k, siac_r_bil_elem_class l, siac_d_class_tipo r
   where l.elem_id = id_in
   and   k.classif_id = l.classif_id
   and   r.classif_tipo_id=k.classif_tipo_id
   and   r.classif_tipo_code=CL_PROGRAMMA
   and   r.ente_proprietario_id=l.ente_proprietario_id
   and   l.data_cancellazione is null
   and   l.validita_fine is null
   and   k.data_cancellazione is null
   and   date_trunc('DAY',dataElaborazione)>=date_trunc('DAY',k.validita_inizio)
   and   date_trunc('DAY',dataFineValClass)<=date_trunc('DAY',coalesce(k.validita_fine,dataFineValClass));

   if programmaClassId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura stanziamento totale competenza.';
   -- calcolo stanziamento competenza per programma
   /*
   select sum(det.elem_det_importo) into stanziamentoTot
   from siac_t_bil_elem e,siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
	    siac_t_bil_elem_det det
   where e.bil_id=bilancioId
    and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rstato.elem_id=e.elem_id
	and   rstato.elem_stato_id!=elemStatoANId
	and   det.elem_id=e.elem_id
	and   det.elem_det_tipo_id=elemDetTipoStaId
	and   det.periodo_id=periodoId
	and   rstato.data_cancellazione is null
	and   rstato.validita_fine is null
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   det.data_cancellazione is null
	and   det.validita_fine is null;
 */

/* 11/01/2018 A.V. introdotta condizione su flagImpegnabile per escludere i non
impegnabili dal calcolo */

   select sum(det.elem_det_importo) into stanziamentoTot
   from siac_t_bil_elem e,siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
	    siac_t_bil_elem_det det
        , siac_t_attr att, siac_r_bil_elem_attr attr
   where e.bil_id=bilancioId
    and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rstato.elem_id=e.elem_id
	and   rstato.elem_stato_id!=elemStatoANId
	and   det.elem_id=e.elem_id
	and   det.elem_det_tipo_id=elemDetTipoStaId
	and   det.periodo_id=periodoId
	and   rstato.data_cancellazione is null
	and   rstato.validita_fine is null
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   det.data_cancellazione is null
	and   det.validita_fine is null
    and   attr.elem_id=e.elem_id
    and   attr.attr_id=att.attr_id
    and   att.attr_code='FlagImpegnabile'
    and   attr."boolean"<>'N'
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;

   if stanziamentoTot is null then
     RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura delta-meno totale competenza.';
   select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into deltaMenoVarTot
   from  siac_t_bil_elem e,siac_r_bil_elem_stato rstato,  siac_r_bil_elem_class rc,
         siac_t_variazione var, siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
         siac_t_bil_elem_det_var bilElemDetVar
   where e.bil_id=bilancioId
	and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rstato.elem_id=e.elem_id
	and   rstato.elem_stato_id!=elemStatoANId
	and   rstato.data_cancellazione is null
	and   rstato.validita_fine is null
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   bilElemDetVar.elem_id=e.elem_id
	and   bilElemDetVar.periodo_id=periodoId
	and   bilElemDetVar.elem_det_importo<0
	and   bilElemDetVar.elem_det_tipo_id=elemVarDetTipoStaId
	and   bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
	and   tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
	and   tipoStatoVar.variazione_stato_tipo_code in (VAR_STATO_G,VAR_STATO_C,VAR_STATO_P,VAR_STATO_B)
	and   var.variazione_id=statoVar.variazione_id
	and   var.bil_id=bilancioId
  	and   bilElemDetVar.data_cancellazione is null
	and   bilElemDetVar.validita_fine is null
    and   statoVar.data_cancellazione is null
    and   statoVar.validita_fine is null
    and   var.data_cancellazione is null
    and  var.validita_fine is null;

   if deltaMenoVarTot is null then
     RAISE  EXCEPTION ' Errore in lettura delta-meno.';
   end if;

   strMessaggio:='Lettura importo IAP.';
   select coalesce(sum(tsdet.movgest_ts_det_importo),0) into importoIAP
   from siac_t_bil_elem e, siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
        siac_r_movgest_bil_elem rmov, siac_t_movgest mov, siac_t_movgest_ts ts,
    	siac_r_movgest_ts_stato rmovstato,
	    siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
	    siac_t_movgest_ts_det tsdet
   where e.bil_id=bilancioId
	and  e.elem_tipo_id=idTipoCapitolo
	and  rc.elem_id=e.elem_id
	and  rc.classif_id=programmaClassId
	and  rstato.elem_id=e.elem_id
	and  rstato.elem_stato_id!=elemStatoANId
	and  rmov.elem_id=e.elem_id
	and  mov.movgest_id=rmov.movgest_id
	and  mov.movgest_anno::integer=annoBilancio::integer
	and  ts.movgest_id=mov.movgest_id
	and  ts.movgest_ts_tipo_id=movGestTsTipoTId
	and  rmovstato.movgest_ts_id=ts.movgest_ts_id
	and  rmovstato.movgest_stato_id!=movGestTsStatoAId
	and  rmovatto.movgest_ts_id=ts.movgest_ts_id
	and  attoamm.attoamm_id=rmovatto.attoamm_id
	and  attoamm.attoamm_anno::integer<annoBilancio::integer
	and  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  tsdet.movgest_ts_det_tipo_id=movGestTsDetATipoId
	and  rstato.data_cancellazione is null
	and  rstato.validita_fine is null
	and  e.data_cancellazione is null
	and  e.validita_fine is null
	and  rc.data_cancellazione is null
	and  rc.validita_fine is null
	and  mov.data_cancellazione is null
	and  mov.validita_fine is null
	and  ts.data_cancellazione is null
	and  ts.validita_fine is null
	and  rmov.data_cancellazione is null
	and  rmov.validita_fine is null
	and  rmovstato.data_cancellazione is null
	and  rmovstato.validita_fine is null
	and  rmovatto.data_cancellazione is null
	and  rmovatto.validita_fine is null
	and  attoamm.data_cancellazione is null
	and  attoamm.validita_fine is null
	and  tsdet.data_cancellazione is null
	and  tsdet.validita_fine is null;

    if importoIAP is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

  -- per calcolo DIM o ENTRAMBI allora calcolo impegnato competenza
  if tipoDisp_in in ( TIPO_DISP_ALL,TIPO_DISP_DIM) then
   strMessaggio:='Lettura importo impegnato competenza.';
   select coalesce(sum(tsdet.movgest_ts_det_importo),0) into importoImpCompetenza
   from siac_t_bil_elem e, siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
        siac_r_movgest_bil_elem rmov, siac_t_movgest mov, siac_t_movgest_ts ts,
    	siac_r_movgest_ts_stato rmovstato,
	    siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
	    siac_t_movgest_ts_det tsdet
   where e.bil_id=bilancioId
	and  e.elem_tipo_id=idTipoCapitolo
	and  rc.elem_id=e.elem_id
	and  rc.classif_id=programmaClassId
	and  rstato.elem_id=e.elem_id
	and  rstato.elem_stato_id!=elemStatoANId
	and  rmov.elem_id=e.elem_id
	and  mov.movgest_id=rmov.movgest_id
	and  mov.movgest_anno::integer=annoBilancio::integer
	and  ts.movgest_id=mov.movgest_id
	and  ts.movgest_ts_tipo_id=movGestTsTipoTId
	and  rmovstato.movgest_ts_id=ts.movgest_ts_id
	and  rmovstato.movgest_stato_id!=movGestTsStatoAId
	and  rmovatto.movgest_ts_id=ts.movgest_ts_id
	and  attoamm.attoamm_id=rmovatto.attoamm_id
	and  attoamm.attoamm_anno::integer=annoBilancio::integer
	and  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  tsdet.movgest_ts_det_tipo_id=movGestTsDetATipoId
	and  rstato.data_cancellazione is null
	and  rstato.validita_fine is null
	and  e.data_cancellazione is null
	and  e.validita_fine is null
	and  rc.data_cancellazione is null
	and  rc.validita_fine is null
	and  mov.data_cancellazione is null
	and  mov.validita_fine is null
	and  ts.data_cancellazione is null
	and  ts.validita_fine is null
	and  rmov.data_cancellazione is null
	and  rmov.validita_fine is null
	and  rmovstato.data_cancellazione is null
	and  rmovstato.validita_fine is null
	and  rmovatto.data_cancellazione is null
	and  rmovatto.validita_fine is null
	and  attoamm.data_cancellazione is null
	and  attoamm.validita_fine is null
	and  tsdet.data_cancellazione is null
	and  tsdet.validita_fine is null;

    if importoImpCompetenza is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

   end if;

   -- per calcolo DPM o ENTRAMBI allora calcolo pagato competenza
   if  tipoDisp_in in ( TIPO_DISP_ALL,TIPO_DISP_DPM) then
    strMessaggio:='Lettura importo pagato competenza.';
	select coalesce(sum(tsdet.ord_ts_det_importo),0) into importoPagatoTot
	from siac_t_bil_elem e,  siac_r_bil_elem_class rc,siac_r_movgest_bil_elem rmov,
         siac_t_movgest mov, siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
	     siac_r_liquidazione_movgest rliq,
    	 siac_r_liquidazione_ord rord, siac_t_ordinativo_ts ordts, siac_t_ordinativo ord,
	     siac_r_ordinativo_stato rordstato,
    	 siac_t_ordinativo_ts_det tsdet
	where e.bil_id=bilancioId
	and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rmov.elem_id=e.elem_id
	and   mov.movgest_id=rmov.movgest_id
	and   ts.movgest_id=mov.movgest_id
	and   mov.movgest_anno::integer=annoBilancio::integer
	and   rmovatto.movgest_ts_id=ts.movgest_ts_id
	and   attoamm.attoamm_id=rmovatto.attoamm_id
	and   attoamm.attoamm_anno::integer=annoBilancio::integer
	and   rliq.movgest_ts_id=ts.movgest_ts_id
	and   rord.liq_id=rliq.liq_id
	and   ordts.ord_ts_id=rord.sord_id
	and   ord.ord_id=ordts.ord_id
	and   rordstato.ord_id=ord.ord_id
	and   rordstato.ord_stato_id!=ordStatoAId
	and   tsdet.ord_ts_id=ordts.ord_ts_id
	and   tsdet.ord_ts_det_tipo_id=ordTsDetTipoAId
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   mov.data_cancellazione is null
	and   mov.validita_fine is null
	and   ts.data_cancellazione is null
	and   ts.validita_fine is null
	and   rmov.data_cancellazione is null
	and   rmov.validita_fine is null
	and   rord.data_cancellazione is null
	and   rord.validita_fine is null
	and   rliq.data_cancellazione is null
	and   rliq.validita_fine is null
	and   ordts.data_cancellazione is null
	and   ordts.validita_fine is null
	and   ord.data_cancellazione is null
	and   ord.validita_fine is null
	and   rordstato.data_cancellazione is null
	and   rordstato.validita_fine is null
	and   tsdet.data_cancellazione is null
	and   tsdet.validita_fine is null
	and   rmovatto.data_cancellazione is null
	and   rmovatto.validita_fine is null
	and   attoamm.data_cancellazione is null
	and   attoamm.validita_fine is null;

    if importoPagatoTot is null then
    	RAISE  EXCEPTION ' Errore in lettura.';
    end if;
   end if;


   LIC:=stanziamentoTot-deltaMenoVarTot;
   IAP:=importoIAP;
   -- ricava il mese dal timestamp attuale
   nMese:=date_part('month',dataelaborazione);
   LIM:=round((LIC-IAP)/12,2);

   raise notice 'LIC=%',LIC;
   raise notice 'IAP=%',IAP;
   raise notice 'nMese=%',nMese;
   raise notice 'LIM=%',LIM;


   if tipoDisp_in = TIPO_DISP_ALL then
       -- calcolo DIM + calcolo DPM
       importodim := (LIM*nMEse) - importoImpCompetenza;
       importodpm := (LIM*nMEse) - importoPagatoTot;
   elsif tipoDisp_in = TIPO_DISP_DIM then
        -- calcolo DIM
        importodim := (LIM*nMEse) - importoImpCompetenza;
   else
           -- calcolo DPM
       importodpm := (LIM*nMEse) - importoPagatoTot;
   end if;

   raise notice 'importodim=%',importodim;
   raise notice 'importodpm=%',importodpm;

   -- setta gli altri campi di ritorno
   codicerisultato    := 0;
   messaggiorisultato := strMessaggioFinale||'Risultato OK.';
   elemid             := id_in;
   annocompetenza     := annoBilancio;

   return next;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        RAISE notice '%',messaggioRisultato;
        codiceRisultato:=-1;
        return;
    when no_data_found then
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Nessun elemento trovato.' ;
        RAISE notice '%',messaggioRisultato;
        codiceRisultato:=-1;
        return;
    when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1050) ;
        RAISE notice '%',messaggioRisultato;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5772: aggiornamento da parte del CSI INIZIO - Maurizio

-- SIAC-5485 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_770_tracciato_quadro_c_f (
  p_anno_elab varchar,
  p_ente_proprietario_id integer,
  p_ex_ente varchar,
  p_quadro_c_f varchar
)
RETURNS varchar AS
$body$
DECLARE

rec_tracciato_770 record;
rec_indirizzo record;
rec_inps record;
rec_tracciato_fin_c record;
rec_tracciato_fin_f record;

v_soggetto_id INTEGER; -- SIAC-5485
v_comune_id_nascita INTEGER; 
v_comune_id INTEGER;
v_comune_id_gen INTEGER;
v_via_tipo_id INTEGER;
v_ord_id_a INTEGER;
v_indirizzo_tipo_code VARCHAR;
v_principale VARCHAR;
v_onere_tipo_code VARCHAR;

v_zip_code VARCHAR;
v_comune_desc VARCHAR;
v_provincia_desc VARCHAR;
v_nazione_desc VARCHAR;
v_indirizzo VARCHAR;
v_via_tipo_desc VARCHAR;
v_toponimo VARCHAR;
v_numero_civico VARCHAR;
v_frazione VARCHAR;
v_interno VARCHAR;
-- INPS
v_importoParzInpsImpon NUMERIC;
v_importoParzInpsNetto NUMERIC;
v_importoParzInpsRiten NUMERIC;
v_importoParzInpsEnte NUMERIC;
v_importo_ritenuta_inps NUMERIC;
v_importo_imponibile_inps NUMERIC;
v_importo_ente_inps NUMERIC;
v_importo_netto_inps NUMERIC;
v_idFatturaOld INTEGER;
v_contaQuotaInps INTEGER;
v_percQuota NUMERIC;
v_numeroQuoteFattura INTEGER;
-- INPS 
v_tipo_record VARCHAR;
v_codice_fiscale_ente VARCHAR;
v_codice_fiscale_percipiente VARCHAR;
v_tipo_percipiente VARCHAR;
v_cognome VARCHAR;
v_nome VARCHAR;
v_sesso VARCHAR;
v_data_nascita TIMESTAMP;    
v_comune_nascita VARCHAR;
v_nazione_nascita VARCHAR; 
v_provincia_nascita VARCHAR;
v_comune_indirizzo_principale VARCHAR;
v_provincia_indirizzo_principale VARCHAR;
v_indirizzo_principale VARCHAR;
v_cap_indirizzo_principale VARCHAR;  
 
v_indirizzo_fiscale VARCHAR;
v_cap_indirizzo_fiscale VARCHAR;
v_comune_indirizzo_fiscale VARCHAR;
v_provincia_indirizzo_fiscale VARCHAR;    
        
v_codice_fiscale_estero VARCHAR;
v_causale VARCHAR;
v_importo_lordo NUMERIC;
v_somma_non_soggetta NUMERIC;  
v_importo_imponibile NUMERIC;
v_ord_ts_det_importo NUMERIC;
v_importo_carico_ente NUMERIC;
v_importo_carico_soggetto NUMERIC; 
v_codice VARCHAR;  
v_codice_tributo VARCHAR;
v_matricola_c INTEGER;
v_matricola_f INTEGER;
v_codice_controllo2 VARCHAR;
v_aliquota NUMERIC;
    
v_elab_id INTEGER;
v_elab_id_det INTEGER;
v_elab_id_temp INTEGER;
v_elab_id_det_temp INTEGER;
v_codresult INTEGER := null;
elab_mif_esito_in CONSTANT  VARCHAR := 'IN';
elab_mif_esito_ok CONSTANT  VARCHAR := 'OK';
elab_mif_esito_ko CONSTANT  VARCHAR := 'KO';
v_tipo_flusso  CONSTANT  VARCHAR := 'MOD770';
v_login CONSTANT  VARCHAR := 'SIAC';
messaggioRisultato VARCHAR;

BEGIN

-- Inserimento record in tabella mif_t_flusso_elaborato
INSERT INTO mif_t_flusso_elaborato
(flusso_elab_mif_data,
 flusso_elab_mif_esito,
 flusso_elab_mif_esito_msg,
 flusso_elab_mif_file_nome,
 flusso_elab_mif_tipo_id,
 flusso_elab_mif_id_flusso_oil,
 validita_inizio,
 ente_proprietario_id,
 login_operazione)
 (SELECT now(),
         elab_mif_esito_in,
         'Elaborazione in corso per tipo flusso '||v_tipo_flusso,
         tipo.flusso_elab_mif_nome_file,
         tipo.flusso_elab_mif_tipo_id,
         null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
         now(),
         p_ente_proprietario_id,
         v_login
  FROM mif_d_flusso_elaborato_tipo tipo
  WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
  AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
  AND   tipo.data_cancellazione IS NULL
  AND   tipo.validita_fine IS NULL
 )
 RETURNING flusso_elab_mif_id into v_elab_id;

IF p_anno_elab IS NULL THEN
   messaggioRisultato := 'Parametro Anno di Elaborazione nullo.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;
END IF;

IF p_ente_proprietario_id IS NULL THEN
   messaggioRisultato := 'Parametro Ente Propietario nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_ex_ente IS NULL THEN
   messaggioRisultato := 'Parametro Ex Ente nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_quadro_c_f IS NULL THEN
   messaggioRisultato := 'Parametro Quadro C-F nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF v_elab_id IS NULL THEN
  messaggioRisultato := 'Errore generico in inserimento';
  -- RETURN NEXT;  
  RETURN messaggioRisultato;
END IF;

v_codresult:=null;
-- Verifica esistenza elaborazioni in corso per tipo flusso
SELECT DISTINCT 1 
INTO v_codresult
FROM mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
WHERE  elab.flusso_elab_mif_id != v_elab_id
AND    elab.flusso_elab_mif_esito = elab_mif_esito_in
AND    elab.data_cancellazione IS NULL
AND    elab.validita_fine IS NULL
AND    tipo.flusso_elab_mif_tipo_id = elab.flusso_elab_mif_tipo_id
AND    tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
AND    tipo.ente_proprietario_id = p_ente_proprietario_id
AND    tipo.data_cancellazione IS NULL
AND    tipo.validita_fine IS NULL;

IF v_codresult IS NOT NULL THEN
   messaggioRisultato := 'Verificare situazioni esistenti.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;  
END IF;

v_elab_id_det := 1;
v_elab_id_det_temp := 1;
v_matricola_c := 8000000;
v_matricola_f := 9000000;

IF p_quadro_c_f in ('C','T') THEN
  DELETE FROM siac.tracciato_770_quadro_c_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_c
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f in ('F','T') THEN
  DELETE FROM siac.tracciato_770_quadro_f_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_f
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f = 'C' THEN
   v_onere_tipo_code := 'IRPEF';
ELSIF p_quadro_c_f = 'F' THEN
   v_onere_tipo_code := 'IRPEG';
ELSE
   v_onere_tipo_code := null;
END IF;   

v_codice_fiscale_ente := null;
v_tipo_record := null;

SELECT codice_fiscale
INTO   v_codice_fiscale_ente
FROM   siac_t_ente_proprietario
WHERE  ente_proprietario_id = p_ente_proprietario_id;

--v_importo_lordo := 0;
--v_codice_tributo := null;
--v_causale := null; 

v_idFatturaOld := 0;
v_contaQuotaInps := 0;

FOR rec_tracciato_770 IN
SELECT --sto.ord_id, 
       --SUM(totd.ord_ts_det_importo) IMPORTO_LORDO,
       --totd.ord_ts_det_importo IMPORTO_LORDO,       
       rdo.caus_id,
       sdo.onere_code,
       td.doc_id,
       rdo.doc_onere_id,
       rdo.somma_non_soggetta_tipo_id,
       rdo.onere_id,
       sros.soggetto_id,
       roa.testo
FROM  siac_t_ordinativo sto
INNER JOIN siac_t_ente_proprietario tep ON sto.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac_t_bil tb ON tb.bil_id = sto.bil_id
INNER JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
INNER JOIN siac_d_ordinativo_tipo dot ON dot.ord_tipo_id = sto.ord_tipo_id
INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
--INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
--INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
INNER JOIN siac_r_onere_attr roa ON roa.onere_id = rdo.onere_id
INNER JOIN siac_t_attr ta ON ta.attr_id = roa.attr_id
INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
INNER JOIN siac_r_ordinativo_soggetto sros ON sros.ord_id = sto.ord_id
WHERE sto.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dos.ord_stato_code <> 'A'
AND   dot.ord_tipo_code = 'P'
--AND   dotdt.ord_ts_det_tipo_code = 'A'
AND   ((roa.testo = p_quadro_c_f) OR ('T' = p_quadro_c_f AND roa.testo IN ('C','F')))
AND   ta.attr_code = 'QUADRO_770'
AND   ((sdot.onere_tipo_code = v_onere_tipo_code) OR ('T' = p_quadro_c_f AND sdot.onere_tipo_code IN ('IRPEF','IRPEG')))
AND   sto.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   tot.data_cancellazione IS NULL
--AND   totd.data_cancellazione IS NULL
--AND   dotdt.data_cancellazione IS NULL
AND   rsot.data_cancellazione IS NULL
AND   ts.data_cancellazione IS NULL
AND   td.data_cancellazione IS NULL
AND   rdo.data_cancellazione IS NULL
AND   roa.data_cancellazione IS NULL
AND   ta.data_cancellazione IS NULL
AND   sdo.data_cancellazione IS NULL
AND   sdot.data_cancellazione IS NULL
AND   sros.data_cancellazione IS NULL
AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
AND   now() BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, now())
AND   now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND   now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
AND   now() BETWEEN dot.validita_inizio AND COALESCE(dot.validita_fine, now())
AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
--AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
--AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
AND   now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
AND   now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now())
AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
AND   now() BETWEEN sros.validita_inizio AND COALESCE(sros.validita_fine, now())
GROUP BY   rdo.caus_id,
           sdo.onere_code,
           td.doc_id,
           rdo.doc_onere_id,
           rdo.somma_non_soggetta_tipo_id,
           rdo.onere_id,
           sros.soggetto_id,
           roa.testo

LOOP  

  --v_importo_lordo := 0;
  v_importoParzInpsImpon := 0;
  v_importoParzInpsNetto := 0;
  v_importoParzInpsRiten := 0;
  v_importoParzInpsEnte := 0;
  v_importo_ritenuta_inps := 0;
  v_importo_imponibile_inps := 0;
  v_importo_ente_inps := 0;
  v_importo_netto_inps := 0;
  v_codice_tributo := null;

  --v_importo_lordo := rec_tracciato_770.IMPORTO_LORDO;
  v_codice_tributo := rec_tracciato_770.onere_code;
  
  v_causale := null;
  
  BEGIN

    SELECT dc.caus_code
    INTO   STRICT v_causale
    FROM   siac_d_causale dc
    WHERE  dc.caus_id = rec_tracciato_770.caus_id
    AND    dc.data_cancellazione IS NULL
    AND    now() BETWEEN dc.validita_inizio AND COALESCE(dc.validita_fine, now());

  EXCEPTION
      
    WHEN NO_DATA_FOUND THEN
        v_causale := null;
      
  END;

  IF rec_tracciato_770.testo = 'C' THEN
   
    v_tipo_record := 'SC';   
    
    v_codice := null;
    
    IF rec_tracciato_770.somma_non_soggetta_tipo_id IS NULL THEN
    
          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          --INTO  STRICT v_codice
          INTO  v_codice
          FROM  siac_r_onere_somma_non_soggetta_tipo rosnst,
                siac_d_somma_non_soggetta_tipo dsnst
          WHERE rosnst.somma_non_soggetta_tipo_id = dsnst.somma_non_soggetta_tipo_id   
          AND   rosnst.onere_id = rec_tracciato_770.onere_id
          AND   rosnst.data_cancellazione IS NULL
          AND   dsnst.data_cancellazione IS NULL
          AND   now() BETWEEN rosnst.validita_inizio AND COALESCE(rosnst.validita_fine, now())
          AND   now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());
                              
    ELSE

        BEGIN

          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          INTO   STRICT v_codice 
          FROM   siac_d_somma_non_soggetta_tipo dsnst
          WHERE  dsnst.somma_non_soggetta_tipo_id = rec_tracciato_770.somma_non_soggetta_tipo_id
          AND    dsnst.data_cancellazione IS NULL
          AND    now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());  
      
        EXCEPTION
              
          WHEN NO_DATA_FOUND THEN
              v_codice := null;
              
        END;    
    
    END IF;
    
  ELSE
    
    v_tipo_record := 'SF'; 
    
  END IF;

    -- PARTE RELATIVA AL SOGGETTO INIZIO
    
    v_codice_fiscale_percipiente := null;
    v_codice_fiscale_estero := null;
    v_tipo_percipiente := null;
    v_cognome := null;
    v_nome := null;
    v_sesso := null;
    v_data_nascita := null;
    v_comune_id_nascita := null;
    v_soggetto_id := null; -- SIAC-5485 
    
    BEGIN -- SIAC-5485 INIZIO
    
    SELECT a.soggetto_id_da
    INTO   STRICT v_soggetto_id
    FROM   siac_r_soggetto_relaz a, siac_d_relaz_tipo b
    WHERE  a.ente_proprietario_id = p_ente_proprietario_id
    AND    a.relaz_tipo_id = b.relaz_tipo_id
    AND    b.relaz_tipo_code = 'SEDE_SECONDARIA'
    AND    a.soggetto_id_a = rec_tracciato_770.soggetto_id;
    
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN      
           v_soggetto_id := rec_tracciato_770.soggetto_id; 
              
    END; -- SIAC-5485 FINE
        
    BEGIN
    
      SELECT ts.codice_fiscale,
             ts.codice_fiscale_estero,
             CASE 
                WHEN dst.soggetto_tipo_code IN ('PF','PFI') THEN
                     1
                ELSE
                     2
             END tipo_percipiente,
             coalesce(tpf.cognome, tpg.ragione_sociale) cognome,
             tpf.nome,
             tpf.sesso,
             tpf.nascita_data,
             tpf.comune_id_nascita
      INTO  STRICT v_codice_fiscale_percipiente,
            v_codice_fiscale_estero,
            v_tipo_percipiente,
            v_cognome,
            v_nome,
            v_sesso,
            v_data_nascita,
            v_comune_id_nascita                
      FROM siac_t_soggetto ts
      INNER JOIN siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
      INNER JOIN siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
      LEFT JOIN  siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, now())
                                              AND tpg.data_cancellazione IS NULL
      LEFT JOIN  siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, now())
                                              AND tpf.data_cancellazione IS NULL
      WHERE ts.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
      AND   ts.data_cancellazione IS NULL
      AND   rst.data_cancellazione IS NULL
      AND   dst.data_cancellazione IS NULL
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, now())
      AND   now() BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, now());

      v_cognome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cognome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
      v_nome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_indirizzo_principale := null;
    v_cap_indirizzo_principale := null;
    v_comune_indirizzo_principale := null;
    v_provincia_indirizzo_principale := null;

    v_indirizzo_fiscale := null; -- SIAC-5485
    v_cap_indirizzo_fiscale := null; -- SIAC-5485
    v_comune_indirizzo_fiscale := null; -- SIAC-5485
    v_provincia_indirizzo_fiscale := null; -- SIAC-5485

    v_comune_nascita := null;
    v_provincia_nascita := null;
    v_nazione_nascita := null;    
    
    FOR rec_indirizzo IN
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
    AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL
    UNION -- SIAC-5485 INIZIO
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = rec_tracciato_770.soggetto_id
    AND   dit.indirizzo_tipo_code = 'DOMICILIO'
    --AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL -- SIAC-5485 FINE    
    UNION
    SELECT NULL, 'NASCITA', NULL, NULL, NULL, NULL, NULL, NULL, NULL

    LOOP

      v_comune_id := null;
      v_comune_id_gen := null;
      v_via_tipo_id := null;
      v_indirizzo_tipo_code := null;
      v_principale := null;
      
      v_zip_code := null;
      v_comune_desc := null;
      v_provincia_desc := null;
      v_nazione_desc := null;
      v_indirizzo := null;
      v_via_tipo_desc := null;
      v_toponimo := null;
      v_numero_civico := null;
      v_frazione := null;
      v_interno := null;
      
      v_comune_id := rec_indirizzo.comune_id;
      v_via_tipo_id := rec_indirizzo.via_tipo_id;      
      v_indirizzo_tipo_code := rec_indirizzo.indirizzo_tipo_code;      
      v_principale := rec_indirizzo.principale;
      
      v_zip_code := rec_indirizzo.zip_code;
      v_toponimo := rec_indirizzo.toponimo;
      v_numero_civico := rec_indirizzo.numero_civico;
      v_frazione := rec_indirizzo.frazione;
      v_interno := rec_indirizzo.interno;

      BEGIN
      
        SELECT dvt.via_tipo_desc
        INTO STRICT v_via_tipo_desc
        FROM siac.siac_d_via_tipo dvt
        WHERE dvt.via_tipo_id = v_via_tipo_id
        AND now() BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, now())
        AND dvt.data_cancellazione IS NULL;
      
      EXCEPTION
      
        WHEN NO_DATA_FOUND THEN
        	v_via_tipo_desc := null;
      
      END;
      
      IF v_via_tipo_desc IS NOT NULL THEN
         v_indirizzo := v_via_tipo_desc;
      END IF;

      IF v_toponimo IS NOT NULL THEN
         v_indirizzo := v_indirizzo||' '||v_toponimo;
      END IF;

      IF v_numero_civico IS NOT NULL THEN
         v_indirizzo := v_indirizzo||' '||v_numero_civico;
      END IF;

      IF v_frazione IS NOT NULL THEN
         v_indirizzo := v_indirizzo||', frazione '||v_frazione;
      END IF;

      IF v_interno IS NOT NULL THEN
         v_indirizzo := v_indirizzo||', interno '||v_interno;
      END IF;

      v_indirizzo := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_indirizzo),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''');
      v_indirizzo := UPPER(v_indirizzo);

      IF v_indirizzo_tipo_code = 'NASCITA' THEN
         v_comune_id_gen := v_comune_id_nascita;
      ELSE
         v_comune_id_gen := v_comune_id;
      END IF;

      BEGIN

        SELECT tc.comune_desc, tp.sigla_automobilistica, tn.nazione_desc
        INTO  STRICT v_comune_desc, v_provincia_desc, v_nazione_desc
        FROM siac.siac_t_comune tc
        LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                                   AND now() BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, now())
                                                   AND rcp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                           AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
                                           AND tp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                         AND now() BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, now())
                                         AND tn.data_cancellazione IS NULL
        WHERE tc.comune_id = v_comune_id_gen
        AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
        AND tc.data_cancellazione IS NULL;

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

    
      IF v_principale = 'S' THEN
         v_indirizzo_principale := v_indirizzo;
         v_cap_indirizzo_principale := v_zip_code;
         v_comune_indirizzo_principale := v_comune_desc;
         v_provincia_indirizzo_principale := v_provincia_desc;
      END IF;
       -- SIAC-5485 INIZIO
      IF  indirizzo_tipo_code = 'DOMICILIO' THEN
         v_indirizzo_fiscale := v_indirizzo;
         v_cap_indirizzo_fiscale := v_zip_code;
         v_comune_indirizzo_fiscale := v_comune_desc;
         v_provincia_indirizzo_fiscale := v_provincia_desc;      
      END IF;
      -- SIAC-5485 FINE
      IF  v_indirizzo_tipo_code = 'NASCITA' THEN
          v_comune_nascita := v_comune_desc;
          v_provincia_nascita := v_provincia_desc;
          v_nazione_nascita := v_nazione_desc;
      END IF;    

    END LOOP;

    v_cap_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_comune_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_cap_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_provincia_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_nazione_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nazione_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    -- PARTE RELATIVA AL SOGGETTO FINE

    v_somma_non_soggetta := 0;  
    v_importo_imponibile := 0;
    v_importo_lordo := 0;
/*     v_ord_ts_det_importo := 0;

   SELECT rdo.somma_non_soggetta,  --> id 32 
           rdo.importo_imponibile,  --> id 33 
           totd.ord_ts_det_importo  --> id 34 e id 35 a 0
    INTO   v_somma_non_soggetta,   
           v_importo_imponibile,
           v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
    FROM   siac_r_doc_onere_ordinativo_ts rdoot   
    INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
    INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
    INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
    INNER  JOIN siac_r_doc_onere rdo ON rdoot.doc_onere_id = rdo.doc_onere_id
    WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
    AND    dotdt.ord_ts_det_tipo_code = 'A'  
    AND    rdoot.data_cancellazione IS NULL
    AND    tot.data_cancellazione IS NULL
    AND    totd.data_cancellazione IS NULL
    AND    dotdt.data_cancellazione IS NULL
    AND    rdo.data_cancellazione IS NULL
    AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
    AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
    AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
    AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
    AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());*/

    BEGIN

      SELECT COALESCE(rdo.somma_non_soggetta,0),  --> id 31 
             COALESCE(rdo.importo_imponibile,0)   --> id 32 
      INTO   STRICT v_somma_non_soggetta,   
             v_importo_imponibile    
      FROM   siac_r_doc_onere rdo
      WHERE  rdo.doc_onere_id = rec_tracciato_770.doc_onere_id
      AND    rdo.data_cancellazione IS NULL
      AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());
      
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_importo_lordo := v_importo_imponibile + v_somma_non_soggetta;
      
      v_ord_ts_det_importo := 0;

      BEGIN

        SELECT SUM(totd.ord_ts_det_importo) --> id 34 e id 35 a 0
        INTO   STRICT v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
        FROM   siac_r_doc_onere_ordinativo_ts rdoot 
        INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
        INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
        INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
        INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
        INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
        INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
        WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
        AND    dotdt.ord_ts_det_tipo_code = 'A'  
        AND    dos.ord_stato_code <> 'A'
        AND    rdoot.data_cancellazione IS NULL
        AND    tot.data_cancellazione IS NULL
        AND    sto.data_cancellazione IS NULL
        AND    ros.data_cancellazione IS NULL
        AND    dos.data_cancellazione IS NULL    
        AND    totd.data_cancellazione IS NULL
        AND    dotdt.data_cancellazione IS NULL
        AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
        AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
        AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
        AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
        AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
        AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
        AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

IF rec_tracciato_770.testo = 'F' THEN

  BEGIN

    v_aliquota := 0;

    SELECT roa.percentuale
    INTO   STRICT v_aliquota
    FROM   siac_d_onere sdo, siac_r_onere_attr roa, siac_t_attr ta
    WHERE  sdo.onere_id = rec_tracciato_770.onere_id
    AND    sdo.onere_id = roa.onere_id    
    AND    roa.attr_id = ta.attr_id
    AND    ta.attr_code = 'ALIQUOTA_SOGG'
    AND    sdo.data_cancellazione IS NULL
    AND    roa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
    AND    now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
    AND    now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now());

  EXCEPTION
                
    WHEN NO_DATA_FOUND THEN
         null;
                
  END;

END IF;

IF rec_tracciato_770.testo = 'C' THEN

      v_importo_carico_ente := 0;
      v_importo_carico_soggetto := 0; 

      /* verifico quante quote ci sono relative alla fattura */
  /*    v_numeroQuoteFattura := 0;
  		            
      SELECT count(*)
      INTO   v_numeroQuoteFattura
      FROM   siac_t_subdoc
      WHERE  doc_id= rec_tracciato_770.doc_id;
                
      IF NOT FOUND THEN
          v_numeroQuoteFattura := 0;
      END IF;*/

      FOR rec_inps IN  
      SELECT td.doc_importo IMPORTO_FATTURA,
             ts.subdoc_importo IMPORTO_QUOTA,
             rdo.importo_carico_ente,
             --totd.ord_ts_det_importo
             --rdo.importo_carico_soggetto
             rdo.doc_onere_id
      FROM  siac_t_ordinativo sto
      INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
      INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
      INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
      INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
      INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
      INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
      INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
      INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
      INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
      WHERE td.doc_id = rec_tracciato_770.doc_id
      AND   dos.ord_stato_code <> 'A'
      AND   dotdt.ord_ts_det_tipo_code = 'A'
      AND   sdot.onere_tipo_code = 'INPS'
      AND   sto.data_cancellazione IS NULL
      AND   ros.data_cancellazione IS NULL
      AND   dos.data_cancellazione IS NULL
      AND   tot.data_cancellazione IS NULL
      AND   totd.data_cancellazione IS NULL
      AND   dotdt.data_cancellazione IS NULL
      AND   rsot.data_cancellazione IS NULL
      AND   ts.data_cancellazione IS NULL
      AND   td.data_cancellazione IS NULL
      AND   rdo.data_cancellazione IS NULL
      AND   sdo.data_cancellazione IS NULL
      AND   sdot.data_cancellazione IS NULL
      AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
      AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
      AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
      AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
      AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
      AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
      AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
      AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
      AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
      AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
       
      LOOP
      
        BEGIN

          SELECT SUM(totd.ord_ts_det_importo)
          INTO   STRICT v_importo_carico_soggetto           
          FROM   siac_r_doc_onere_ordinativo_ts rdoot 
          INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
          INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
          INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
          INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
          INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
          INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
          WHERE  rdoot.doc_onere_id = rec_inps.doc_onere_id
          AND    dotdt.ord_ts_det_tipo_code = 'A'  
          AND    dos.ord_stato_code <> 'A'
          AND    rdoot.data_cancellazione IS NULL
          AND    tot.data_cancellazione IS NULL
          AND    sto.data_cancellazione IS NULL
          AND    ros.data_cancellazione IS NULL
          AND    dos.data_cancellazione IS NULL    
          AND    totd.data_cancellazione IS NULL
          AND    dotdt.data_cancellazione IS NULL
          AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
          AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
          AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
          AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
          AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
          AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
          AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

        EXCEPTION
                  
          WHEN NO_DATA_FOUND THEN
               null;
                  
        END;    
      
          --v_importo_carico_soggetto := rec_inps.importo_carico_soggetto;
          --v_importo_carico_ente := rec_inps.importo_carico_ente;
          v_percQuota := 0;    	          
                                                  
          -- calcolo la percentuale della quota corrente rispetto
          -- al totale fattura.
          v_percQuota := COALESCE(rec_inps.IMPORTO_QUOTA,0)*100/COALESCE(rec_inps.IMPORTO_FATTURA,0);                
                                                       
          --raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
          --raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
          --raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
                                
          -- la fattura e' la stessa della quota precedente.       		      
          ----IF v_idFatturaOld = rec_tracciato_770.doc_id THEN
              ----v_contaQuotaInps := v_contaQuotaInps + 1;
              --raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
              -- e' l'ultima quota della fattura:
              -- gli importi sono quelli totali meno quelli delle quote
              -- precedenti, per evitare problemi di arrotondamento.            
  /*          IF v_contaQuotaInps = v_numeroQuoteFattura THEN
              --raise notice 'ULTIMA QUOTA'; 
              v_importo_imponibile_inps := v_importo_imponibile - v_importoParzInpsImpon;
              v_importo_ritenuta_inps := v_importo_carico_soggetto - v_importoParzInpsRiten;
              v_importo_ente_inps := rec_inps.importo_carico_ente - v_importoParzInpsEnte;                                  
              -- azzero gli importi parziali per fattura
              v_importoParzInpsImpon := 0;
              v_importoParzInpsRiten := 0;
              v_importoParzInpsEnte := 0;
              v_importoParzInpsNetto := 0;
              v_contaQuotaInps := 0;      
            ELSE*/
              --raise notice 'ALTRA QUOTA';
              --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
              --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
              ----v_importo_ente_inps := rec_inps.importo_carico_ente*v_percQuota/100;
              --v_importo_netto_inps := v_importo_lordo-v_importo_ritenuta_inps;                      
              -- sommo l'importo della quota corrente
              -- al parziale per fattura.
              --v_importoParzInpsImpon := v_importoParzInpsImpon + v_importo_imponibile_inps;
              --v_importoParzInpsRiten := v_importoParzInpsRiten + v_importo_ritenuta_inps;
              ----v_importoParzInpsEnte :=  v_importoParzInpsEnte + v_importo_ente_inps;
              --v_importoParzInpsNetto := v_importoParzInpsNetto + v_importo_netto_inps;                      
            --END IF;      
          ----ELSE -- fattura diversa dalla precedente
            --raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
            --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
            v_importo_ente_inps := COALESCE(rec_inps.importo_carico_ente,0)*v_percQuota/100;
            --v_importo_netto_inps := v_importo_lordo - v_importo_ritenuta_inps;
            -- imposto l'importo della quota corrente
            -- al parziale per fattura.            
            --v_importoParzInpsImpon := v_importo_imponibile_inps;
            --v_importoParzInpsRiten := v_importo_ritenuta_inps;
            ----v_importoParzInpsEnte := v_importo_ente_inps;
            --v_importoParzInpsNetto := v_importo_netto_inps;
            ----v_contaQuotaInps := 1;            
          ----END IF;                                    
          --raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
          --raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
          ----v_idFatturaOld := rec_tracciato_770.doc_id;    
          v_importo_carico_ente :=  v_importo_carico_ente + v_importo_ente_inps;  
      END LOOP;
  
    END IF;  
           
    IF rec_tracciato_770.testo = 'F' THEN
       null;
       -- Aliquota
       -- Ritenute Operate
    END IF;
        
    IF rec_tracciato_770.testo = 'C' THEN
    
      INSERT INTO siac.tracciato_770_quadro_c_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_spedizione,
        provincia_domicilio_spedizione,
        indirizzo_domicilio_spedizione,
        cap_domicilio_spedizione,
        percipienti_esteri_cod_fiscale,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        imponibile_b,
        ritenute_titolo_acconto_b,
        ritenute_titolo_imposta_b,
        contr_prev_carico_sog_erogante,
        contr_prev_carico_sog_percipie,
        codice,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          v_comune_indirizzo_principale, 
          v_provincia_indirizzo_principale, 
          v_indirizzo_principale, 
          v_cap_indirizzo_principale,           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_importo_imponibile,
          v_ord_ts_det_importo,
          0,
          v_importo_carico_ente,
          v_importo_carico_soggetto,      
          v_codice,
          p_anno_elab,
          v_codice_tributo
        );         
    
    END IF;    
    
    IF rec_tracciato_770.testo = 'F' THEN    
    
      INSERT INTO siac.tracciato_770_quadro_f_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_fiscale,
        provincia_domicilio_fiscale,
        indirizzo_domicilio_fiscale,
        cap_domicilio_spedizione,
        codice_identif_fiscale_estero,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        aliquota,
        ritenute_operate,
        ritenute_sospese,
        rimborsi,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          COALESCE(v_comune_indirizzo_fiscale, v_comune_indirizzo_principale), 
          COALESCE(v_provincia_indirizzo_fiscale, v_provincia_indirizzo_principale), 
          COALESCE(v_indirizzo_fiscale, v_indirizzo_principale), 
          COALESCE(v_cap_indirizzo_fiscale, v_cap_indirizzo_principale),           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_aliquota,
          v_ord_ts_det_importo,
          0,
          0,    
          p_anno_elab,
          v_codice_tributo
        );         
     
    END IF;
    
  v_elab_id_det_temp := v_elab_id_det_temp + 1;
     
END LOOP;

IF p_quadro_c_f IN ('C','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_c IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_spedizione,'') from 1 for 21), 21, ' ') comune_domicilio_spedizione,
    rpad(substring(coalesce(provincia_domicilio_spedizione,'') from 1 for 2), 2, ' ') provincia_domicilio_spedizione,
    rpad(substring(coalesce(indirizzo_domicilio_spedizione,'') from 1 for 35), 35, ' ') indirizzo_domicilio_spedizione,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(percipienti_esteri_cod_fiscale,'') from 1 for 20), 20, ' ') percipienti_esteri_cod_fiscale,
    rpad(substring(coalesce(causale,'') from 1 for 2), 2, ' ') causale,
    rpad(substring(coalesce(codice,'') from 1 for 1), 1, ' ') codice,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 11, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 11, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(imponibile_b,0))*100)::bigint::varchar, 11, '0') imponibile_b,
    lpad((SUM(coalesce(ritenute_titolo_acconto_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_acconto_b,
    lpad((SUM(coalesce(ritenute_titolo_imposta_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_imposta_b,
    lpad((SUM(coalesce(contr_prev_carico_sog_erogante,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_erogante,
    lpad((SUM(coalesce(contr_prev_carico_sog_percipie,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_percipie,
    lpad(codice_tributo,4,'0') codice_tributo
  FROM tracciato_770_quadro_c_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_spedizione,
    provincia_domicilio_spedizione,
    indirizzo_domicilio_spedizione,
    cap_domicilio_spedizione,
    percipienti_esteri_cod_fiscale,
    causale,
    codice,
    anno_competenza,
    codice_tributo
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_c
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          colonna_1,
          colonna_2 ,
          comune_domicilio_fiscale_prec,
          comune_domicilio_spedizione,
          provincia_domicilio_spedizione,
          colonna_3,
          esclusione_precompilata,
          categorie_particolari,
          indirizzo_domicilio_spedizione,
          cap_domicilio_spedizione,
          colonna_4,
          codice_sede,
          comune_domicilio_fiscale,
          rappresentante_codice_fiscale,
          percipienti_esteri_no_res,
          percipienti_esteri_localita,
          percipienti_esteri_stato,
          percipienti_esteri_cod_fiscale,
          ex_causale,
          ammontare_lordo_corrisposto,
          somme_no_ritenute_regime_conv,
          altre_somme_no_ritenute,
          imponibile_b,
          ritenute_titolo_acconto_b,
          ritenute_titolo_imposta_b,
          ritenute_sospese_b,
          anticipazione,
          anno,
          add_reg_titolo_acconto_b,
          add_reg_titolo_imposta_b,
          add_reg_sospesa_b,
          imponibile_anni_prec,
          ritenute_operate_anni_prec,
          contr_prev_carico_sog_erogante,
          contr_prev_carico_sog_percipie,
          spese_rimborsate,
          ritenute_rimborsate,
          colonna_5,
          percipienti_esteri_via_numciv,
          colonna_6,
          eventi_eccezionali,
          somme_prima_data_fallimento,
          somme_curatore_commissario,
          colonna_7,
          colonna_8,
          codice,
          colonna_9,
          codice_fiscale_e,
          imponibile_e,
          ritenute_titolo_acconto_e,
          ritenute_titolo_imposta_e,
          ritenute_sospese_e,
          add_reg_titolo_acconto_e,
          add_reg_titolo_imposta_e,
          add_reg_sospesa_e,
          add_com_titolo_acconto_e,
          add_com_titolo_imposta_e,
          add_com_sospesa_e,
          add_com_titolo_acconto_b,
          add_com_titolo_imposta_b,
          add_com_sospesa_b,
          colonna_10,
          codice_fiscale_redd_diversi_f,
          codice_fiscale_pignoramento_f,
          codice_fiscale_esproprio_f,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          codice_fiscale_ente_prev,
          denominazione_ente_prev,
          codice_ente_prev,
          codice_azienda,
          categoria,
          altri_contributi,
          importo_altri_contributi,
          contributi_dovuti,
          contributi_versati,
          causale,
          colonna_24,
          colonna_25,
          colonna_26,
          colonna_27,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1,
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_c.tipo_record,
          rec_tracciato_fin_c.codice_fiscale_ente,
          rec_tracciato_fin_c.codice_fiscale_percipiente,
          rec_tracciato_fin_c.tipo_percipiente,
          rec_tracciato_fin_c.cognome_denominazione,
          rec_tracciato_fin_c.nome,
          rec_tracciato_fin_c.sesso,
          rec_tracciato_fin_c.data_nascita,
          rec_tracciato_fin_c.comune_nascita,
          rec_tracciato_fin_c.provincia_nascita,
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rec_tracciato_fin_c.comune_domicilio_spedizione,
          rec_tracciato_fin_c.provincia_domicilio_spedizione,
          rpad(' ',3,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rec_tracciato_fin_c.indirizzo_domicilio_spedizione,
          rec_tracciato_fin_c.cap_domicilio_spedizione,
          rpad(' ',57,' '),
          rpad(' ',3,' '),
          rpad(' ',4,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_c.percipienti_esteri_cod_fiscale,
          rpad(' ',1,' '),
          rec_tracciato_fin_c.ammontare_lordo_corrisposto,
          lpad('0',11,'0'),
          rec_tracciato_fin_c.altre_somme_no_ritenute,
          rec_tracciato_fin_c.imponibile_b,
          rec_tracciato_fin_c.ritenute_titolo_acconto_b,
          rec_tracciato_fin_c.ritenute_titolo_imposta_b,
          lpad('0',11,'0'),
          lpad('0',1,'0'),
          lpad('0',4,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.contr_prev_carico_sog_erogante,
          rec_tracciato_fin_c.contr_prev_carico_sog_percipie,
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',11,' '),
          rpad(' ',1,' '),        
          rec_tracciato_fin_c.codice,
          rpad(' ',9,' '),
          rpad(' ',16,' '),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',103,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',16,' '),
          rpad(' ',30,' '),
          rpad(' ',1,' '),
          rpad(' ',15,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.causale,
          rpad(' ',1044,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),          
          rpad(' ',1818,' '),
          rec_tracciato_fin_c.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_c)::varchar,7,'0'),
          rec_tracciato_fin_c.codice_tributo,
          'V12',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_c := 8000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
  
END IF;

IF p_quadro_c_f IN ('F','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_f IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_fiscale,'') from 1 for 21), 21, ' ') comune_domicilio_fiscale,
    rpad(substring(coalesce(provincia_domicilio_fiscale,'') from 1 for 2), 2, ' ') provincia_domicilio_fiscale,
    rpad(substring(coalesce(indirizzo_domicilio_fiscale,'') from 1 for 35), 35, ' ') indirizzo_domicilio_fiscale,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(codice_identif_fiscale_estero,'') from 1 for 20), 20, ' ') codice_identif_fiscale_estero,
    rpad(substring(coalesce(causale,'') from 1 for 1), 1, ' ') causale,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 13, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 13, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(ritenute_operate,0))*100)::bigint::varchar, 13, '0') ritenute_operate,
    lpad((SUM(coalesce(ritenute_sospese,0))*100)::bigint::varchar, 13, '0') ritenute_sospese,
    lpad((SUM(coalesce(rimborsi,0))*100)::bigint::varchar, 13, '0') rimborsi,
    lpad(codice_tributo,4,'0') codice_tributo,
    lpad((coalesce(aliquota,0)*100)::bigint::varchar,5,'0') aliquota
  FROM tracciato_770_quadro_f_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_fiscale,
    provincia_domicilio_fiscale,
    indirizzo_domicilio_fiscale,
    cap_domicilio_spedizione,
    codice_identif_fiscale_estero,
    causale,
    anno_competenza,
    codice_tributo,
    aliquota
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_f
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          comune_domicilio_fiscale,
          provincia_domicilio_fiscale,
          indirizzo_domicilio_fiscale,
          colonna_1,
          colonna_2,
          colonna_3,
          colonna_4,
          cap_domicilio_spedizione,
          colonna_5,
          codice_stato_estero,
          codice_identif_fiscale_estero,
          causale,
          ammontare_lordo_corrisposto,
          somme_no_soggette_ritenuta,
          aliquota,
          ritenute_operate,
          ritenute_sospese,
          codice_fiscale_rappr_soc,
          cognome_denom_rappr_soc,
          nome_rappr_soc,
          sesso_rappr_soc,
          data_nascita_rappr_soc,
          comune_nascita_rappr_soc,
          provincia_nascita_rappr_soc,
          comune_dom_fiscale_rappr_soc,
          provincia_rappr_soc,
          indirizzo_rappr_soc,
          codice_stato_estero_rappr_soc,
          rimborsi,
          colonna_6,
          colonna_7,
          colonna_8,
          colonna_9,
          colonna_10,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1, 
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_f.tipo_record,
          rec_tracciato_fin_f.codice_fiscale_ente,
          rec_tracciato_fin_f.codice_fiscale_percipiente,
          rec_tracciato_fin_f.tipo_percipiente,
          rec_tracciato_fin_f.cognome_denominazione,
          rec_tracciato_fin_f.nome,
          rec_tracciato_fin_f.sesso,
          rec_tracciato_fin_f.data_nascita,
          rec_tracciato_fin_f.comune_nascita,
          rec_tracciato_fin_f.provincia_nascita,
          rec_tracciato_fin_f.comune_domicilio_fiscale,
          rec_tracciato_fin_f.provincia_domicilio_fiscale,
          rec_tracciato_fin_f.indirizzo_domicilio_fiscale,
          rpad(' ',60,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rec_tracciato_fin_f.cap_domicilio_spedizione,
          rpad(' ',31,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.codice_identif_fiscale_estero,
          rec_tracciato_fin_f.causale,
          rec_tracciato_fin_f.ammontare_lordo_corrisposto,
          rec_tracciato_fin_f.altre_somme_no_ritenute,
          rec_tracciato_fin_f.aliquota,
          rec_tracciato_fin_f.ritenute_operate,
          rec_tracciato_fin_f.ritenute_sospese,
          rpad(' ',16,' '),
          rpad(' ',60,' '),
          rpad(' ',20,' '),
          rpad(' ',1,' '),
          lpad('0',8,'0'),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.rimborsi,
          rpad(' ',315,' '),
          rpad(' ',16,' '),       
          rpad(' ',1,' '),      
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',1143,' '),
          rpad(' ',4,' '),    
          rpad(' ',4,' '),
          rpad(' ',1818,' '),                                                                                                                                              
          rec_tracciato_fin_f.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_f)::varchar,7,'0'),
          rec_tracciato_fin_f.codice_tributo,
          'V12',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_f := 9000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
             
END IF;  

messaggioRisultato := 'OK';

-- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
UPDATE  mif_t_flusso_elaborato
SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
    (elab_mif_esito_ok,'Elaborazione conclusa [stato OK] per tipo flusso '||v_tipo_flusso, now())
WHERE flusso_elab_mif_id = v_elab_id;

RETURN messaggioRisultato;

EXCEPTION

	WHEN OTHERS  THEN
         messaggioRisultato := SUBSTRING(UPPER(SQLERRM) from 1 for 100);
         -- RETURN NEXT;
		 messaggioRisultato := UPPER(messaggioRisultato);
        
        INSERT INTO mif_t_flusso_elaborato
        (flusso_elab_mif_data,
         flusso_elab_mif_esito,
         flusso_elab_mif_esito_msg,
         flusso_elab_mif_file_nome,
         flusso_elab_mif_tipo_id,
         flusso_elab_mif_id_flusso_oil,
         validita_inizio,
         validita_fine,
         ente_proprietario_id,
         login_operazione)
         (SELECT now(),
                 elab_mif_esito_ko,
                 'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato,
                 tipo.flusso_elab_mif_nome_file,
                 tipo.flusso_elab_mif_tipo_id,
                 null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
                 now(),
                 now(),
                 p_ente_proprietario_id,
                 v_login
          FROM mif_d_flusso_elaborato_tipo tipo
          WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
          AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
          AND   tipo.data_cancellazione IS NULL
          AND   tipo.validita_fine IS NULL
         );
         
         RETURN messaggioRisultato;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
-- SIAC-5485 FINE