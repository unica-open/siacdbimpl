/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into pagopa_d_elaborazione_svecchia_tipo
(
    pagopa_elab_svecchia_tipo_code,
	pagopa_elab_svecchia_tipo_desc,
	pagopa_elab_svecchia_tipo_fl_attivo,
	pagopa_elab_svecchia_tipo_fl_back,
	pagopa_elab_svecchia_delta_giorni,	
	validita_inizio,
	ente_proprietario_id,
	login_operazione
)
select 'PUNTUALE-OK',
	        'SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE PER FLUSSI OK',
	        true,
	        true,
	        0,
	        now(),
	        ente.ente_proprietario_id ,
	        'SIAC-8842'
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and   not exists 
(
select 1 from pagopa_d_elaborazione_svecchia_tipo tipo 
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.pagopa_elab_svecchia_tipo_code='PUNTUALE-OK'
);

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
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out outpagopaelabid integer,
  out outpagopaelabprecid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
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
CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc(enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT outpagopaelabid integer, OUT outpagopaelabprecid integer, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
 AS $body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioBck  VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';

	codResult integer:=null;
	annoBilancio integer:=null;
    annoBilancio_ini integer:=null;

    filePagoPaElabId integer:=null;
    filePagoPaElabPrecId integer:=null;

    elabRec record;
    elabResRec record;
    annoRec record;
    elabEsecResRec record;

    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti


	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
	-- 18.01.2021 Sofia jira SIAC-7962
	ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

	---- 28.10.2020 Sofia SIAC-7672
    elabSvecchiaRec record;
BEGIN

	strMessaggioFinale:='Elaborazione PAGOPA.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale;
    raise notice 'strMessaggioLog=%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    outPagoPaElabPrecId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza elaborazione acquisita, in corso.';
    select 1 into codResult
    from pagopa_t_elaborazione pagopa, pagopa_d_elaborazione_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   pagopa.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is not null then
         outPagoPaElabId:=-1;
         outPagoPaElabPrecId:=-1;
         messaggioRisultato:=upper(strMessaggioFinale||' Elaborazione acquisita, in corso esistente.');
         strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	     insert into pagopa_t_elaborazione_log
         (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	     )
	     values
	     (
	      null,
	      strMessaggioLog,
	 	  enteProprietarioId,
     	  loginOperazione,
          clock_timestamp()
    	 );

         codiceRisultato:=-1;
    	 return;
    end if;




    annoBilancio:=extract('YEAR' from now())::integer;
    annoBilancio_ini:=annoBilancio;
    strMessaggio:='Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select 1 into codResult
    from siac_t_bil bil,siac_t_periodo per,
         siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where per.ente_proprietario_id=enteProprietarioid
    and   per.anno::integer=annoBilancio-1
    and   bil.periodo_id=per.periodo_id
    and   r.bil_id=bil.bil_id
    and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_id=r.fase_operativa_id
    -- 18.01.2021 Sofia jira SIAC-7962
--    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
    if codResult is not null then
    	annoBilancio_ini:=annoBilancio-1;
    end if;


    strMessaggio:='Verifica esistenza file da elaborare.';
    select 1 into codResult
    from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
    and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   pagopa.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
    if codResult is null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File da elaborare non esistenti.');
           codiceRisultato:=-1;
           strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	       insert into pagopa_t_elaborazione_log
           (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	       )
	       values
	       (
	        null,
	        strMessaggioLog,
	 	    enteProprietarioId,
     	    loginOperazione,
            clock_timestamp()
    	   );

           return;
    end if;
   
   -- SIAC-8276 - inizio 
   strMessaggio:='Verifica esistenza file duplicati.';
   select count(*)  into codResult 
   from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
   where stato.ente_proprietario_id=enteProprietarioId
   and   stato.file_pagopa_stato_code not in ( 'ANNULLATO','RIFIUTATO')
   and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
   and   file.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
   and file.data_cancellazione is null
   group by file.file_pagopa_id_flusso
   having count(*)>1;

   if codResult is not null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File duplicati esistenti.');
           codiceRisultato:=-1;
           strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
	       insert into pagopa_t_elaborazione_log
           (
     		pagopa_elab_id,
		    pagopa_elab_log_operazione,
		    ente_proprietario_id,
		    login_operazione,
            data_creazione
	       )
	       values
	       (
	        null,
	        strMessaggioLog,
	 	    enteProprietarioId,
     	    loginOperazione,
            clock_timestamp()
    	   );

           return;
    end if;
   
   -- SIAC-8276 - fine
   

   codResult:=null;
   strMessaggio:='Inizio elaborazioni anni.';
   strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
   raise notice 'strMessaggioLog=%',strMessaggioLog;
   insert into pagopa_t_elaborazione_log
   (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
   )
   values
   (
    null,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   for annoRec in
   (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    where codiceRisultato=0
    order by 1
   )
   loop
   -- codiceRisultato:=0;
    if annoRec.anno_elab>annoBilancio_ini then
    	filePagoPaElabPrecId:=filePagoPaElabId;
    end if;
    filePagoPaElabId:=null;
    strMessaggio:='Inizio elaborazione file PAGOPA per annoBilancio='||annoRec.anno_elab::varchar||'.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
    raise notice 'strMessaggioLog=%',strMessaggioLog;
    insert into pagopa_t_elaborazione_log
    (
      pagopa_elab_id,
      pagopa_elab_log_operazione,
      ente_proprietario_id,
      login_operazione,
      data_creazione
    )
    values
    (
     null,
     strMessaggioLog,
     enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
   
   raise notice 'ERRORE ERRORE codiceRisultato=%',codiceRisultato::varchar;
   raise notice 'ERRORE ERRORE annoRec.anno_elab=%',annoRec.anno_elab::varchar;
   
    for  elabRec in
    (
      select pagopa.*
      from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
      and   pagopa.file_pagopa_anno=annoRec.anno_elab
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null
      and   codiceRisultato=0
      order by pagopa.file_pagopa_id
    )
    loop
    	raise notice 'ERRORE ERRORE elabRec.file_pagopa_id=%',elabRec.file_pagopa_id::varchar;
       
       strMessaggio:='Elaborazione File PAGOPA ID='||elabRec.file_pagopa_id||' Identificativo='||coalesce(elabRec.file_pagopa_code,' ')
                      ||' annoBilancio='||annoRec.anno_elab::varchar||'.';

       strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
       raise notice '1strMessaggioLog=%',strMessaggioLog;
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
        elabRec.file_pagopa_id,
	    strMessaggioLog,
	    enteProprietarioId,
	    loginOperazione,
        clock_timestamp()
	   );
       raise notice '2strMessaggioLog=%',strMessaggioLog;

       select * into elabResRec
       from fnc_pagopa_t_elaborazione_riconc_insert
       (
          elabRec.file_pagopa_id,
          null,--filepagopaFileXMLId     varchar,
          null,--filepagopaFileOra       varchar,
          null,--filepagopaFileEnte      varchar,
          null,--filepagopaFileFruitore  varchar,
          filePagoPaElabId,
          annoRec.anno_elab,
          enteProprietarioId,
          loginOperazione,
          dataElaborazione
       );
              raise notice '2strMessaggioLog dopo=%',elabResRec.messaggiorisultato;

       if elabResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabResRec.codiceRisultato;
          strMessaggio:=elabResRec.messaggiorisultato;
       else
          filePagoPaElabId:=elabResRec.outPagoPaElabId;
       end if;

		raise notice 'codiceRisultato=%',codiceRisultato;
        raise notice 'strMessaggio=%',strMessaggio;
    end loop;

	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
    	strMessaggio:='Elaborazione documenti  annoBilancio='||annoRec.anno_elab::varchar
                      ||' Identificativo elab='||coalesce((filePagoPaElabId::varchar),' ')||'.';
        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc - '||strMessaggioFinale||strMessaggio;
        raise notice 'strMessaggioLog=%',strMessaggioLog;
	    insert into pagopa_t_elaborazione_log
   	    (
	      pagopa_elab_id,
    	  pagopa_elab_log_operazione,
	      ente_proprietario_id,
    	  login_operazione,
          data_creazione
	    )
	    values
	    (
     	  filePagoPaElabId,
	      strMessaggioLog,
	      enteProprietarioId,
	      loginOperazione,
          clock_timestamp()
	    );

        select * into elabEsecResRec
       	from fnc_pagopa_t_elaborazione_riconc_esegui
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabEsecResRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabEsecResRec.codiceRisultato;
          strMessaggio:=elabEsecResRec.messaggiorisultato;
        end if;
    end if;

    -- 28.10.2020 Sofia SIAC-7672 - inizio
--	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
--  16.04.2021 Sofia Jira 	SIAC-8163 - attivazione svecchiamento puntuale
    if coalesce(filePagoPaElabId,0)!=0 then
        select * into elabSvecchiaRec
       	from fnc_pagopa_t_elaborazione_riconc_svecchia_err
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabSvecchiaRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabSvecchiaRec.codiceRisultato;
          strMessaggio:=elabSvecchiaRec.messaggiorisultato;
        end if;
        raise notice 'codiceRisultato=%',codiceRisultato;
        raise notice 'strMessaggio=%',strMessaggio;
    end if;
    -- 28.10.2020 Sofia SIAC-7672 - fine

   end loop;
   
   -- 12.05.2023 Sofia SIAC-8842
   if coalesce(filePagoPaElabId,0)!=0 then
  	select * into elabSvecchiaRec
  	from fnc_pagopa_t_elaborazione_riconc_svecchia_okerr
	(
		  filePagoPaElabId,
	      annoBilancio,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
    );
    if elabSvecchiaRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabSvecchiaRec.codiceRisultato;
          strMessaggio:=elabSvecchiaRec.messaggiorisultato;
     end if;
     raise notice 'codiceRisultato=%',codiceRisultato;
     raise notice 'strMessaggio=%',strMessaggio;
   end if;
    -- 12.05.2023 Sofia SIAC-8842
  
   if codiceRisultato=0 then
	    outPagoPaElabId:=filePagoPaElabId;
        outPagoPaElabPrecId:=filePagoPaElabPrecId;
    	messaggioRisultato:=upper(strMessaggioFinale||' TERMINE OK.');
   else
    	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
    	messaggioRisultato:=upper(strMessaggioFinale||'TERMINE KO.'||strMessaggio);
   end if;

   strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc - '||messaggioRisultato;
   insert into pagopa_t_elaborazione_log
   (
    pagopa_elab_id,
    pagopa_elab_log_operazione,
    ente_proprietario_id,
    login_operazione,
    data_creazione
   )
   values
   (
    filePagoPaElabId ,
    strMessaggioLog,
    enteProprietarioId,
    loginOperazione,
    clock_timestamp()
   );

   return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
       	outPagoPaElabPrecId:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function
siac.fnc_pagopa_t_elaborazione_riconc
(
 integer,
 varchar,
 timestamp,
 out integer,
 out integer,
 out integer,
 out varchar
) OWNER to siac;