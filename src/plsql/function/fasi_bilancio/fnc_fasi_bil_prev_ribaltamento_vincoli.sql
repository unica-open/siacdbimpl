/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

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