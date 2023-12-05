/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc_svecchia_okerr
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out svecchiaPagoPaElabId        integer,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_svecchia_okerr
(
  filePagoPaElabId                          integer,
  annoBilancioElab                         integer,
  enteProprietarioId                       integer,
  loginOperazione                           varchar,
  dataElaborazione                         timestamp,
  out svecchiaPagoPaElabId      integer,
  out codicerisultato                     integer,
  out messaggiorisultato             varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
	codResult integer:=null;
    countDel  integer:=0;

    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

    SVECCHIA_CODE_PUNTUALE CONSTANT  varchar :='PUNTUALE-OK';

    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;


    annoBilancio integer:=null;



    fncRec record;
    pagoPaRec record;
	pagopaElabSvecchiaId integer :=null;
    pagopaElabSvecchiaTipoflagAttivo boolean:=false;
    pagopaElabSvecchiaTipoflagBack boolean:=false;
    pagopaElabSvecchiaMesi integer:=null;
   	dataSvecchia timestamp:=null;
    dataSvecchiaSqlQuery varchar(200):=null;

BEGIN
	strMessaggioFinale:='Elaborazione svecchiamento puntuale okerr rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';
    strMessaggio:='Inserimento pagopa_t_elaborazione_log.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggioFinale;
    raise notice '%',strMessaggioLog;

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
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;

    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';
    svecchiaPagoPaElabId:=null;



    strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PUNTUALE||'].';
    select tipo.pagopa_elab_svecchia_tipo_fl_attivo, tipo.pagopa_elab_svecchia_tipo_fl_back,coalesce(tipo.pagopa_elab_svecchia_delta_giorni ,0)
    into   pagopaElabSvecchiaTipoflagAttivo,pagopaElabSvecchiaTipoflagBack, pagopaElabSvecchiaMesi
	from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE;
   
    if pagopaElabSvecchiaTipoflagAttivo is null or pagopaElabSvecchiaTipoflagBack is null  then
    	codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
    end if;
    if pagopaElabSvecchiaTipoflagAttivo=false then
    	messaggioRisultato:=strMessaggio||' Tipo svecchiamento non attivo.'||strMessaggioFinale;
        return;
    end if;
   
   raise notice 'pagopaElabSvecchiaTipoflagAttivo=%',pagopaElabSvecchiaTipoflagAttivo::varchar;
   raise notice 'pagopaElabSvecchiaTipoflagBack=%',pagopaElabSvecchiaTipoflagBack::varchar;
   raise notice 'pagopaElabSvecchiaMesi=%',pagopaElabSvecchiaMesi::varchar;
  
/*    if filePagoPaElabId is not null and filePagoPaElabId!=0 then 
	    strMessaggio:='Verifica esistenza dati da svecchiare.';
    	-- elaborazione deve essere ELABORATO_KO, ELABORATO_ERRATO, ELABORATO_SCARTATO
	    select 1 into codResult
    	from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
	    where elab.pagopa_elab_id=filePagoPaElabId
    	and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
	    and   stato.pagopa_elab_stato_code not in ( 'ANNULLATO','RIFIUTATO' )
    	and   stato.ente_proprietario_id=enteProprietarioId
	    and   elab.data_cancellazione is null;
    	raise notice 'strMessaggio  %',strMessaggio;
	    raise notice 'codResult %',codResult;
    	if codResult is null then
    		messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
	        return;
    	end if;
   end if; */
   
   
   strMessaggio:='Configurazione elab. di svecchiamento ['||SVECCHIA_CODE_PUNTUALE||']. Calcolo data di svecchiamento.';
   if pagopaElabSvecchiaMesi>0 then 
	      dataSvecchiaSqlQuery:='select date_trunc(''DAY'','''||dataElaborazione||'''::timestamp)- interval '''||pagopaElabSvecchiaMesi||' months'' ';
   else  dataSvecchiaSqlQuery:='select date_trunc(''DAY'','''||dataElaborazione||'''::timestamp)+ interval '''||1||' days'' ';	  
   end if;
   raise notice 'dataSvecchiaSqlQuery=%',dataSvecchiaSqlQuery;
   execute dataSvecchiaSqlQuery into dataSvecchia;
   if dataSvecchia is null then
   		messaggioRisultato:=strMessaggio||' Errore in calcolo.'||strMessaggioFinale;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        return;
   end if;
  
  
   strMessaggioFinale:='Elaborazione svecchiamento puntuale rinconciliazione PAGOPA okerr per '||
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
       'INIZIO '||tipo.pagopa_elab_svecchia_tipo_desc||'. ELAB. ID='||filePagoPaElabId::varchar||'. DataSvecchia='||to_char(dataSvecchia,'dd/mm/yyyy')||'.',
       tipo.pagopa_elab_svecchia_tipo_id,
       clock_timestamp(),
       loginOperazione,
       tipo.ente_proprietario_id
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE
    returning pagopa_elab_svecchia_id into pagopaElabSvecchiaId;
    if pagopaElabSvecchiaId is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in inserimento.'||strMessaggioFinale;
        return;
    end if;
 
   strMessaggio:='Inizio caricamento pagopa_t_elabora_svecchia_punt_okerr.';

   strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
   	);
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	
   raise notice '@@ prima di creazione table temp @@@';
   create temporary table pagopa_t_elabora_svecchia_punt_okerr
   as select distinct file.file_pagopa_id , flusso.pagopa_elab_flusso_id , elab.pagopa_elab_id 
		 from pagopa_t_riconciliazione_doc del,
			      siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
        		   pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione  ric 
		where stato.ente_proprietario_id=enteProprietarioId
		and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id
		and     stato.file_pagopa_stato_code ='ELABORATO_OK'
		and     r.file_pagopa_id=file.file_pagopa_id
		and     elab.pagopa_elab_id=r.pagopa_elab_id
		and     stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
		and     stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
		and     elab.pagopa_elab_data<dataSvecchia::timestamp
		and     flusso.pagopa_elab_id =elab.pagopa_elab_id 
		and     del.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		and     ric.pagopa_ric_id=del.pagopa_ric_id 
		and     ric.file_pagopa_id =file.file_pagopa_id
		and     exists 
		(
			select 1 from pagopa_t_riconciliazione_doc doc1 ,pagopa_t_riconciliazione  ric1
			where doc1.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
			and       doc1.pagopa_ric_doc_stato_elab='X' 
			and       ric1.pagopa_ric_id=doc1.pagopa_ric_id 
			and       ric1.file_pagopa_id =file.file_pagopa_id 
		);
	
	codResult:=0;
	select count(*) into codResult
    from pagopa_t_elabora_svecchia_punt_okerr;
	if codResult is null then codResult:=0; end if;
    raise notice 'pagopa_t_elabora_svecchia_punt_okerr=%',codResult;

    if pagopaElabSvecchiaTipoflagBack=true then
   		strMessaggio:='Inizio caricamento pagopa_t_bck_riconciliazione_doc.';

	    strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    	);
   		GET DIAGNOSTICS codResult = ROW_COUNT;
   	
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
          del.pagopa_ric_doc_id,
          del.pagopa_ric_doc_data,
          del.pagopa_ric_doc_voce_code,
          del.pagopa_ric_doc_voce_desc,
          del.pagopa_ric_doc_voce_tematica,
          del.pagopa_ric_doc_sottovoce_code,
          del.pagopa_ric_doc_sottovoce_desc,
          del.pagopa_ric_doc_sottovoce_importo,
          del.pagopa_ric_doc_anno_esercizio,
          del.pagopa_ric_doc_anno_accertamento,
          del.pagopa_ric_doc_num_accertamento,
          del.pagopa_ric_doc_num_capitolo,
          del.pagopa_ric_doc_num_articolo,
          del.pagopa_ric_doc_pdc_v_fin,
          del.pagopa_ric_doc_titolo,
          del.pagopa_ric_doc_tipologia,
          del.pagopa_ric_doc_categoria,
          del.pagopa_ric_doc_codice_benef,
          del.pagopa_ric_doc_str_amm,
          del.pagopa_ric_doc_subdoc_id,
          del.pagopa_ric_doc_provc_id,
          del.pagopa_ric_doc_movgest_ts_id,
          del.pagopa_ric_doc_stato_elab,
          del.pagopa_ric_errore_id,
          del.pagopa_ric_id,
          del.pagopa_elab_flusso_id,
          del.file_pagopa_id,
          del.validita_inizio,
          del.validita_fine,
          del.data_creazione,
          del.data_modifica,
          del.data_cancellazione,
          del.login_operazione,
          del.pagopa_ric_doc_ragsoc_benef,
          del.pagopa_ric_doc_nome_benef,
          del.pagopa_ric_doc_cognome_benef,
          del.pagopa_ric_doc_codfisc_benef,
          del.pagopa_ric_doc_soggetto_id,
          del.pagopa_ric_doc_flag_dett,
          del.pagopa_ric_doc_flag_con_dett,
          del.pagopa_ric_doc_tipo_code,
          del.pagopa_ric_doc_tipo_id,
          del.pagopa_ric_det_id,
          del.pagopa_ric_doc_iuv,
          del.pagopa_ric_doc_data_operazione,
          now(),
          loginOperazione,
          del.ente_proprietario_id
        from pagopa_t_riconciliazione_doc del,
			      siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
        		   pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione  ric ,pagopa_t_elabora_svecchia_punt_okerr tmp
		where stato.ente_proprietario_id=enteProprietarioId 
		and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id
		and     stato.file_pagopa_stato_code ='ELABORATO_OK'
		and     r.file_pagopa_id=file.file_pagopa_id
		and     elab.pagopa_elab_id=r.pagopa_elab_id
		and     stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
		and     stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
		and     elab.pagopa_elab_data< dataSvecchia::timestamp
		and     flusso.pagopa_elab_id =elab.pagopa_elab_id 
		and     del.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		and     ric.pagopa_ric_id=del.pagopa_ric_id 
		and     ric.file_pagopa_id =file.file_pagopa_id
		and     tmp.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		and     tmp.pagopa_elab_id =elab.pagopa_elab_id 
		and     tmp.file_pagopa_id =file.file_pagopa_id 
		and     exists 
		(
			select 1 from pagopa_t_riconciliazione_doc doc1 ,pagopa_t_riconciliazione  ric1
			where doc1.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
			and       doc1.pagopa_ric_doc_stato_elab='X' 
			and       ric1.pagopa_ric_id=doc1.pagopa_ric_id 
			and       ric1.file_pagopa_id =file.file_pagopa_id 
		);
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio
                     ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
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
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;
    
     strMessaggio:='Inizio cancellazione pagopa_t_riconciliazione_doc.';

	 strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
     );
   	 GET DIAGNOSTICS codResult = ROW_COUNT;
   
    codResult:=0;
    delete  from pagopa_t_riconciliazione_doc doc
	using siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
       		   pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione  ric ,pagopa_t_elabora_svecchia_punt_okerr tmp
	where stato.ente_proprietario_id=enteProprietarioId 
		and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
		and   stato.file_pagopa_stato_code ='ELABORATO_OK'
		and   r.file_pagopa_id=file.file_pagopa_id
		and   elab.pagopa_elab_id=r.pagopa_elab_id
		and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
		and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
		and   elab.pagopa_elab_data< dataSvecchia::timestamp
		and   flusso.pagopa_elab_id =elab.pagopa_elab_id 
		and   doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		and   ric.pagopa_ric_id=doc.pagopa_ric_id 
		and   ric.file_pagopa_id =file.file_pagopa_id
		and     tmp.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		and     tmp.pagopa_elab_id =elab.pagopa_elab_id 
		and     tmp.file_pagopa_id =file.file_pagopa_id 
	    and     exists 
		(
			select 1 from pagopa_t_riconciliazione_doc doc1 ,pagopa_t_riconciliazione  ric1
			where doc1.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
			and       doc1.pagopa_ric_doc_stato_elab='X' 
			and       ric1.pagopa_ric_id=doc1.pagopa_ric_id 
			and       ric1.file_pagopa_id =file.file_pagopa_id 
		); 
	GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is null then codResult:=0; end if;
    raise notice 'cancellati=%',codResult;
    countDel:=countDel+codResult;

    strMessaggio:='Cancellati  pagopa_t_riconciliazione_doc='||codResult::varchar||'.';

	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
   	GET DIAGNOSTICS codResult = ROW_COUNT;
   
   if pagopaElabSvecchiaTipoflagBack=true then
   		strMessaggio:='Inizio caricamento pagopa_t_bck_elaborazione_flusso.';

	    strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    	);
   		GET DIAGNOSTICS codResult = ROW_COUNT;
   	
      	strMessaggio:='Backup  pagopa_t_elaborazione_flusso.';
	    raise notice 'strMessaggio= backup pagopa_t_bck_elaborazione_flusso - ';
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
        select distinct 
              pagopaElabSvecchiaId,
              del.pagopa_elab_flusso_id,
              del.pagopa_elab_flusso_data,
              del.pagopa_elab_flusso_stato_id,
              del.pagopa_elab_flusso_note,
              del.pagopa_elab_ric_flusso_id,
              del.pagopa_elab_flusso_nome_mittente,
              del.pagopa_elab_ric_flusso_data,
              del.pagopa_elab_flusso_tot_pagam,
              del.pagopa_elab_flusso_anno_esercizio,
              del.pagopa_elab_flusso_anno_provvisorio,
              del.pagopa_elab_flusso_num_provvisorio,
              del.pagopa_elab_flusso_provc_id,
              del.pagopa_elab_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              now(),
              loginOperazione,
              del.ente_proprietario_id
        from pagopa_t_elaborazione_flusso del,
				  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
				  pagopa_t_elabora_svecchia_punt_okerr tmp
		where stato.ente_proprietario_id=enteProprietarioId 
		and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id
  	    and     stato.file_pagopa_stato_code ='ELABORATO_OK'
		and     r.file_pagopa_id=file.file_pagopa_id
		and     elab.pagopa_elab_id=r.pagopa_elab_id
		and     stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
		and     stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
	    and     elab.pagopa_elab_data< dataSvecchia::timestamp
		and     del.pagopa_elab_id =elab.pagopa_elab_id 
		and     tmp.pagopa_elab_flusso_id =del.pagopa_elab_flusso_id 
		and     tmp.pagopa_elab_id =elab.pagopa_elab_id 
		and     tmp.file_pagopa_id =file.file_pagopa_id 
     	and   not exists 
	    (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric
		    where    doc.pagopa_elab_flusso_id =del.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
	    );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio
                     ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
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
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;
    
     strMessaggio:='Inizio cancellazione pagopa_t_elaborazione_flusso.';

	 strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
   
    codResult:=0;
    delete from pagopa_t_elaborazione_flusso flusso
    using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                  pagopa_t_elabora_svecchia_punt_okerr tmp
    where stato.ente_proprietario_id=enteProprietarioId 
    and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id
	and     stato.file_pagopa_stato_code ='ELABORATO_OK'
	and     r.file_pagopa_id=file.file_pagopa_id
	and     elab.pagopa_elab_id=r.pagopa_elab_id
	and     stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and     stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
	and     elab.pagopa_elab_data< dataSvecchia::timestamp
	and     flusso.pagopa_elab_id =elab.pagopa_elab_id 
	and     tmp.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
	and     tmp.pagopa_elab_id =flusso.pagopa_elab_id 
	and     tmp.file_pagopa_id =file.file_pagopa_id
	and   not exists 
	(
		select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric
		where    doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		and          ric.file_pagopa_id =file.file_pagopa_id 
	);
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is null then codResult:=0; end if;
    raise notice 'cancellati=%',codResult;
    countDel:=countDel+codResult;

    strMessaggio:='Cancellati  pagopa_t_elaborazione_flusso='||codResult::varchar||'.';

	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
   	GET DIAGNOSTICS codResult = ROW_COUNT;
   
   
   if pagopaElabSvecchiaTipoflagBack=true then
   		strMessaggio:='Inizio caricamento pagopa_t_bck_elaborazione_log.';

	    strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    	);
   		GET DIAGNOSTICS codResult = ROW_COUNT;
   	
      	strMessaggio:='Backup  pagopa_t_bck_elaborazione_log.';
	    raise notice 'strMessaggio= backup pagopa_t_bck_elaborazione_log  - ';
        codResult:=0;
        insert into pagopa_t_bck_elaborazione_log 
        (
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
			del.pagopa_elab_log_id,
			del.pagopa_elab_id,
			del.pagopa_elab_file_id,
			del.pagopa_elab_log_operazione,
			now() ,
			del.ente_proprietario_id,
			loginOperazione
        from  pagopa_t_elaborazione_log del,
	    		     siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
	    		     pagopa_t_elabora_svecchia_punt_okerr tmp
	    where stato.ente_proprietario_id=enteProprietarioId 
	    and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
		and   stato.file_pagopa_stato_code ='ELABORATO_OK'
		and   r.file_pagopa_id=file.file_pagopa_id
	    and   elab.pagopa_elab_id=r.pagopa_elab_id
	    and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
	    and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
	    and   elab.pagopa_elab_data< dataSvecchia::timestamp
	    and   del.pagopa_elab_id =elab.pagopa_elab_id
	    and   del.pagopa_elab_file_id =file.file_pagopa_id 
		and     tmp.pagopa_elab_id =elab.pagopa_elab_id 
		and     tmp.file_pagopa_id =file.file_pagopa_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;
        
               
        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio
                     ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
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
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;
    
    strMessaggio:='Inizio cancellazione pagopa_t_elaborazione_log.';

	 strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
     raise notice '%',strMessaggioLog;
	 codResult:=0;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
   
    codResult:=0;
    delete from pagopa_t_elaborazione_log log_elab
	using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                  pagopa_t_elabora_svecchia_punt_okerr tmp
	where stato.ente_proprietario_id=enteProprietarioId 
	and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
	and   stato.file_pagopa_stato_code ='ELABORATO_OK'
	and   r.file_pagopa_id=file.file_pagopa_id
	and   elab.pagopa_elab_id=r.pagopa_elab_id
	and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
	and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
	and   elab.pagopa_elab_data< dataSvecchia::timestamp
	and   log_elab.pagopa_elab_id =elab.pagopa_elab_id
	and   log_elab.pagopa_elab_file_id =file.file_pagopa_id 
    and   tmp.pagopa_elab_id =elab.pagopa_elab_id 
	and   tmp.file_pagopa_id =file.file_pagopa_id; 
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is null then codResult:=0; end if;
    raise notice 'cancellati=%',codResult;
    countDel:=countDel+codResult;

    strMessaggio:='Cancellati  pagopa_t_elaborazione_log='||codResult::varchar||'.';

	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
   	GET DIAGNOSTICS codResult = ROW_COUNT;
   
   
   
     strMessaggio:='Inizio cancellazione pagopa_t_modifica_elab.';

	 strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
     );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    
    codResult:=0;
    delete from pagopa_t_modifica_elab modif
    using siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                  pagopa_t_elabora_svecchia_punt_okerr tmp
    where stato.ente_proprietario_id=enteProprietarioId 
    and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   stato.file_pagopa_stato_code ='ELABORATO_OK'
    and   r.file_pagopa_id=file.file_pagopa_id
    and   elab.pagopa_elab_id=r.pagopa_elab_id
    and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
    and   elab.pagopa_elab_data<dataSvecchia::timestamp
    and   modif.pagopa_elab_id  = elab.pagopa_elab_id 
    and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
    and   tmp.file_pagopa_id =file.file_pagopa_id 
    and   not exists 
    (
 	select 1 from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc,pagopa_t_riconciliazione  ric
	where   flusso.pagopa_elab_id =elab.pagopa_elab_id 
	and       doc.pagopa_elab_flusso_id  =flusso.pagopa_elab_flusso_id 
	and       modif.subdoc_id =doc.pagopa_ric_doc_subdoc_id
	and       ric.pagopa_ric_id=doc.pagopa_ric_id 
	and       ric.file_pagopa_id =file.file_pagopa_id 
    );
   GET DIAGNOSTICS codResult = ROW_COUNT;
   if codResult is null then codResult:=0; end if;
   raise notice 'cancellati=%',codResult;
   countDel:=countDel+codResult;

   strMessaggio:='Cancellati  pagopa_t_modifica_elab='||codResult::varchar||'.';

	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
     );
   	 GET DIAGNOSTICS codResult = ROW_COUNT;
   
   
    strMessaggio:='Inizio cancellazione pagopa_t_bck_*.';

	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
     );
     GET DIAGNOSTICS codResult = ROW_COUNT;
   
    strMessaggio:='Inizio cancellazione pagopa_bck_t_subdoc.';
    codResult:=0;
    delete from pagopa_bck_t_subdoc bck
    using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                   pagopa_t_elabora_svecchia_punt_okerr tmp
	where stato.ente_proprietario_id=enteProprietarioId 
	and      file.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and      stato.file_pagopa_stato_code ='ELABORATO_OK'
    and      r.file_pagopa_id=file.file_pagopa_id
    and      elab.pagopa_elab_id=r.pagopa_elab_id
    and      stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and      stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
    and      elab.pagopa_elab_data< dataSvecchia::timestamp
    and      bck.pagopa_elab_id=elab.pagopa_elab_id 
    and      tmp.pagopa_elab_id =bck.pagopa_elab_id 
    and      tmp.file_pagopa_id =file.file_pagopa_id
    and   not exists 
	(
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
	);
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is null then codResult:=0; end if;
    raise notice 'cancellati=%',codResult;
    countDel:=countDel+codResult;
    
    strMessaggio:='Inizio cancellazione pagopa_bck_t_subdoc_attr.';
    codResult:=0;
    delete from pagopa_bck_t_subdoc_attr bck
    using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab
    where stato.ente_proprietario_id=enteProprietarioId
    and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   stato.file_pagopa_stato_code ='ELABORATO_OK'
    and   r.file_pagopa_id=file.file_pagopa_id
    and   elab.pagopa_elab_id=r.pagopa_elab_id
    and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
    and      elab.pagopa_elab_data< dataSvecchia::timestamp
    and   bck.pagopa_elab_id=elab.pagopa_elab_id 
    and   not exists 
	(
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
	);
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is null then codResult:=0; end if;
    raise notice 'cancellati=%',codResult;
    countDel:=countDel+codResult;

    strMessaggio:='Inizio cancellazione pagopa_bck_t_subdoc_atto_amm.';
    codResult:=0;
   delete from pagopa_bck_t_subdoc_atto_amm bck
   using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                  pagopa_t_elabora_svecchia_punt_okerr tmp
   where stato.ente_proprietario_id=enteProprietarioId
   and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
   and   stato.file_pagopa_stato_code ='ELABORATO_OK'
   and   r.file_pagopa_id=file.file_pagopa_id
   and   elab.pagopa_elab_id=r.pagopa_elab_id
   and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
   and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
   and   elab.pagopa_elab_data< dataSvecchia::timestamp
   and   bck.pagopa_elab_id=elab.pagopa_elab_id 
   and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
   and   tmp.file_pagopa_id=file.file_pagopa_id 
   and   not exists 
	(
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
	);
   GET DIAGNOSTICS codResult = ROW_COUNT;
   if codResult is null then codResult:=0; end if;
   raise notice 'cancellati=%',codResult;
   countDel:=countDel+codResult;

   strMessaggio:='Inizio cancellazione pagopa_bck_t_subdoc_prov_cassa.';
   codResult:=0;
   delete from pagopa_bck_t_subdoc_prov_cassa bck
   using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                  pagopa_t_elabora_svecchia_punt_okerr tmp
   where stato.ente_proprietario_id=enteProprietarioId
   and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
   and   stato.file_pagopa_stato_code ='ELABORATO_OK'
   and   r.file_pagopa_id=file.file_pagopa_id
   and   elab.pagopa_elab_id=r.pagopa_elab_id
   and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
   and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
   and   elab.pagopa_elab_data< dataSvecchia::timestamp
   and   bck.pagopa_elab_id=elab.pagopa_elab_id 
   and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
   and   tmp.file_pagopa_id=file.file_pagopa_id
   and   not exists 
   (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
   );
   GET DIAGNOSTICS codResult = ROW_COUNT;
   if codResult is null then codResult:=0; end if;
   raise notice 'cancellati=%',codResult;
   countDel:=countDel+codResult;
   
   strMessaggio:='Inizio cancellazione pagopa_bck_t_subdoc_movgest_ts.';
   codResult:=0;
   delete from pagopa_bck_t_subdoc_movgest_ts bck
   using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                  pagopa_t_elabora_svecchia_punt_okerr tmp
   where stato.ente_proprietario_id=enteProprietarioId
   and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
   and   stato.file_pagopa_stato_code ='ELABORATO_OK'
   and   r.file_pagopa_id=file.file_pagopa_id
   and   elab.pagopa_elab_id=r.pagopa_elab_id
   and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
   and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
   and   elab.pagopa_elab_data< dataSvecchia::timestamp
   and   bck.pagopa_elab_id=elab.pagopa_elab_id 
   and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
   and   tmp.file_pagopa_id=file.file_pagopa_id
   and   not exists 
	(
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
	);
   GET DIAGNOSTICS codResult = ROW_COUNT;
   if codResult is null then codResult:=0; end if;
   raise notice 'cancellati=%',codResult;
   countDel:=countDel+codResult;
   
  strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_doc.';
  codResult:=0;
  delete from pagopa_bck_t_doc bck
  using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                 pagopa_t_elabora_svecchia_punt_okerr tmp
  where stato.ente_proprietario_id=enteProprietarioId
  and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
  and   stato.file_pagopa_stato_code ='ELABORATO_OK'
  and   r.file_pagopa_id=file.file_pagopa_id
  and   elab.pagopa_elab_id=r.pagopa_elab_id
  and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
  and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
  and   elab.pagopa_elab_data< dataSvecchia::timestamp
  and   bck.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.file_pagopa_id=file.file_pagopa_id
  and   not exists 
  (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
 
 strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_doc_stato.';
 codResult:=0;
 delete from pagopa_bck_t_doc_stato bck 
 using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                pagopa_t_elabora_svecchia_punt_okerr tmp
 where stato.ente_proprietario_id=enteProprietarioId
 and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
 and   stato.file_pagopa_stato_code ='ELABORATO_OK'
 and   r.file_pagopa_id=file.file_pagopa_id
 and   elab.pagopa_elab_id=r.pagopa_elab_id
 and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
 and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK' 
 and   elab.pagopa_elab_data< dataSvecchia::timestamp
 and   bck.pagopa_elab_id=elab.pagopa_elab_id 
 and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
 and   tmp.file_pagopa_id=file.file_pagopa_id
 and   not exists 
 (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
 );
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice 'cancellati=%',codResult;
 countDel:=countDel+codResult;

 strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_subdoc_num.';
 codResult:=0;
 delete from pagopa_bck_t_subdoc_num bck
 using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                pagopa_t_elabora_svecchia_punt_okerr tmp
 where stato.ente_proprietario_id=enteProprietarioId
 and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
 and   stato.file_pagopa_stato_code ='ELABORATO_OK'
 and   r.file_pagopa_id=file.file_pagopa_id
 and   elab.pagopa_elab_id=r.pagopa_elab_id
 and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
 and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
 and   elab.pagopa_elab_data< dataSvecchia::timestamp
 and   bck.pagopa_elab_id=elab.pagopa_elab_id 
 and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
 and   tmp.file_pagopa_id=file.file_pagopa_id
 and   not exists 
 (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
 );
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice 'cancellati=%',codResult;
 countDel:=countDel+codResult;

 strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_doc_sog.';
 codResult:=0;
 delete from pagopa_bck_t_doc_sog bck
 using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                pagopa_t_elabora_svecchia_punt_okerr tmp
 where stato.ente_proprietario_id=enteProprietarioId
 and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
 and   stato.file_pagopa_stato_code ='ELABORATO_OK'
 and   r.file_pagopa_id=file.file_pagopa_id
 and   elab.pagopa_elab_id=r.pagopa_elab_id
 and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
 and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
 and   elab.pagopa_elab_data< dataSvecchia::timestamp
 and   bck.pagopa_elab_id=elab.pagopa_elab_id 
 and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
 and   tmp.file_pagopa_id=file.file_pagopa_id
 and   not exists 
 (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
 );
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice 'cancellati=%',codResult;
 countDel:=countDel+codResult;

  strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_doc_attr.';
  codResult:=0;
  delete from pagopa_bck_t_doc_attr bck
  using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                 pagopa_t_elabora_svecchia_punt_okerr tmp
  where stato.ente_proprietario_id=enteProprietarioId
  and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
  and   stato.file_pagopa_stato_code ='ELABORATO_OK'
  and   r.file_pagopa_id=file.file_pagopa_id
  and   elab.pagopa_elab_id=r.pagopa_elab_id
  and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
  and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
  and   elab.pagopa_elab_data< dataSvecchia::timestamp
  and   bck.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.file_pagopa_id=file.file_pagopa_id
  and   not exists 
  (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
   );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;
  
  strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_doc_class.';
  codResult:=0;
  delete from pagopa_bck_t_doc_class bck
  using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                 pagopa_t_elabora_svecchia_punt_okerr tmp
  where stato.ente_proprietario_id=enteProprietarioId
  and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
  and   stato.file_pagopa_stato_code ='ELABORATO_OK'
  and   r.file_pagopa_id=file.file_pagopa_id
  and   elab.pagopa_elab_id=r.pagopa_elab_id
  and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
  and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
  and   elab.pagopa_elab_data< dataSvecchia::timestamp
  and   bck.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.file_pagopa_id=file.file_pagopa_id
  and   not exists 
  (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
  );
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice 'cancellati=%',codResult;
 countDel:=countDel+codResult;
   
  strMessaggio:='Inizio cancellazione   delete from pagopa_bck_t_registrounico_doc.';
  codResult:=0;
  delete from pagopa_bck_t_registrounico_doc bck
  using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
                 pagopa_t_elabora_svecchia_punt_okerr tmp
  where stato.ente_proprietario_id=enteProprietarioId
  and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
  and   stato.file_pagopa_stato_code ='ELABORATO_OK'
  and   r.file_pagopa_id=file.file_pagopa_id
  and   elab.pagopa_elab_id=r.pagopa_elab_id
  and   stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
  and   stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
  and   elab.pagopa_elab_data< dataSvecchia::timestamp
  and   bck.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.pagopa_elab_id=elab.pagopa_elab_id 
  and   tmp.file_pagopa_id=file.file_pagopa_id
  and   not exists 
  (
	    	select 1 from pagopa_t_riconciliazione_doc doc ,pagopa_t_riconciliazione  ric,pagopa_t_elaborazione_flusso  flusso
		    where    flusso.pagopa_elab_id =elab.pagopa_elab_id
		    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id 
		    and          ric.pagopa_ric_id =doc.pagopa_ric_id 
		    and          ric.file_pagopa_id =file.file_pagopa_id 
  );
 GET DIAGNOSTICS codResult = ROW_COUNT;
  if codResult is null then codResult:=0; end if;
  raise notice 'cancellati=%',codResult;
  countDel:=countDel+codResult;

 if pagopaElabSvecchiaTipoflagBack=true then
   		strMessaggio:='Inizio caricamento pagopa_r_bck_elaborazione_file.';

	    strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    	);
   		GET DIAGNOSTICS codResult = ROW_COUNT;
   	
      	strMessaggio:='Backup  pagopa_r_elaborazione_file.';
	    raise notice 'strMessaggio= backup pagopa_r_bck_elaborazione_file - ';
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
              del.pagopa_r_elab_id,
              del.pagopa_elab_id,
              del.file_pagopa_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              now(),
              loginOperazione,
              del.ente_proprietario_id
        from pagopa_r_elaborazione_file del,
  				    siac_t_file_pagopa file,siac_d_file_pagopa_stato stato, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab,
  				    pagopa_t_elabora_svecchia_punt_okerr tmp
		where stato.ente_proprietario_id=enteProprietarioId 
		and      stato.file_pagopa_stato_code='ELABORATO_OK'
	    and      file.file_pagopa_stato_id=stato.file_pagopa_stato_id
		and      del.file_pagopa_id=file.file_pagopa_id
	    and      del.pagopa_elab_id =elab.pagopa_elab_id
		and      stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
		and      stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
	    and      elab.pagopa_elab_data< dataSvecchia::timestamp
	    and      tmp.pagopa_elab_id=elab.pagopa_elab_id 
	    and      tmp.file_pagopa_id =file.file_pagopa_id 
 		and   not exists 
		(
		select 1 
		from pagopa_t_riconciliazione_doc doc , pagopa_t_elaborazione_flusso  flusso, pagopa_t_riconciliazione  ric 
		where   ric.file_pagopa_id=del.file_pagopa_id 
		and        doc.pagopa_ric_id=ric.pagopa_ric_id 
	    and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id
		and        flusso.pagopa_elab_id =elab.pagopa_elab_id 
	    ); 
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio
                     ||' Inseriti '||codResult::varchar||'. '||strMessaggioFinale;
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
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;
    
     strMessaggio:='Inizio cancellazione pagopa_r_elaborazione_file.';

	 strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
   
    codResult:=0;
    delete from pagopa_r_elaborazione_file  del
    using  siac_t_file_pagopa file,siac_d_file_pagopa_stato stato, pagopa_t_elaborazione elab ,pagopa_d_elaborazione_stato stato_elab
	where stato.ente_proprietario_id=enteProprietarioId 
	and      file.file_pagopa_stato_id=stato.file_pagopa_stato_id
  	and      stato.file_pagopa_stato_code ='ELABORATO_OK'
	and      del.file_pagopa_id=file.file_pagopa_id
	and      del.pagopa_elab_id =elab.pagopa_elab_id
	and      stato_elab.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
	and      stato_elab.pagopa_elab_stato_code!='ELABORATO_OK'
	and      elab.pagopa_elab_data< dataSvecchia::timestamp
 	and   not exists 
	(
	  select 1 
	  from pagopa_t_riconciliazione_doc doc , pagopa_t_elaborazione_flusso  flusso, pagopa_t_riconciliazione  ric 
	  where   ric.file_pagopa_id=del.file_pagopa_id 
	  and        doc.pagopa_ric_id=ric.pagopa_ric_id 
	  and         doc.pagopa_elab_flusso_id =flusso.pagopa_elab_flusso_id
	  and        flusso.pagopa_elab_id =elab.pagopa_elab_id 
	); 
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is null then codResult:=0; end if;
    raise notice 'cancellati=%',codResult;
    countDel:=countDel+codResult;

    strMessaggio:='Cancellati  pagopa_r_elaborazione_file='||codResult::varchar||'.';

	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_okerr - '||strMessaggio||' '||strMessaggioFinale;
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
    	 filePagoPaElabId,
	     null,
    	 strMessaggioLog,
		 enteProprietarioId,
    	 loginOperazione,
	     clock_timestamp()
    );
   	GET DIAGNOSTICS codResult = ROW_COUNT;
   

    



    codResult:=null;
    strMessaggio:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
                  ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                  ||'  Chiusura elaborazione [pagopa_t_elaborazione_svecchia].';
    raise notice 'strMessaggio=%',strMessaggio;
    update pagopa_t_elaborazione_svecchia elab
    set    data_modifica=clock_timestamp(),
               validita_fine=clock_timestamp(),
               pagopa_elab_svecchia_note=
               upper('FINE '||tipo.pagopa_elab_svecchia_tipo_desc||'. ELAB. ID='||filePagoPaElabId::varchar
               ||' Cancellati complessivamente '||coalesce(countDel,0)::varchar||' .')
    from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE
    and   elab.pagopa_elab_svecchia_id=pagopaElabSvecchiaId
    returning pagopa_elab_svecchia_id into codResult;
    if codResult is null then
        codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Errore in aggiornamento.'||strMessaggioFinale;
        return;
    end if;


    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
                          ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                          ||'  pagopa_t_riconciliazione_doc. '||strMessaggioFinale;
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
     filePagoPaElabId,
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;

    svecchiaPagoPaElabId:=pagopaElabSvecchiaId;
    codiceRisultato:=0;
    messaggioRisultato:='SVECCHIAMENTO TERMINATO - '
        ||' CANCELLATI COMPLESSIVAMENTE '||countDel::varchar||' .'
        ||upper(strMessaggioFinale);
    raise notice 'messaggioRisultato=%',messaggioRisultato;


    return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'') ;
       	codiceRisultato:=-1;
		svecchiaPagoPaElabId:=-1;
		messaggioRisultato:=upper(messaggioRisultato);
   		raise notice 'messaggioRisultato=%',messaggioRisultato;
		raise notice 'codiceRisultato=%',codiceRisultato;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
    	raise notice 'messaggioRisultato=%',messaggioRisultato;
		raise notice 'codiceRisultato=%',codiceRisultato;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        raise notice 'messaggioRisultato=%',messaggioRisultato;
    	raise notice 'codiceRisultato=%',codiceRisultato;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        svecchiaPagoPaElabId:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
	    raise notice 'messaggioRisultato=%',messaggioRisultato;
        raise notice 'codiceRisultato=%',codiceRisultato;

        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function  siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
(
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) owner to siac;