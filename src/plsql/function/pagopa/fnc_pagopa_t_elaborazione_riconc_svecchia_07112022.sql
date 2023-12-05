/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

DROP FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc_svecchia
(enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT svecchiapagopaelabid integer, OUT codicerisultato integer, OUT messaggiorisultato character varying);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_svecchia(enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT svecchiapagopaelabid integer, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE

	strMessaggio VARCHAR(2500):='';
    strMessaggioBck  VARCHAR(2500):='';
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';


    pagoPaRec record;


	codResult integer:=null;
    countDel  integer:=null;
    
    altri_record integer:=null;
   
    pagopaElabSvecchiaId integer:=null;

    nCountoRecordPrima integer:=null;
    nCountoRecordDopo integer:=null;

    pagopaElabSvecchiaTipoflagAttivo boolean:=null;
    pagopaElabSvecchiaTipoflagBack boolean:=null;
    pagopaElabSvecchiaTipoDeltaGG  integer:=null;
	dataSvecchia timestamp:=null;
    dataSvecchiaSqlQuery varchar(200):=null;

	SVECCHIA_CODE_PERIODICO CONSTANT  varchar :='PERIODICO';
BEGIN

   codiceRisultato:=0;
   messaggioRisultato:='';
   svecchiaPagoPaElabId:=null;


   strMessaggioFinale:='Elaborazione svecchiamento '||SVECCHIA_CODE_PERIODICO||' rinconciliazione PAGOPA.';

   strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_svecchia - '||strMessaggioFinale;
  
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;

   

   strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PERIODICO||'].';
   select tipo.pagopa_elab_svecchia_tipo_fl_attivo, tipo.pagopa_elab_svecchia_tipo_fl_back, coalesce(tipo.pagopa_elab_svecchia_delta_giorni,0)
   into   pagopaElabSvecchiaTipoflagAttivo,pagopaElabSvecchiaTipoflagBack,pagopaElabSvecchiaTipoDeltaGG
   from pagopa_d_elaborazione_svecchia_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PERIODICO;
   if pagopaElabSvecchiaTipoflagAttivo is null or pagopaElabSvecchiaTipoflagBack is null then
    	codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
   end if;

   if pagopaElabSvecchiaTipoflagAttivo=false then
    	messaggioRisultato:=strMessaggio||' Tipo svecchiamento non attivo.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;

   if   pagopaElabSvecchiaTipoDeltaGG<=0 then
	    messaggioRisultato:=strMessaggio||' Delta day di svecchiamento non impostato correttamente.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;

   strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PERIODICO||']. Calcolo data di svecchiamento.';
   dataSvecchiaSqlQuery:='select date_trunc(''DAY'','''||dataElaborazione||'''::timestamp)- interval '''||pagopaElabSvecchiaTipoDeltaGG||' day'' ';
   raise notice 'dataSvecchiaSqlQuery=%',dataSvecchiaSqlQuery;
   execute dataSvecchiaSqlQuery into dataSvecchia;
   if dataSvecchia is null then
   		messaggioRisultato:=strMessaggio||' Errore in calcolo.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;

   strMessaggioFinale:='Elaborazione svecchiamento periodico rinconciliazione PAGOPA per '||
                       ' dataSvecchia='||to_char(dataSvecchia,'dd/mm/yyyy')||'.';
   raise notice 'dataSvecchia=%',dataSvecchia;

   strMessaggio:='Inserimento elaborazione id svecchiamento [pagopa_t_elaborazione_svecchia].';
   insert into pagopa_t_elaborazione_svecchia
   (
	    pagopa_elab_svecchia_data,
	    pagopa_elab_svecchia_note,
	    pagopa_elab_svecchia_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
   )
   select
       clock_timestamp(),
       upper('INIZIO '||tipo.pagopa_elab_svecchia_tipo_desc||'. Data svecchiamento='||to_char(dataSvecchia,'dd/mm/yyyy')||'.'),
       tipo.pagopa_elab_svecchia_tipo_id,
       clock_timestamp(),
       loginOperazione,
       tipo.ente_proprietario_id
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PERIODICO
    returning pagopa_elab_svecchia_id into pagopaElabSvecchiaId;
    if pagopaElabSvecchiaId is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in inserimento.'||strMessaggioFinale;
        return;
    end if;
    raise notice '---------- ELEABORAZIONE IN CORSO --------------';

countDel:=0;


--pagopa_t_elaborazione (A) 
      if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
        strMessaggio:='Backup  pagopa_t_elaborazione.';
	    raise notice 'strMessaggio= backup pagopa_t_elaborazione - ';
        codResult:=0;   
insert into pagopa_t_bck_elaborazione
            (
              pagopa_elab_svecchia_id,
              pagopa_elab_id,
              pagopa_elab_data,
              pagopa_elab_stato_id,
              pagopa_elab_note,
              pagopa_elab_file_id,
              pagopa_elab_file_ora,
              pagopa_elab_file_ente,
              pagopa_elab_file_fruitore,
              file_pagopa_id,
              pagopa_elab_errore_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              elab.pagopa_elab_id,
              elab.pagopa_elab_data,
              elab.pagopa_elab_stato_id,
              elab.pagopa_elab_note,
              elab.pagopa_elab_file_id,
              elab.pagopa_elab_file_ora,
              elab.pagopa_elab_file_ente,
              elab.pagopa_elab_file_fruitore,
              elab.file_pagopa_id,
              elab.pagopa_elab_errore_id,
              elab.validita_inizio,
              elab.validita_fine,
              elab.data_creazione,
              elab.data_modifica,
              elab.data_cancellazione,
              elab.login_operazione,
              clock_timestamp(),
              loginOperazione,
              elab.ente_proprietario_id            
     from pagopa_t_elaborazione elab, 
          pagopa_d_elaborazione_stato stato
     where stato.ente_proprietario_id=enteproprietarioid
       and stato.pagopa_elab_stato_code='ELABORATO_OK'
       and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
       and elab.pagopa_elab_data < dataSvecchia::timestamp;
        --returning pagopa_bck_elab_id into codResult;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;




--	pagopa_t_elaborazione_flusso (B)   
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_elaborazione_flusso.';
	  raise notice 'strMessaggio= backup pagopa_t_elaborazione_flusso - ';
      codResult:=0;   
      insert into pagopa_t_bck_elaborazione_flusso
            (
              pagopa_elab_svecchia_id,
              pagopa_elab_flusso_id,
              pagopa_elab_flusso_data,
              pagopa_elab_flusso_stato_id,
              pagopa_elab_flusso_note,
              pagopa_elab_ric_flusso_id,
              pagopa_elab_flusso_nome_mittente,
              pagopa_elab_ric_flusso_data,
              pagopa_elab_flusso_tot_pagam,
              pagopa_elab_flusso_anno_esercizio,
              pagopa_elab_flusso_anno_provvisorio,
              pagopa_elab_flusso_num_provvisorio,
              pagopa_elab_flusso_provc_id,
              pagopa_elab_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              fl.pagopa_elab_flusso_id,
              fl.pagopa_elab_flusso_data,
              fl.pagopa_elab_flusso_stato_id,
              fl.pagopa_elab_flusso_note,
              fl.pagopa_elab_ric_flusso_id,
              fl.pagopa_elab_flusso_nome_mittente,
              fl.pagopa_elab_ric_flusso_data,
              fl.pagopa_elab_flusso_tot_pagam,
              fl.pagopa_elab_flusso_anno_esercizio,
              fl.pagopa_elab_flusso_anno_provvisorio,
              fl.pagopa_elab_flusso_num_provvisorio,
              fl.pagopa_elab_flusso_provc_id,
              fl.pagopa_elab_id,
              fl.validita_inizio,
              fl.validita_fine,
              fl.data_creazione,
              fl.data_modifica,
              fl.data_cancellazione,
              fl.login_operazione,
              clock_timestamp(),
              loginOperazione,
              fl.ente_proprietario_id
        from pagopa_t_elaborazione elab, 
             pagopa_d_elaborazione_stato stato,
             pagopa_t_elaborazione_flusso fl
        where stato.ente_proprietario_id=enteproprietarioid
          and stato.pagopa_elab_stato_code='ELABORATO_OK'
          and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
          and elab.pagopa_elab_data < dataSvecchia::timestamp
          and elab.pagopa_elab_id = fl.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;





--	pagopa_t_riconciliazione_doc  (C) 
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_riconciliazione_doc.';
	  raise notice 'strMessaggio= backup pagopa_t_riconciliazione_doc - ';
      codResult:=0;   
insert into pagopa_t_bck_riconciliazione_doc
        (
          pagopa_elab_svecchia_id,
          pagopa_ric_doc_id,
          pagopa_ric_doc_data,
          pagopa_ric_doc_voce_code,
          pagopa_ric_doc_voce_desc,
          pagopa_ric_doc_voce_tematica,
          pagopa_ric_doc_sottovoce_code,
          pagopa_ric_doc_sottovoce_desc,
          pagopa_ric_doc_sottovoce_importo,
          pagopa_ric_doc_anno_esercizio,
          pagopa_ric_doc_anno_accertamento,
          pagopa_ric_doc_num_accertamento,
          pagopa_ric_doc_num_capitolo,
          pagopa_ric_doc_num_articolo,
          pagopa_ric_doc_pdc_v_fin,
          pagopa_ric_doc_titolo,
          pagopa_ric_doc_tipologia,
          pagopa_ric_doc_categoria,
          pagopa_ric_doc_codice_benef,
          pagopa_ric_doc_str_amm,
          pagopa_ric_doc_subdoc_id,
          pagopa_ric_doc_provc_id,
          pagopa_ric_doc_movgest_ts_id,
          pagopa_ric_doc_stato_elab,
          pagopa_ric_errore_id,
          pagopa_ric_id,
          pagopa_elab_flusso_id,
          file_pagopa_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          pagopa_ric_doc_ragsoc_benef,
          pagopa_ric_doc_nome_benef,
          pagopa_ric_doc_cognome_benef,
          pagopa_ric_doc_codfisc_benef,
          pagopa_ric_doc_soggetto_id,
          pagopa_ric_doc_flag_dett,
          pagopa_ric_doc_flag_con_dett,
          pagopa_ric_doc_tipo_code,
          pagopa_ric_doc_tipo_id,
          pagopa_ric_det_id,
          pagopa_ric_doc_iuv,
          pagopa_ric_doc_data_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        select
          pagopaElabSvecchiaId,
          ric_doc.pagopa_ric_doc_id,
          ric_doc.pagopa_ric_doc_data,
          ric_doc.pagopa_ric_doc_voce_code,
          ric_doc.pagopa_ric_doc_voce_desc,
          ric_doc.pagopa_ric_doc_voce_tematica,
          ric_doc.pagopa_ric_doc_sottovoce_code,
          ric_doc.pagopa_ric_doc_sottovoce_desc,
          ric_doc.pagopa_ric_doc_sottovoce_importo,
          ric_doc.pagopa_ric_doc_anno_esercizio,
          ric_doc.pagopa_ric_doc_anno_accertamento,
          ric_doc.pagopa_ric_doc_num_accertamento,
          ric_doc.pagopa_ric_doc_num_capitolo,
          ric_doc.pagopa_ric_doc_num_articolo,
          ric_doc.pagopa_ric_doc_pdc_v_fin,
          ric_doc.pagopa_ric_doc_titolo,
          ric_doc.pagopa_ric_doc_tipologia,
          ric_doc.pagopa_ric_doc_categoria,
          ric_doc.pagopa_ric_doc_codice_benef,
          ric_doc.pagopa_ric_doc_str_amm,
          ric_doc.pagopa_ric_doc_subdoc_id,
          ric_doc.pagopa_ric_doc_provc_id,
          ric_doc.pagopa_ric_doc_movgest_ts_id,
          ric_doc.pagopa_ric_doc_stato_elab,
          ric_doc.pagopa_ric_errore_id,
          ric_doc.pagopa_ric_id,
          ric_doc.pagopa_elab_flusso_id,
          ric_doc.file_pagopa_id,
          ric_doc.validita_inizio,
          ric_doc.validita_fine,
          ric_doc.data_creazione,
          ric_doc.data_modifica,
          ric_doc.data_cancellazione,
          ric_doc.login_operazione,
          ric_doc.pagopa_ric_doc_ragsoc_benef,
          ric_doc.pagopa_ric_doc_nome_benef,
          ric_doc.pagopa_ric_doc_cognome_benef,
          ric_doc.pagopa_ric_doc_codfisc_benef,
          ric_doc.pagopa_ric_doc_soggetto_id,
          ric_doc.pagopa_ric_doc_flag_dett,
          ric_doc.pagopa_ric_doc_flag_con_dett,
          ric_doc.pagopa_ric_doc_tipo_code,
          ric_doc.pagopa_ric_doc_tipo_id,
          ric_doc.pagopa_ric_det_id,
          ric_doc.pagopa_ric_doc_iuv,
          ric_doc.pagopa_ric_doc_data_operazione,
          clock_timestamp(),
          loginOperazione,
          ric_doc.ente_proprietario_id          
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_t_elaborazione_flusso fl,
			 pagopa_t_riconciliazione ric,
			 pagopa_t_riconciliazione_doc ric_doc
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = fl.pagopa_elab_id
		  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
		  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
		  and ric_doc.pagopa_ric_doc_stato_elab='S'
		  and (ric_doc.pagopa_ric_doc_flag_con_dett=false  or ric_doc.pagopa_ric_doc_flag_dett=true);
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;
  
  



--	pagopa_r_elaborazione_file     (D)  
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_r_elaborazione_file.';
	  raise notice 'strMessaggio= backup pagopa_r_elaborazione_file - ';
      codResult:=0;   
insert into pagopa_r_bck_elaborazione_file
            (
              pagopa_elab_svecchia_id,
              pagopa_r_elab_id,
              pagopa_elab_id,
              file_pagopa_id,
              bck_validita_inizio,
              bck_validita_fine,
              bck_data_creazione,
              bck_data_modifica,
              bck_data_cancellazione,
              bck_login_operazione,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
            )
            select
              pagopaElabSvecchiaId,
              rf.pagopa_r_elab_id,
              rf.pagopa_elab_id,
              rf.file_pagopa_id,
              rf.validita_inizio,
              rf.validita_fine,
              rf.data_creazione,
              rf.data_modifica,
              rf.data_cancellazione,
              rf.login_operazione,
              clock_timestamp(),
              loginOperazione,
              rf.ente_proprietario_id              
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;



--	siac_t_file_pagopa   (E)  
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  siac_t_file_pagopa.';
	  raise notice 'strMessaggio= backup siac_t_file_pagopa - ';
      codResult:=0;   
		insert into siac_t_bck_file_pagopa (
			pagopa_elab_svecchia_id,
			file_pagopa_id,
			file_pagopa_size,
			file_pagopa,
			file_pagopa_code,
			file_pagopa_note,
			file_pagopa_anno,
			file_pagopa_stato_id,
			file_pagopa_errore_id,
			validita_inizio,
			validita_fine,
			ente_proprietario_id,
			data_creazione,
			data_modifica,
			data_cancellazione,
			login_operazione,
			file_pagopa_id_psp,
			file_pagopa_id_flusso
		   )	
		 select 
			pagopaElabSvecchiaId,
			file.file_pagopa_id,
			file.file_pagopa_size,
			file.file_pagopa,
			file.file_pagopa_code,
			file.file_pagopa_note,
			file.file_pagopa_anno,
			file.file_pagopa_stato_id,
			file.file_pagopa_errore_id,
			file.validita_inizio,
			file.validita_fine,
			file.ente_proprietario_id,
			file.data_creazione,
			file.data_modifica,
			file.data_cancellazione,
			file.login_operazione,
			file.file_pagopa_id_psp,
			file.file_pagopa_id_flusso 
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf,
			 siac_t_file_pagopa file
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id
		  and rf.file_pagopa_id = file.file_pagopa_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;




--	pagopa_t_riconciliazione   (F)  
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_riconciliazione.';
	  raise notice 'strMessaggio= backup pagopa_t_riconciliazione - ';
      codResult:=0;   
     insert into pagopa_t_bck_riconciliazione (
			pagopa_elab_svecchia_id,
			pagopa_ric_id,
			pagopa_ric_data,
			pagopa_ric_file_id,
			pagopa_ric_file_ora,
			pagopa_ric_file_ente,
			pagopa_ric_file_fruitore,
			pagopa_ric_file_num_flussi,
			pagopa_ric_file_tot_flussi,
			pagopa_ric_flusso_id,
			pagopa_ric_flusso_nome_mittente,
			pagopa_ric_flusso_data,
			pagopa_ric_flusso_tot_pagam,
			pagopa_ric_flusso_anno_esercizio,
			pagopa_ric_flusso_anno_provvisorio,
			pagopa_ric_flusso_num_provvisorio,
			pagopa_ric_flusso_voce_code,
			pagopa_ric_flusso_voce_desc,
			pagopa_ric_flusso_tematica,
			pagopa_ric_flusso_sottovoce_code,
			pagopa_ric_flusso_sottovoce_desc,
			pagopa_ric_flusso_sottovoce_importo,
			pagopa_ric_flusso_anno_accertamento,
			pagopa_ric_flusso_num_accertamento,
			pagopa_ric_flusso_num_capitolo,
			pagopa_ric_flusso_num_articolo,
			pagopa_ric_flusso_pdc_v_fin,
			pagopa_ric_flusso_titolo,
			pagopa_ric_flusso_tipologia,
			pagopa_ric_flusso_categoria,
			pagopa_ric_flusso_codice_benef,
			pagopa_ric_flusso_str_amm,
			file_pagopa_id,
			pagopa_ric_flusso_stato_elab,
			pagopa_ric_errore_id,
			validita_inizio,
			validita_fine,
			ente_proprietario_id,
			data_creazione,
			data_modifica,
			data_cancellazione,
			login_operazione,
			pagopa_ric_flusso_ragsoc_benef,
			pagopa_ric_flusso_nome_benef,
			pagopa_ric_flusso_cognome_benef,
			pagopa_ric_flusso_codfisc_benef
			)
		select 
			pagopaElabSvecchiaId,
			ric.pagopa_ric_id,
			ric.pagopa_ric_data,
			ric.pagopa_ric_file_id,
			ric.pagopa_ric_file_ora,
			ric.pagopa_ric_file_ente,
			ric.pagopa_ric_file_fruitore,
			ric.pagopa_ric_file_num_flussi,
			ric.pagopa_ric_file_tot_flussi,
			ric.pagopa_ric_flusso_id,
			ric.pagopa_ric_flusso_nome_mittente,
			ric.pagopa_ric_flusso_data,
			ric.pagopa_ric_flusso_tot_pagam,
			ric.pagopa_ric_flusso_anno_esercizio,
			ric.pagopa_ric_flusso_anno_provvisorio,
			ric.pagopa_ric_flusso_num_provvisorio,
			ric.pagopa_ric_flusso_voce_code,
			ric.pagopa_ric_flusso_voce_desc,
			ric.pagopa_ric_flusso_tematica,
			ric.pagopa_ric_flusso_sottovoce_code,
			ric.pagopa_ric_flusso_sottovoce_desc,
			ric.pagopa_ric_flusso_sottovoce_importo,
			ric.pagopa_ric_flusso_anno_accertamento,
			ric.pagopa_ric_flusso_num_accertamento,
			ric.pagopa_ric_flusso_num_capitolo,
			ric.pagopa_ric_flusso_num_articolo,
			ric.pagopa_ric_flusso_pdc_v_fin,
			ric.pagopa_ric_flusso_titolo,
			ric.pagopa_ric_flusso_tipologia,
			ric.pagopa_ric_flusso_categoria,
			ric.pagopa_ric_flusso_codice_benef,
			ric.pagopa_ric_flusso_str_amm,
			ric.file_pagopa_id,
			ric.pagopa_ric_flusso_stato_elab,
			ric.pagopa_ric_errore_id,
			ric.validita_inizio,
			ric.validita_fine,
			ric.ente_proprietario_id,
			ric.data_creazione,
			ric.data_modifica,
			ric.data_cancellazione,
			ric.login_operazione,
			ric.pagopa_ric_flusso_ragsoc_benef,
			ric.pagopa_ric_flusso_nome_benef,
			ric.pagopa_ric_flusso_cognome_benef,
			ric.pagopa_ric_flusso_codfisc_benef 
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf,
			 pagopa_t_riconciliazione ric
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id
		  and rf.file_pagopa_id = ric.file_pagopa_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;






--	pagopa_t_riconciliazione_det  (G) 
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_riconciliazione_det.';
	  raise notice 'strMessaggio= backup pagopa_t_riconciliazione_det - ';
      codResult:=0;   
      insert into pagopa_t_bck_riconciliazione_det (
			pagopa_elab_svecchia_id,
			pagopa_ric_det_id,
			pagopa_det_anag_cognome,
			pagopa_det_anag_nome,
			pagopa_det_anag_ragione_sociale,
			pagopa_det_anag_codice_fiscale,
			pagopa_det_anag_indirizzo,
			pagopa_det_anag_civico,
			pagopa_det_anag_cap,
			pagopa_det_anag_localita,
			pagopa_det_anag_provincia,
			pagopa_det_anag_nazione,
			pagopa_det_anag_email,
			pagopa_det_causale_versamento_desc,
			pagopa_det_causale,
			pagopa_det_data_pagamento,
			pagopa_det_esito_pagamento,
			pagopa_det_importo_versamento,
			pagopa_det_indice_versamento,
			pagopa_det_transaction_id,
			pagopa_det_versamento_id,
			pagopa_det_riscossione_id,
			pagopa_ric_id,
			validita_inizio,
			validita_fine,
			ente_proprietario_id,
			data_creazione,
			data_modifica,
			data_cancellazione,
			login_operazione
			)
		select 
			pagopaElabSvecchiaId,
			det.pagopa_ric_det_id,
			det.pagopa_det_anag_cognome,
			det.pagopa_det_anag_nome,
			det.pagopa_det_anag_ragione_sociale,
			det.pagopa_det_anag_codice_fiscale,
			det.pagopa_det_anag_indirizzo,
			det.pagopa_det_anag_civico,
			det.pagopa_det_anag_cap,
			det.pagopa_det_anag_localita,
			det.pagopa_det_anag_provincia,
			det.pagopa_det_anag_nazione,
			det.pagopa_det_anag_email,
			det.pagopa_det_causale_versamento_desc,
			det.pagopa_det_causale,
			det.pagopa_det_data_pagamento,
			det.pagopa_det_esito_pagamento,
			det.pagopa_det_importo_versamento,
			det.pagopa_det_indice_versamento,
			det.pagopa_det_transaction_id,
			det.pagopa_det_versamento_id,
			det.pagopa_det_riscossione_id,
			det.pagopa_ric_id,
			det.validita_inizio,
			det.validita_fine,
			det.ente_proprietario_id,
			det.data_creazione,
			det.data_modifica,
			det.data_cancellazione,
			det.login_operazione
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_r_elaborazione_file rf,
			 pagopa_t_riconciliazione ric,
			 pagopa_t_riconciliazione_det det
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = rf.pagopa_elab_id
		  and rf.file_pagopa_id = ric.file_pagopa_id
		  and ric.pagopa_ric_id = det.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;


  --	pagopa_t_elaborazione_log    (I) 
   if pagopaElabSvecchiaId is not null and pagopaElabSvecchiaTipoflagBack=true then
      strMessaggio:='Backup  pagopa_t_elaborazione_log.';
	  raise notice 'strMessaggio= backup pagopa_t_elaborazione_log - ';
      codResult:=0;   
      insert into pagopa_t_bck_elaborazione_log (
			pagopa_elab_svecchia_id,
			pagopa_elab_log_id,
			pagopa_elab_id,
			pagopa_elab_file_id,
			pagopa_elab_log_operazione,
			data_creazione,
			ente_proprietario_id,
			login_operazione
			)
		select 
			pagopaElabSvecchiaId,
			lg.pagopa_elab_log_id,
			lg.pagopa_elab_id,
			lg.pagopa_elab_file_id,
			lg.pagopa_elab_log_operazione,
			lg.data_creazione,
			lg.ente_proprietario_id,
			lg.login_operazione
		from pagopa_t_elaborazione elab, 
			 pagopa_d_elaborazione_stato stato,
			 pagopa_t_elaborazione_log lg
		where stato.ente_proprietario_id=enteproprietarioid
		  and stato.pagopa_elab_stato_code='ELABORATO_OK'
		  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
		  and elab.pagopa_elab_data < dataSvecchia::timestamp
		  and elab.pagopa_elab_id = lg.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        raise notice ' ';
   end if;



 raise notice '---------- INIZIO FASE CANCELLAZIONE --------------';
    
countDel:=0;

  --	pagopa_bck_t_registrounico_doc    (L12) 
strMessaggio:='Cancellazione pagopa_bck_t_registrounico_doc.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_registrounico_doc - ';
codResult:=0;
delete from pagopa_bck_t_registrounico_doc reg
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
 and stato.pagopa_elab_stato_code='ELABORATO_OK'
 and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
 and elab.pagopa_elab_data < dataSvecchia::timestamp
 and elab.pagopa_elab_id = reg.pagopa_elab_id;
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice 'cancellati=%',codResult;
 countDel:=countDel+codResult;
 
   
   
   

  
 --	pagopa_bck_t_doc_class    (L11) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_class.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_class - ';
codResult:=0;
delete from pagopa_bck_t_doc_class cl
using pagopa_t_elaborazione elab, 
     pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = cl.pagopa_elab_id;   
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  

  --	pagopa_bck_t_doc_attr    (L10) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_attr.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_attr - ';
codResult:=0;
delete from pagopa_bck_t_doc_attr attr
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = attr.pagopa_elab_id; 
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
  

 

  --	pagopa_bck_t_doc_sog    (L9) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_sog.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_sog - ';
codResult:=0;
delete from pagopa_bck_t_doc_sog sog
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = sog.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;


 
 

  --	pagopa_bck_t_subdoc_num    (L8) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_num.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_num - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_num num
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = num.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  
  

  --	pagopa_bck_t_doc_stato    (L7) 
strMessaggio:='Cancellazione pagopa_bck_t_doc_stato.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc_stato - ';
codResult:=0;
delete from pagopa_bck_t_doc_stato stdoc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = stdoc.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  

  --	pagopa_bck_t_doc    (L6) 
strMessaggio:='Cancellazione pagopa_bck_t_doc.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_doc - ';
codResult:=0;
delete from  pagopa_bck_t_doc doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = doc.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 

  --	pagopa_bck_t_subdoc_movgest_ts    (L5) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_movgest_ts.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_movgest_ts - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_movgest_ts ts
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = ts.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
   
 
  --	pagopa_bck_t_subdoc_prov_cassa    (L4) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_prov_cassa.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_prov_cassa - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_prov_cassa prov
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = prov.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
  --	pagopa_bck_t_subdoc_atto_amm    (L3) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_atto_amm.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_atto_amm - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_atto_amm amm
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = amm.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;

 
 
  --	pagopa_bck_t_subdoc_attr    (L2) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc_attr.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc_attr - ';
codResult:=0;
delete from pagopa_bck_t_subdoc_attr attr
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = attr.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
  --	pagopa_bck_t_subdoc    (L1) 
strMessaggio:='Cancellazione pagopa_bck_t_subdoc.';
raise notice 'strMessaggio= cancellazione pagopa_bck_t_subdoc - ';
codResult:=0;
delete from pagopa_bck_t_subdoc sub
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = sub.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  
 
  
  --	pagopa_t_elaborazione_log    (I) 
strMessaggio:='Cancellazione pagopa_t_elaborazione_log.';
raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione_log - ';
codResult:=0;
delete from pagopa_t_elaborazione_log lg 
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = lg.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;

  
--	pagopa_t_riconciliazione_det  (G) 
strMessaggio:='Cancellazione pagopa_t_riconciliazione_det.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_det - ';
codResult:=0;
delete from pagopa_t_riconciliazione_det det
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_r_elaborazione_file rf,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id
  and rf.file_pagopa_id = ric.file_pagopa_id
  and ric.pagopa_ric_id = det.pagopa_ric_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
--	pagopa_t_riconciliazione_doc   (C)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl--,
    --  pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id;
 --and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
 -- and ric_doc.pagopa_ric_doc_stato_elab='S' 
 -- and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 
--	pagopa_t_riconciliazione_doc   (C)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc. eventuali elborazioni precedenti andate male';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  and ric_doc.pagopa_ric_doc_stato_elab != 'S' 
  and ric_doc.pagopa_ric_doc_flag_con_dett=false 
  and  ric_doc.pagopa_ric_doc_flag_dett=true;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 

 
--	pagopa_t_riconciliazione           (F)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione - ';
codResult:=0;
delete from pagopa_t_riconciliazione ric
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_r_elaborazione_file rf,
      pagopa_t_riconciliazione_doc ric_doc
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data <  dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id
  and rf.file_pagopa_id = ric.file_pagopa_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  and ric_doc.pagopa_ric_doc_stato_elab='S'
  and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
      


 
--	pagopa_t_elaborazione_flusso (B)   
strMessaggio:='Cancellazione pagopa_t_elaborazione_flusso.';
raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione_flusso (B) - ';
codResult:=0;
delete from pagopa_t_elaborazione_flusso fl
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
      --,      
      --pagopa_t_riconciliazione_doc ric_doc,
      --pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id;
  --and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  --and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  --and ric_doc.pagopa_ric_doc_stato_elab='S' 
  --and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  
 
 
--	pagopa_r_elaborazione_file     (D)  
strMessaggio:='Cancellazione pagopa_r_elaborazione_file.';
raise notice 'strMessaggio= cancellazione pagopa_r_elaborazione_file - ';
codResult:=0;
delete from pagopa_r_elaborazione_file rf
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id ;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 


--	siac_t_file_pagopa   (E)  
strMessaggio:='Cancellazione siac_t_file_pagopa.';
raise notice 'strMessaggio= cancellazione siac_t_file_pagopa - ';
codResult:=0;
delete from siac_t_file_pagopa file
using pagopa_t_elaborazione elab, 
     pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file rf
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = rf.pagopa_elab_id
  and rf.file_pagopa_id = file.file_pagopa_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 

--	pagopa_t_riconciliazione_doc   (H)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc (H)- ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=2
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
  and ric_doc.pagopa_ric_doc_stato_elab='S' 
  and (ric_doc.pagopa_ric_doc_flag_con_dett=false or ric_doc.pagopa_ric_doc_flag_dett=true);    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult; 
 

--	pagopa_t_riconciliazione_doc   (H)  
strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc - ';
codResult:=0;
delete from pagopa_t_riconciliazione_doc ric_doc
using pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl,
      pagopa_t_riconciliazione ric
where stato.ente_proprietario_id=2
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and fl.pagopa_elab_flusso_id = ric_doc.pagopa_elab_flusso_id
  and ric.pagopa_ric_id = ric_doc.pagopa_ric_id
--  and ric_doc.pagopa_ric_doc_stato_elab='S'
  and ric_doc.pagopa_ric_doc_flag_con_dett=true   
  and ric_doc.pagopa_ric_doc_flag_dett=false;    
 GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult; 
 
 
 
 select count(*) into altri_record 
 from pagopa_t_elaborazione elab, 
      pagopa_d_elaborazione_stato stato,
      pagopa_t_elaborazione_flusso fl
 where stato.ente_proprietario_id=2
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id;
  raise notice 'altri_record=%',altri_record;

 if altri_record = 0 then
 --	pagopa_r_elaborazione_file   
strMessaggio:='Cancellazione pagopa_r_elaborazione_file.';
raise notice 'strMessaggio= cancellazione pagopa_r_elaborazione_file - ';
codResult:=0;
delete from pagopa_r_elaborazione_file rf
using pagopa_t_elaborazione elab, 
      pagopa_t_elaborazione_flusso fl,
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and elab.pagopa_elab_id = fl.pagopa_elab_id
  and rf.pagopa_elab_id = fl.pagopa_elab_id;
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'pagopa_r_elaborazione_file cancellati=%',codResult;
  countDel:=countDel+codResult;
 

 end if;
 
 
 
--	pagopa_t_modifica_elab    
strMessaggio:='Cancellazione pagopa_t_modifica_elab.';
raise notice 'strMessaggio= cancellazione pagopa_t_modifica_elab - ';
codResult:=0;
delete from pagopa_t_modifica_elab modif
using pagopa_t_elaborazione elab,
      pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp
  and modif.pagopa_elab_id = elab.pagopa_elab_id;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 
 
--	pagopa_t_elaborazione (A)   
strMessaggio:='Cancellazione pagopa_t_elaborazione.';
raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione - ';
codResult:=0;
delete from pagopa_t_elaborazione elab
using pagopa_d_elaborazione_stato stato
where stato.ente_proprietario_id=enteproprietarioid
  and stato.pagopa_elab_stato_code='ELABORATO_OK'
  and elab.pagopa_elab_stato_id=stato.pagopa_elab_Stato_id
  and elab.pagopa_elab_data < dataSvecchia::timestamp;    
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 
 
 
 
 

 raise notice 'countDel=%',countDel;


 
 
   codResult:=null;
   strMessaggio:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia - '
                  ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                  ||' Chiusura elaborazione [pagopa_t_elaborazione_svecchia].';
    raise notice 'strMessaggio=%',strMessaggio;
    update pagopa_t_elaborazione_svecchia elab
    set    data_modifica=clock_timestamp(),
           validita_fine=clock_timestamp(),
           pagopa_elab_svecchia_note=
           upper('FINE '||tipo.pagopa_elab_svecchia_tipo_desc||'. Data svecchiamento='||to_char(dataSvecchia,'dd/mm/yyyy')||'.'
           ||' Cancellati complessivamente '||coalesce(countDel,0)::varchar||' pagopa_t_riconciliazione_doc.')
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PERIODICO
    and   elab.pagopa_elab_svecchia_id=pagopaElabSvecchiaId
    returning pagopa_elab_svecchia_id into codResult;
    if codResult is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in aggiornamento.'||strMessaggioFinale;
        return;
    end if;
   raise notice '---------- ELABORAZIONE TERMINATA --------------';

  

    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia - '
                          ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                          ||strMessaggioFinale;
    raise notice '%',strMessaggioLog;
    codResult:=null;
    insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;  
  
  
   svecchiaPagoPaElabId:=pagopaElabSvecchiaId;
   messaggioRisultato:=strMessaggioFinale;
   return;

  exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
   		svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	return;
END;
$function$
;


alter function
siac.fnc_pagopa_t_elaborazione_riconc_svecchia
(integer, character varying, timestamp without time zone, OUT integer, OUT integer, OUT  character varying) OWNER to siac;