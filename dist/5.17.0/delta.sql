/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- INIZIO 1.SIAC-8842.sql



\echo 1.SIAC-8842.sql


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




-- INIZIO 2.SIAC-8899.sql



\echo 2.SIAC-8899.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8899 Sofia 08.05.2023 inizio 

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp 
(
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean
);

DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_comp_anno ( integer,character varying);

drop FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_econb_anno
(
  id_in integer,
  anno_in varchar
);

create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno 
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;
BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;



 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
raise notice 'importoCurAttuale=%',importoCurAttuale;
/*select tb.importo into importoCurAttuale from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId))
    group by c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    and t.movgest_ts_tipo_code=TIPO_IMP_T;--'T'; */

 /* select
      coalesce(sum(e.movgest_ts_det_importo),0) into importoCurAttuale
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId));*/

  --raise notice 'importoCurAttuale:%', importoCurAttuale;
 --fine nuovo G
 /*for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=id_in
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilancioId
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo accertato anno_in='||anno_in||'Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;*/
 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    --and   tipom.mod_tipo_code <> 'ECONB'  -- 08.05.2023 Sofia SIAC-8899
     -- 08.05.2023 Sofia SIAC-8899
    and   ( tipom.mod_tipo_code <> 'ECONB' AND  tipom.mod_tipo_code <> 'REANNO' )
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;
raise notice 'importoModifNeg=%',importoModifNeg;
  -- 10.08.2020 Sofia jira SIAC-6865 - inizio
  -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
  if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=id_in
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine
raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione;

  -- anna_economie inizio
   select tb.importo into importoModifINS
   from
   (
      select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
      from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
           siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
           siac_t_movgest_ts_det_mod moddet,
           siac_t_modifica mod, siac_r_modifica_stato rmodstato,
           siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
           siac_d_modifica_tipo tipom
      where rbil.elem_id=id_in
      and	  mov.movgest_id=rbil.movgest_id
      and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
      and   mov.movgest_anno=anno_in::integer
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rstato.movgest_ts_id=ts.movgest_ts_id
      and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
      and   tsdet.movgest_ts_id=ts.movgest_ts_id
      and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
      and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
      -- SIAC-7349
      -- abbiamo tolto il commento nella riga qui sotto perche' d'accordo con Pietro Gambino
      -- e visto che possono anche esserci modifiche ECONB positive
      -- e' bene escluderle dal calcolo importoModifINS
      and   moddet.movgest_ts_det_importo<0 -- importo negativo
      and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
      and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
      and   mod.mod_id=rmodstato.mod_id
      and   atto.attoamm_id=mod.attoamm_id
      and   attostato.attoamm_id=atto.attoamm_id
      and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
      and   tipom.mod_tipo_id=mod.mod_tipo_id
      and   tipom.mod_tipo_code = 'ECONB'
      -- date
      and rbil.data_cancellazione is null
      and rbil.validita_fine is null
      and mov.data_cancellazione is null
      and mov.validita_fine is null
      and ts.data_cancellazione is null
      and ts.validita_fine is null
      and rstato.data_cancellazione is null
      and rstato.validita_fine is null
      and tsdet.data_cancellazione is null
      and tsdet.validita_fine is null
      and moddet.data_cancellazione is null
      and moddet.validita_fine is null
      and mod.data_cancellazione is null
      and mod.validita_fine is null
      and rmodstato.data_cancellazione is null
      and rmodstato.validita_fine is null
      and attostato.data_cancellazione is null
      and attostato.validita_fine is null
      and atto.data_cancellazione is null
      and atto.validita_fine is null
      group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo tipo
    where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
    AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
    order by tipo.movgest_ts_tipo_code desc
    limit 1;

    if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;
raise notice 'importoModifINS=%',importoModifINS;

raise notice 'importoAttuale0=%',importoAttuale;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG
raise notice 'importoAttuale1=%',importoAttuale;

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine
raise notice 'importoAttuale2=%',importoAttuale;

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
raise notice 'importoAttuale3=%',importoAttuale;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean)
    OWNER TO siac;
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp (
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato di competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in and
	  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;


 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	 and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    --and   tipom.mod_tipo_code <> 'ECONB' -- 08.05.2023 Sofia SIAC-8899
    -- 08.05.2023 Sofia SIAC-8899
    and  (tipom.mod_tipo_code <> 'ECONB' and tipom.mod_tipo_code <> 'REANNO') 
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

-- 10.08.2020 Sofia jira SIAC-6865 - inizio
  -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
  if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=id_in
      and   rmov.elem_det_comp_tipo_id=idcomp_in::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine

  -- anna_economie inizio
  select tb.importo into importoModifINS
  from
  (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code = 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;

  if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean)
    OWNER TO siac;
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno(id_in integer, anno_in character varying, verifica_mod_prov boolean DEFAULT true)
 RETURNS TABLE(annocompetenza character varying, dicuiimpegnato numeric)
AS 
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
STATO_MOD_V  constant varchar:='V';
TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0; -- SIAC-7349
attoAmmStatoPId integer:=0;-- SIAC-7349
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;
modStatoVId integer:=0; -- SIAC-7349
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0; -- SIAC-7349
movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; -- SIAC-7349 --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

-- 10.08.2020 Sofia jira siac-6865
movGestStatoPId integer:=null;
importoCurAttAggiudicazione numeric:=0;
BEGIN


 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
      siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
   and bil.bil_id=bilElem.bil_id
   and per.periodo_id=bil.periodo_id;

 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select bilelem.elem_id into elemIdGestEq
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_code=elemCode
   and bilElem.elem_code2=elemCode2
   and bilElem.elem_code3=elemCode3
   and bilElem.ente_proprietario_id=enteProprietarioId
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and bilElem.bil_id=bilIdElemGestEq
   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

if NOT FOUND THEN
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;


-- SIAC-7349 INIZIO
strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;

	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;

	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;
-- SIAC-7349 FINE

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
	   -- SIAC-7349 INIZIO
          
/*  SIAC-8493 03.12.2021 Sofia spostato fuori ciclo      
    if importoCurAttuale>=0 then
              ----------------
              select tb.importo into importoModifDelta
	          from
	          (
	          	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	          	from siac_r_movgest_bil_elem rbil,
	          	 	siac_t_movgest mov,
	          	 	siac_t_movgest_ts ts,
	          		siac_r_movgest_ts_stato rstato,
	          	  siac_t_movgest_ts_det tsdet,
	          		siac_t_movgest_ts_det_mod moddet,
	          		siac_t_modifica mod,
	          	 	siac_r_modifica_stato rmodstato,
	          		siac_r_atto_amm_stato attostato,
	          	 	siac_t_atto_amm atto,
	          		siac_d_modifica_tipo tipom
	          	where
	          		rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
	          		and	 mov.movgest_id=rbil.movgest_id
	          		and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
	          		and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
	          		and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
	          		and  ts.movgest_id=mov.movgest_id
	          		and  rstato.movgest_ts_id=ts.movgest_ts_id
	          		and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
	          		and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
	          	  and  tsdet.movgest_ts_id=ts.movgest_ts_id
	          		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	          		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	          	 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	          		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	          		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	          		and   mod.mod_id=rmodstato.mod_id
	          		and   atto.attoamm_id=mod.attoamm_id
	          		and   attostato.attoamm_id=atto.attoamm_id
	          		and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
	          		and   tipom.mod_tipo_id=mod.mod_tipo_id
	          		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
	          		and rbil.data_cancellazione is null
	          		and rbil.validita_fine is null
	          		and mov.data_cancellazione is null
	          		and mov.validita_fine is null
	          		and ts.data_cancellazione is null
	          		and ts.validita_fine is null
	          		and rstato.data_cancellazione is null
	          		and rstato.validita_fine is null
	          		and tsdet.data_cancellazione is null
	          		and tsdet.validita_fine is null
	          		and moddet.data_cancellazione is null
	          		and moddet.validita_fine is null
	          		and mod.data_cancellazione is null
	          		and mod.validita_fine is null
	          		and rmodstato.data_cancellazione is null
	          		and rmodstato.validita_fine is null
	          		and attostato.data_cancellazione is null
	          		and attostato.validita_fine is null
	          		and atto.data_cancellazione is null
	          		and atto.validita_fine is null
	          		group by ts.movgest_ts_tipo_id
	          	  ) tb, siac_d_movgest_ts_tipo tipo
	          	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	          	  order by tipo.movgest_ts_tipo_code desc
	          	  limit 1;
	      	  -- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
	          if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;

                  /*Aggiunta delle modifiche ECONB*/
		        -- anna_economie inizio
	          select tb.importo into importoModifINS
		                from
		                (
		                	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
		                	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
	                   	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
		                  siac_t_movgest_ts_det_mod moddet,
	                   	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
		                  siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
	                    siac_d_modifica_tipo tipom
		                where rbil.elem_id=elemIdGestEq
		                and	 mov.movgest_id=rbil.movgest_id
		                and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
	                  and  mov.movgest_anno=anno_in::integer
	                  and  mov.bil_id=bilancioId
		                and  ts.movgest_id=mov.movgest_id
		                and  rstato.movgest_ts_id=ts.movgest_ts_id
		                and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		                and  tsdet.movgest_ts_id=ts.movgest_ts_id
		                and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		                and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
		                and   moddet.movgest_ts_det_importo<0 -- importo negativo
		                and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
		                and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
		                and   mod.mod_id=rmodstato.mod_id
		                and   atto.attoamm_id=mod.attoamm_id
		                and   attostato.attoamm_id=atto.attoamm_id
		                and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
	                   and   tipom.mod_tipo_id=mod.mod_tipo_id
	                   and   tipom.mod_tipo_code = 'ECONB'
		                -- date
		                and rbil.data_cancellazione is null
		                and rbil.validita_fine is null
		                and mov.data_cancellazione is null
		                and mov.validita_fine is null
		                and ts.data_cancellazione is null
		                and ts.validita_fine is null
		                and rstato.data_cancellazione is null
		                and rstato.validita_fine is null
		                and tsdet.data_cancellazione is null
		                and tsdet.validita_fine is null
		                and moddet.data_cancellazione is null
		                and moddet.validita_fine is null
		                and mod.data_cancellazione is null
		                and mod.validita_fine is null
		                and rmodstato.data_cancellazione is null
		                and rmodstato.validita_fine is null
		                and attostato.data_cancellazione is null
		                and attostato.validita_fine is null
		                and atto.data_cancellazione is null
		                and atto.validita_fine is null
	                   group by ts.movgest_ts_tipo_id
	                  ) tb, siac_d_movgest_ts_tipo tipo
	                  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	                  order by tipo.movgest_ts_tipo_code desc
	                  limit 1;

       			 if importoModifINS is null then
	 	            importoModifINS = 0;
	            end if;
            end if; SIAC-8493 03.12.2021 Sofia spostato fuori ciclo   - fine   */
    end if;
   importoAttuale:=importoAttuale+importoCurAttuale;
 
  -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
  --importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);

  -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
  --aggiunta per ECONB
  --importoAttuale:=importoAttuale+abs(importoModifINS);

 end loop;
 
 -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
 raise notice 'importoAttuale=%',importoAttuale::varchar;
 if  verifica_mod_prov=true then
  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo modifiche negative per anno_in='||anno_in||'.';
  select tb.importo into importoModifDelta
  from
  (
  	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
  	from siac_r_movgest_bil_elem rbil,
  	 	siac_t_movgest mov,
  	 	siac_t_movgest_ts ts,
  		siac_r_movgest_ts_stato rstato,
  	  siac_t_movgest_ts_det tsdet,
  		siac_t_movgest_ts_det_mod moddet,
  		siac_t_modifica mod,
  	 	siac_r_modifica_stato rmodstato,
  		siac_r_atto_amm_stato attostato,
  	 	siac_t_atto_amm atto,
  		siac_d_modifica_tipo tipom
  	where
  		rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
  		and	 mov.movgest_id=rbil.movgest_id
  		and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
  		and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
  		and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
  		and  ts.movgest_id=mov.movgest_id
  		and  rstato.movgest_ts_id=ts.movgest_ts_id
  		and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
  		and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
    	and  tsdet.movgest_ts_id=ts.movgest_ts_id
  		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
  		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
  	 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
  		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
  		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
  		and   mod.mod_id=rmodstato.mod_id
  		and   atto.attoamm_id=mod.attoamm_id
  		and   attostato.attoamm_id=atto.attoamm_id
  		and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
  		and   tipom.mod_tipo_id=mod.mod_tipo_id
--  		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione -- SIAC-8899 09.05.2023 Sofia 
  		and  (tipom.mod_tipo_code <> 'ECONB' and tipom.mod_tipo_code <> 'REANNO') -- SIAC-8899 09.05.2023 Sofia 
  		and rbil.data_cancellazione is null
  		and rbil.validita_fine is null
  		and mov.data_cancellazione is null
  		and mov.validita_fine is null
  		and ts.data_cancellazione is null
  		and ts.validita_fine is null
  		and rstato.data_cancellazione is null
  		and rstato.validita_fine is null
  		and tsdet.data_cancellazione is null
  		and tsdet.validita_fine is null
  		and moddet.data_cancellazione is null
  		and moddet.validita_fine is null
  		and mod.data_cancellazione is null
  		and mod.validita_fine is null
  		and rmodstato.data_cancellazione is null
  		and rmodstato.validita_fine is null
  		and attostato.data_cancellazione is null
  		and attostato.validita_fine is null
  		and atto.data_cancellazione is null
  		and atto.validita_fine is null
  		group by ts.movgest_ts_tipo_id
  	  ) tb, siac_d_movgest_ts_tipo tipo
  	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  	  order by tipo.movgest_ts_tipo_code desc
  	  limit 1;
   
      if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;
      raise notice 'importoModifDelta=%',importoModifDelta::varchar;

      -- aggiunta negative	
      importoAttuale:=importoAttuale-(importoModifDelta);

      raise notice 'importoAttuale=%',importoAttuale::varchar;

      strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo modifiche negative ECONB per anno_in='||anno_in||'.';  
      select tb.importo into importoModifINS
	  from
	  (
		select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
		from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
			 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
		     siac_t_movgest_ts_det_mod moddet,
			 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
		  	 siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
	   		 siac_d_modifica_tipo tipom
		where rbil.elem_id=elemIdGestEq
		and	 mov.movgest_id=rbil.movgest_id
		and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
		and  mov.movgest_anno=anno_in::integer
		and  mov.bil_id=bilancioId
		and  ts.movgest_id=mov.movgest_id
		and  rstato.movgest_ts_id=ts.movgest_ts_id
		and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		and  tsdet.movgest_ts_id=ts.movgest_ts_id
		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
		and   moddet.movgest_ts_det_importo<0 -- importo negativo
		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
		and   mod.mod_id=rmodstato.mod_id
		and   atto.attoamm_id=mod.attoamm_id
		and   attostato.attoamm_id=atto.attoamm_id
		and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
		and   tipom.mod_tipo_id=mod.mod_tipo_id
		and   tipom.mod_tipo_code = 'ECONB'
		-- date
        and rbil.data_cancellazione is null
        and rbil.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and ts.data_cancellazione is null
        and ts.validita_fine is null
        and rstato.data_cancellazione is null
        and rstato.validita_fine is null
        and tsdet.data_cancellazione is null
        and tsdet.validita_fine is null
        and moddet.data_cancellazione is null
        and moddet.validita_fine is null
        and mod.data_cancellazione is null
        and mod.validita_fine is null
        and rmodstato.data_cancellazione is null
        and rmodstato.validita_fine is null
        and attostato.data_cancellazione is null
        and attostato.validita_fine is null
        and atto.data_cancellazione is null
        and atto.validita_fine is null
        group by ts.movgest_ts_tipo_id
      ) tb, siac_d_movgest_ts_tipo tipo
	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	  order by tipo.movgest_ts_tipo_code desc
	  limit 1;
		
	  if importoModifINS is null then
		    importoModifINS = 0;
	  end if;   
      raise notice 'importoModifINS=%',importoModifINS::varchar;

      --aggiunta per ECONB
      importoAttuale:=importoAttuale+abs(importoModifINS);
	  raise notice 'importoAttuale=%',importoAttuale::varchar;
 end if;
 -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo - fine

 -- 10.08.2020 Sofia Jira SIAC-6865 - inizio
 -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
 if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=elemIdGestEq
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilIdElemGestEq
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
    raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione::varchar;
    importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
    raise notice 'importoAttuale=%',importoAttuale::varchar;
  end if;
  -- 10.08.2020 Sofia Jira SIAC-6865 - fine

end if;


-- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo
raise notice '@@@@@ in uscita importoAttuale=%',importoAttuale::varchar;
annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE
/*
Calcolo dell'impegnato di un capitolo di previsione id_in su una componente id_comp per l'anno anno_it,
utile al calcolo della disponibilita' a variare
quindi non tiene conto di grandezze da considerare solo per disponibilita' ad impegnare: limite massimo impegnabile e modifiche di impegno negative su provvedimento provvisorio
*/

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';

STATO_MOD_V  constant varchar:='V';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0;
attoAmmStatoPId integer:=0;
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

modStatoVId integer:=0;
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTsId integer:=0;


importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

-- 10.08.2020 Sofia jira siac-6865
movGestStatoPId integer:=null;
importoCurAttAggiudicazione numeric:=0;
BEGIN

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
      siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
   and bil.bil_id=bilElem.bil_id
   and per.periodo_id=bil.periodo_id;

 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select bilelem.elem_id into elemIdGestEq
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_code=elemCode
   and bilElem.elem_code2=elemCode2
   and bilElem.elem_code3=elemCode3
   and bilElem.ente_proprietario_id=enteProprietarioId
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and bilElem.bil_id=bilIdElemGestEq
   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

if NOT FOUND THEN
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;

	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;

	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;



 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
	 and movGestRel.elem_det_comp_tipo_id=id_comp
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);



    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;

	   if importoCurAttuale>=0 then

		  select tb.importo into importoModifDelta
				from
				(
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil,
					 	siac_t_movgest mov,
					 	siac_t_movgest_ts ts,
						siac_r_movgest_ts_stato rstato,
					  siac_t_movgest_ts_det tsdet,
						siac_t_movgest_ts_det_mod moddet,
						siac_t_modifica mod,
					 	siac_r_modifica_stato rmodstato,
						siac_r_atto_amm_stato attostato,
					 	siac_t_atto_amm atto,
						siac_d_modifica_tipo tipom
					where
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	 mov.movgest_id=rbil.movgest_id
						and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
						and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and  ts.movgest_id=mov.movgest_id
						and  rstato.movgest_ts_id=ts.movgest_ts_id
						and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
						and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					  and  tsdet.movgest_ts_id=ts.movgest_ts_id
						and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
--						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione -- SIAC-8899 09.05.2023 Sofia
						and   ( tipom.mod_tipo_code <> 'ECONB' and  tipom.mod_tipo_code <> 'REANNO' ) -- SIAC-8899 09.05.2023 Sofia
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;
				-- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
				if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;

		/*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=anno_in::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;

			 if importoModifINS is null then
			 	importoModifINS = 0;
			 end if;



		   end if;

    end if;

    importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);
  --aggiunta per ECONB
	importoAttuale:=importoAttuale+abs(importoModifINS);
 end loop;

 -- 10.08.2020 Sofia Jira SIAC-6865 - inizio
 -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
 if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=elemIdGestEq
      and   rmov.elem_det_comp_tipo_id=id_comp::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilIdElemGestEq
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;

    importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
  end if;
  -- 10.08.2020 Sofia Jira SIAC-6865 - fine

end if;

annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean)
    OWNER TO siac;


create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno 
(
  id_in integer,
  anno_in varchar
)
RETURNS TABLE 
(
  annocompetenza varchar,
  dicuiimpegnato_econb numeric
) AS
$body$
DECLARE



strMessaggio varchar(1500):='';

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

importoModifNeg  numeric:=0;
importoModifEconb  numeric:=0;

esisteMovPerElemId INTEGER:=0;

BEGIN

strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Inizio.';
annoCompetenza:=anno_in;
diCuiImpegnato_EconB:=0;

strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Verifica esistenza movimenti..';
select 1 into esisteMovPerElemId 
from siac_r_movgest_bil_elem re, siac_t_movgest mov
where re.elem_id=id_in
and     mov.movgest_id=re.movgest_id
and     mov.movgest_anno=anno_in::integer
and     re.data_cancellazione  is null 
and     re.validita_fine  is null;
if esisteMovPerElemId is null then esisteMovPerElemId:=0; end if;
raise notice 'esisteMovPerElemId=%',esisteMovPerElemId;

if esisteMovPerElemId <>0 then



 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in='' then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
 into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and      bilElem.data_cancellazione is null
 and      bil.bil_id=bilElem.bil_id
 and      per.periodo_id=bil.periodo_id;


 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'. Inizio calcolo totale modifiche negative prov. per anno_in='||anno_in||'.';
 raise notice 'strMessaggio %',strMessaggio;
 select tb.importo  into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id 
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
	       	  siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	          siac_t_movgest_ts_det_mod moddet,
    	 	  siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	  	      siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
              siac_d_modifica_tipo tipom,
              siac_d_movgest_tipo tipo ,
              siac_d_movgest_stato stato ,
              siac_d_modifica_stato stato_modif,
              siac_d_atto_amm_stato stato_atto
	where  rbil.elem_id= id_in -- <elem_id_in >
	and	      mov.movgest_id=rbil.movgest_id
	and  	  mov.movgest_tipo_id=tipo.movgest_tipo_id 
	and   	  tipo.movgest_tipo_code ='I'
    and       mov.movgest_anno=anno_in::integer -- <annoCompetenza>
    and       mov.bil_id=bilancioId
	and   	  ts.movgest_id=mov.movgest_id
	and       rstato.movgest_ts_id=ts.movgest_ts_id
	and       rstato.movgest_stato_id=stato.movgest_stato_id 
	and   	  stato.movgest_stato_code !='A'
	and   	  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  	  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and  	  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and  	  moddet.movgest_ts_det_importo<0 -- importo negativo
	and   	  rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   	  rmodstato.mod_stato_id=stato_modif.mod_stato_id 
	and   	  stato_modif.mod_stato_code ='V'
	and       mod.mod_id=rmodstato.mod_id
	and  	  atto.attoamm_id=mod.attoamm_id
	and   	  attostato.attoamm_id=atto.attoamm_id
	and   	  attostato.attoamm_stato_id=stato_atto.attoamm_stato_id 
    and   	  stato_atto.attoamm_stato_code ='PROVVISORIO'
    and   	  tipom.mod_tipo_id=mod.mod_tipo_id
    --and   	  tipom.mod_tipo_code <> 'ECONB' -- 10.05.2023 Sofia Jira SIAC-8899
    and   	  ( tipom.mod_tipo_code <> 'ECONB'   AND tipom.mod_tipo_code <> 'REANNO' ) -- 10.05.2023 Sofia Jira SIAC-8899
    and    	  not exists 
    (
    select 1 
    from siac_r_movgest_aggiudicazione  ragg 
    where ragg.movgest_id_da =mov.movgest_id 
    and     ragg.data_cancellazione  is null 
    and     ragg.validita_fine is null 
    )
	and 	  rbil.data_cancellazione is null
	and 	  rbil.validita_fine is null
	and		  mov.data_cancellazione is null
	and		  mov.validita_fine is null
	and 	  ts.data_cancellazione is null
	and 	  ts.validita_fine is null
	and 	  rstato.data_cancellazione is null
	and 	  rstato.validita_fine is null
	and 	  tsdet.data_cancellazione is null
	and 	  tsdet.validita_fine is null
	and 	  moddet.data_cancellazione is null
	and 	  moddet.validita_fine is null
	and 	  mod.data_cancellazione is null
	and 	  mod.validita_fine is null
	and       rmodstato.data_cancellazione is null
	and		  rmodstato.validita_fine is null
	and 	  attostato.data_cancellazione is null
	and 	  attostato.validita_fine is null
	and 	  atto.data_cancellazione is null
	and 	  atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T';
  if importoModifNeg is null then importoModifNeg:=0; end if;
  
  raise notice 'importoModifNeg=%',importoModifNeg::varchar;
 
  strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'. Inizio calcolo totale modifiche econb  per anno_in='||anno_in||'.';
  raise notice 'strMessaggio %',strMessaggio;
 select tb.importo into importoModifEconb
  from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
       	       siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	           siac_t_movgest_ts_det_mod moddet,
	       	   siac_t_modifica mod, siac_r_modifica_stato rmodstato,
  	           siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
               siac_d_modifica_tipo tipom,
	           siac_d_movgest_tipo tipo ,
               siac_d_movgest_stato stato ,
	           siac_d_modifica_stato stato_modif,
               siac_d_atto_amm_stato stato_atto
	where  rbil.elem_id= id_in -- <elem_id_id>
 	and	      mov.movgest_id=rbil.movgest_id
	and       mov.movgest_tipo_id=tipo.movgest_tipo_id 
	and       tipo.movgest_tipo_code ='I'
    and       mov.movgest_anno=anno_in::integer -- <annoCompetenza>
    and       mov.bil_id=bilancioId
	and       ts.movgest_id=mov.movgest_id
	and       rstato.movgest_ts_id=ts.movgest_ts_id
	and       rstato.movgest_stato_id=stato.movgest_stato_id 
	and       stato.movgest_stato_code !='A'
	and       tsdet.movgest_ts_id=ts.movgest_ts_id
	and       moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and       moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and       moddet.movgest_ts_det_importo<0 -- importo negativo
	and       rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and       rmodstato.mod_stato_id=stato_modif.mod_stato_id 
	and       stato_modif.mod_stato_code ='V'
	and       mod.mod_id=rmodstato.mod_id
	and       atto.attoamm_id=mod.attoamm_id
	and       attostato.attoamm_id=atto.attoamm_id
	and       attostato.attoamm_stato_id=stato_atto.attoamm_stato_id 
    and       stato_atto.attoamm_stato_code in ('PROVVISORIO','DEFINITIVO')
    and       tipom.mod_tipo_id=mod.mod_tipo_id
    and       tipom.mod_tipo_code = 'ECONB'
	and       rbil.data_cancellazione is null
	and       rbil.validita_fine is null
	and       mov.data_cancellazione is null
	and       mov.validita_fine is null
	and       ts.data_cancellazione is null
	and       ts.validita_fine is null
	and       rstato.data_cancellazione is null
	and       rstato.validita_fine is null
	and       tsdet.data_cancellazione is null
	and       tsdet.validita_fine is null
	and       moddet.data_cancellazione is null
	and       moddet.validita_fine is null
	and       mod.data_cancellazione is null
	and       mod.validita_fine is null
	and       rmodstato.data_cancellazione is null
	and       rmodstato.validita_fine is null
	and       attostato.data_cancellazione is null
	and       attostato.validita_fine is null
	and       atto.data_cancellazione is null
	and       atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T';
  if importoModifEconb is null then importoModifEconb:=0; end if;
  raise notice 'importoModifEconb=%',importoModifEconb::varchar;


  annoCompetenza:=anno_in;
  diCuiImpegnato_EconB:=importoModifNeg+importoModifEconb;

else

   annoCompetenza:=anno_in;
   diCuiImpegnato_EconB:=0;
   raise notice 'Movimento non esistenti.';
end if;

raise notice 'anno_in=%',anno_in;
raise notice 'diCuiImpegnato_EconB=%',diCuiImpegnato_EconB::varchar;

return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno(integer, varchar)   OWNER TO siac;


-- SIAC-8899 Sofia 08.05.2023 fine 




-- INIZIO 3.SIAC-8750-TASK99.sql



\echo 3.SIAC-8750-TASK99.sql


--SIAC-8750 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR153_struttura_dca_spese_fpv_anno_succ"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR153_struttura_dca_spese_fpv_anno_succ" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  missione_code varchar,
  programma_code varchar,
  cofog varchar,
  transaz_ue varchar,
  pdc varchar,
  per_sanitario varchar,
  ricorr_spesa varchar,
  code_cup varchar,
  tupla_group varchar,
  fondo_plur_vinc numeric
) AS
$body$
DECLARE

/* 10/09/2020 - SIAC-7702.
	Nuova funzione che estrae i dati delle quote di impegni vincolati a FPVSC o FPVCC 
    dell'anno di bilancio successivo a quello per cui e' lanciato il report BILR153.
    I dati sono raggruppati per la tupla che compone la chiave logica del report:
    Missione, Programma, Codice Cofog, Codice Transazione UE, PDC, Perimetro Sanitario Spesa,
    Ricorrente Spesa, Cup.
*/

classifBilRec record;
bilancio_id integer;
RTN_MESSAGGIO text;
anno_int integer;

BEGIN
RTN_MESSAGGIO:='select 1';

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

anno_int :=p_anno::INTEGER;


return query
select distinct
	zz.missione_code, zz.programma_code, zz.code_cofog, zz.code_transaz_ue,
    zz.pdc_iv, zz.perim_sanitario_spesa, zz.ricorrente_spesa,zz.cup,
	zz.tupla_group::varchar,
	sum(zz.fondo_plur_vinc)  
from (
with clas as (
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
--insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
from missione , programma
,titusc, macroag
, siac_r_class progmacro
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 ),
capall as (
with
cap as (
select a.elem_id,
a.elem_code ,
a.elem_desc ,
a.elem_code2 ,
a.elem_desc2 ,
a.elem_id_padre ,
a.elem_code3,
d.classif_id programma_id,d2.classif_id macroag_id
from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
siac_r_bil_elem_class c2,
siac_t_class d,siac_t_class d2,
siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i
where b.elem_tipo_id=a.elem_tipo_id
and c.elem_id=a.elem_id
and c2.elem_id=a.elem_id
and d.classif_id=c.classif_id
and d2.classif_id=c2.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e2.classif_tipo_id=d2.classif_tipo_id
and g.elem_cat_id=f.elem_cat_id
and f.elem_id=a.elem_id
and h.elem_id=a.elem_id
and i.elem_stato_id=h.elem_stato_id
and a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.elem_tipo_code = 'CAP-UG'
and e.classif_tipo_code='PROGRAMMA'
and e2.classif_tipo_code='MACROAGGREGATO'
and g.elem_cat_code in	('STD','FPV','FSC','FPVC')
and i.elem_stato_code = 'VA'
and h.validita_fine is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and c2.data_cancellazione is null
and d.data_cancellazione is null
and d2.data_cancellazione is null
and e.data_cancellazione is null
and e2.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
), 
elenco_movgest as (
select distinct
r.elem_id, a.movgest_id,b.movgest_ts_id,
a.movgest_anno,
coalesce(o.movgest_ts_det_importo,0) movgest_importo
 from  siac_t_movgest a, 
 	siac_t_movgest_ts b,  
 	siac_t_movgest_ts_det o,
	siac_d_movgest_ts_det_tipo p,
    siac_d_movgest_tipo q,
    siac_r_movgest_bil_elem r ,
    siac_r_movgest_ts_stato s,
    siac_d_movgest_stato t,
    siac_d_movgest_ts_tipo u
where b.movgest_id=a.movgest_id
and o.movgest_ts_id=b.movgest_ts_id
and p.movgest_ts_det_tipo_id=o.movgest_ts_det_tipo_id
and q.movgest_tipo_id=a.movgest_tipo_id
and r.movgest_id=a.movgest_id
and s.movgest_ts_id=b.movgest_ts_id
and t.movgest_stato_id=s.movgest_stato_id
and u.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
-- VERIFICARE SE e' GIUSTO PRENDERE ANCHE I MOVGEST > 2017
-- PER estrarre Impegnato reimputato ad esercizi successivi
--and a.movgest_anno<=p_anno::INTEGER
and q.movgest_tipo_code='I'
and p.movgest_ts_det_tipo_code='A' -- importo attuale
and t.movgest_stato_code in ('D','N') 
and u.movgest_ts_tipo_code='T' 
and a.data_cancellazione is null
and b.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null
and u.data_cancellazione is null
and s.validita_fine is NULL
),
elenco_ord as(
select 
l.elem_id, f.ord_id, a.movgest_id, a.movgest_anno,
sum(coalesce(m.ord_ts_det_importo,0)) ord_importo
 from  siac_T_movgest a, siac_t_movgest_ts b,
 siac_r_liquidazione_movgest c,siac_r_liquidazione_ord d,
siac_t_ordinativo_ts e, 
siac_t_ordinativo f,
siac_d_ordinativo_tipo g,siac_r_ordinativo_stato h,
siac_d_ordinativo_stato i,siac_r_ordinativo_bil_elem l,siac_t_ordinativo_ts_det m,
siac_d_ordinativo_ts_det_tipo n
where b.movgest_id=a.movgest_id
and c.movgest_ts_id=b.movgest_ts_id
and d.liq_id=c.liq_id
and f.ord_id=e.ord_id
and d.sord_id=e.ord_ts_id
and f.ord_id=e.ord_id
and g.ord_tipo_id=f.ord_tipo_id
and i.ord_stato_id=h.ord_stato_id
and l.ord_id=f.ord_id
and m.ord_ts_id=e.ord_ts_id
and n.ord_ts_det_tipo_id=m.ord_ts_det_tipo_id
and h.ord_id=f.ord_id
and a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
--and a.movgest_anno<= p_anno::INTEGER
and g.ord_tipo_code='P'
and i.ord_stato_code<>'A'
and n.ord_ts_det_tipo_code='A'
and l.validita_fine is NULL
and h.validita_fine is NULL
and c.validita_fine is NULL
and d.validita_fine is NULL
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
group by l.elem_id, f.ord_id, a.movgest_id, a.movgest_anno
),
elenco_pdci_IV as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code pdc_iv
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_IV'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null),
elenco_pdci_V as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code classif_code_cap,
  substring(t_class.classif_code from 1 for length(t_class.classif_code)-3) ||
          '000' pdc_v
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_V'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null) ,                    
elenco_class_capitoli as (
	select * from "fnc_bilr153_tab_class_capitoli"  (p_ente_prop_id,bilancio_id)),                    
elenco_class_movgest as (
	select * from "fnc_bilr153_tab_class_movgest"  (p_ente_prop_id,bilancio_id)),
elenco_class_ord as (
	select * from "fnc_bilr153_tab_class_ord"  (p_ente_prop_id,bilancio_id)) ,
cupord as (
		select DISTINCT t_attr.attr_code attr_code_cup_ord, 
        		trim(r_ordinativo_attr.testo) testo_cup_ord,
				r_ordinativo_attr.ord_id                
        from 
               siac_t_attr t_attr,
               siac_r_ordinativo_attr  r_ordinativo_attr
              where  r_ordinativo_attr.attr_id=t_attr.attr_id   
              and  t_attr.ente_proprietario_id=p_ente_prop_id         
              AND upper(t_attr.attr_code) = 'CUP'           
                  and r_ordinativo_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL) ,
cup_movgest as(
	select DISTINCT t_attr.attr_code attr_code_cup_movgest, 
          trim(r_movgest_ts_attr.testo) testo_cup_movgest,
          r_movgest_ts_attr.movgest_ts_id,
          t_movgest_ts.movgest_id
        from 
               siac_t_attr t_attr,
               siac_r_movgest_ts_attr  r_movgest_ts_attr,
               siac_t_movgest_ts t_movgest_ts
              where  r_movgest_ts_attr.attr_id=t_attr.attr_id                 	
                and t_movgest_ts.movgest_ts_id = r_movgest_ts_attr.movgest_ts_id      
                  and t_attr.ente_proprietario_id=p_ente_prop_id         
              AND upper(t_attr.attr_code) = 'CUP'           
                  and r_movgest_ts_attr.data_cancellazione IS NULL
                  and t_attr.data_cancellazione IS NULL
                  and t_movgest_ts.data_cancellazione IS NULL),
fondo_plur as (
-- da SIAC-7702: Tale importo deve essere calcolato andando a considerare le 
-- quote di impegni vincolati a FPVSC o FPVCC dell'anno di bilancio 
-- successivo a -- quello di elaborazione ed aventi 
-- anno impegno >= anno bilancio successivo.
-- Questa funzione viene lanciata con il parametro di anni bilancio
-- successivo a quello impostato nel report.
/*    select --cap.elem_id,
    		imp.movgest_id,
            sum(r_imp_ts.movgest_ts_importo) importo_quota_vincolo
     from siac_t_movgest imp,
          siac_t_movgest_ts imp_ts,
          siac_d_movgest_ts_tipo d_imp_ts_tipo,
          siac_r_movgest_ts r_imp_ts,   
          siac_d_movgest_tipo d_imp_tipo,    
          siac_t_avanzovincolo av,
          siac_d_avanzovincolo_tipo avt,
          siac_r_movgest_bil_elem r_imp_cap,
          siac_t_bil_elem cap      
    where  imp.movgest_id=imp_ts.movgest_id
    and imp_ts.movgest_ts_id = r_imp_ts.movgest_ts_b_id
    and d_imp_ts_tipo.movgest_ts_tipo_id=imp_ts.movgest_ts_tipo_id
    and d_imp_tipo.movgest_tipo_id=imp.movgest_tipo_id   
    and r_imp_ts.avav_id = av.avav_id
    and av.avav_tipo_id=avt.avav_tipo_id
    and r_imp_cap.movgest_id=imp.movgest_id
    and cap.elem_id=r_imp_cap.elem_id
    and imp.ente_proprietario_id= p_ente_prop_id
    and imp.bil_id=bilancio_id
    and imp.movgest_anno>=anno_int
    and d_imp_tipo.movgest_tipo_code='I'
    and d_imp_ts_tipo.movgest_ts_tipo_code = 'T'
    and DATE_PART('year', av.validita_inizio) = anno_int
    and avt.avav_tipo_code in('FPVCC','FPVSC')
    and r_imp_ts.validita_fine is null
    and av.data_cancellazione IS NULL
    and imp.data_cancellazione IS NULL
    and imp_ts.data_cancellazione IS NULL
    and d_imp_ts_tipo.data_cancellazione IS NULL
    and d_imp_tipo.data_cancellazione IS NULL
    and r_imp_cap.data_cancellazione IS NULL
    and cap.data_cancellazione IS NULL
    group by imp.movgest_id */
  
--SIAC-8750 09/05/2023.
--Implementato nuovo algoritmo: si devono prendere gli importi INIZIALI degli impegni del bilancio successivo a quello del report,
--cioe' del rendiconto con anno impegno > dell'anno del rendiconto, collegati a vincoli FPV con atto <= all'anno del
--rendiconto. 
    select --cap.elem_id,
    		imp.movgest_id,
           -- sum(r_imp_ts.movgest_ts_importo) importo_quota_vincolo,
            sum(imp_ts_det.movgest_ts_det_importo) importo_iniziale_impegno 
     from siac_t_movgest imp,
          siac_t_movgest_ts imp_ts,
          siac_d_movgest_ts_tipo d_imp_ts_tipo,
          siac_r_movgest_ts r_imp_ts,   
          siac_d_movgest_tipo d_imp_tipo,    
          siac_t_avanzovincolo av,
          siac_d_avanzovincolo_tipo avt,
          siac_r_movgest_bil_elem r_imp_cap,
          siac_t_bil_elem cap ,
          siac_t_movgest_ts_det   imp_ts_det,
          siac_d_movgest_ts_det_tipo d_imp_ts_det_tipo,
          siac_r_movgest_ts_atto_amm r_imp_atto,
          siac_t_atto_amm atto
    where  imp.movgest_id=imp_ts.movgest_id
    and imp_ts.movgest_ts_id = r_imp_ts.movgest_ts_b_id
    and d_imp_ts_tipo.movgest_ts_tipo_id=imp_ts.movgest_ts_tipo_id
    and d_imp_tipo.movgest_tipo_id=imp.movgest_tipo_id   
    and r_imp_ts.avav_id = av.avav_id
    and av.avav_tipo_id=avt.avav_tipo_id
    and r_imp_cap.movgest_id=imp.movgest_id
    and cap.elem_id=r_imp_cap.elem_id
    and imp_ts_det.movgest_ts_id=imp_ts.movgest_ts_id
    and d_imp_ts_det_tipo.movgest_ts_det_tipo_id=imp_ts_det.movgest_ts_det_tipo_id
    and r_imp_atto.movgest_ts_id=imp_ts.movgest_ts_id
    and r_imp_atto.attoamm_id=atto.attoamm_id
    and imp.ente_proprietario_id= p_ente_prop_id
    and imp.bil_id= bilancio_id
    and imp.movgest_anno > anno_int-1 --anno per il quale sto facendo il rendiconto
    and d_imp_tipo.movgest_tipo_code='I'  --Impegno
    and d_imp_ts_tipo.movgest_ts_tipo_code = 'T'
    and DATE_PART('year', av.validita_inizio) = anno_int
    and avt.avav_tipo_code in('FPVCC','FPVSC')
    and d_imp_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo Iniziale 
    and atto.attoamm_anno::integer <= anno_int-1 --anno per il quale sto facendo il rendiconto
    and r_imp_ts.validita_fine is null
    and av.data_cancellazione IS NULL
    and imp.data_cancellazione IS NULL
    and imp_ts.data_cancellazione IS NULL
    and d_imp_ts_tipo.data_cancellazione IS NULL
    and d_imp_tipo.data_cancellazione IS NULL
    and r_imp_cap.data_cancellazione IS NULL
    and cap.data_cancellazione IS NULL
    and imp_ts_det.data_cancellazione IS NULL 
    and r_imp_atto.data_cancellazione IS NULL
    group by imp.movgest_id
    
    )                                  
select distinct
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.programma_id,cap.macroag_id,
COALESCE(elenco_class_capitoli.code_cofog,'') code_cofog_cap,
COALESCE(elenco_class_capitoli.code_transaz_ue,'') code_transaz_ue_cap,
COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') perim_sanitario_spesa_cap,
COALESCE(elenco_class_capitoli.ricorrente_spesa,'') ricorrente_spesa_cap,
COALESCE(elenco_class_movgest.code_cofog,'') code_cofog_movgest,
COALESCE(elenco_class_movgest.code_transaz_ue,'') code_transaz_ue_movgest,
COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') perim_sanitario_spesa_movgest,
COALESCE(elenco_class_movgest.ricorrente_spesa,'') ricorrente_spesa_movgest,
COALESCE(elenco_class_ord.code_cofog,'') code_cofog_ord,
COALESCE(elenco_class_ord.code_transaz_ue,'') code_transaz_ue_ord,
COALESCE(elenco_class_ord.perim_sanitario_spesa,'') perim_sanitario_spesa_ord,
COALESCE(elenco_class_ord.ricorrente_spesa,'') ricorrente_spesa_ord,
-- ANNA INIZIO 
--CASE WHEN  trim(COALESCE(elenco_pdci_IV.pdc_iv,'')) = ''
--        THEN elenco_pdci_V.pdc_v ::varchar 
--        ELSE elenco_pdci_IV.pdc_iv ::varchar end pdc_iv,
CASE WHEN  trim(COALESCE(elenco_class_movgest.pdc_v,'')) = ''
        THEN elenco_pdci_IV.pdc_iv ::varchar 
        ELSE elenco_class_movgest.pdc_v ::varchar end pdc_iv,
-- ANNA FINE 
COALESCE(cupord.testo_cup_ord,'') testo_cup_ord,
COALESCE(cup_movgest.testo_cup_movgest,'') testo_cup_movgest,
elenco_ord.ord_id,
COALESCE(elenco_ord.ord_importo,0) ord_importo,
elenco_movgest.elem_id,
COALESCE(elenco_movgest.movgest_anno,0) anno_movgest,
elenco_movgest.movgest_id,
COALESCE(elenco_movgest.movgest_importo,0) movgest_importo,
--SIAC-8750 09/05/2023: importo degli impegni inziali e non del vincolo.
--COALESCE(fondo_plur.importo_quota_vincolo,0) fondo_plur_vinc,
COALESCE(fondo_plur.importo_iniziale_impegno,0) fondo_plur_vinc,
CASE WHEN COALESCE(elenco_class_capitoli.code_cofog,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.code_cofog,'') = ''
              THEN COALESCE(elenco_class_ord.code_cofog,'')
              ELSE COALESCE(elenco_class_movgest.code_cofog,'')
              END
        ELSE  COALESCE(elenco_class_capitoli.code_cofog,'') end code_cofog,
CASE WHEN COALESCE(elenco_class_capitoli.code_transaz_ue,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.code_transaz_ue,'') = ''
        		THEN COALESCE(elenco_class_ord.code_transaz_ue,'')
                ELSE COALESCE(elenco_class_movgest.code_transaz_ue,'')
                END
        ELSE COALESCE(elenco_class_capitoli.code_transaz_ue,'') end code_transaz_ue,                            
CASE WHEN COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') = '' 
	or COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'')='XX' -- 25.08.2017 Sofia
    	 THEN CASE WHEN COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') = '' 
         	or COALESCE(elenco_class_movgest.perim_sanitario_spesa,'')='XX'  -- 25.08.2017 Sofia
                   THEN case when COALESCE(elenco_class_ord.perim_sanitario_spesa,'')='XX' then '' 
                   	else COALESCE(elenco_class_ord.perim_sanitario_spesa,'') end -- 25.08.2017 Sofia
                   ELSE COALESCE(elenco_class_movgest.perim_sanitario_spesa,'') 
                   END
        ELSE COALESCE(elenco_class_capitoli.perim_sanitario_spesa,'') end perim_sanitario_spesa,
 CASE WHEN COALESCE(elenco_class_capitoli.ricorrente_spesa,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.ricorrente_spesa,'') = ''
              THEN COALESCE(elenco_class_ord.ricorrente_spesa,'')::varchar
              ELSE COALESCE(elenco_class_movgest.ricorrente_spesa,'') 
              END
        ELSE COALESCE(elenco_class_capitoli.ricorrente_spesa,'') end ricorrente_spesa,
 CASE WHEN COALESCE(cup_movgest.testo_cup_movgest,'') =''
    	THEN COALESCE(cupord.testo_cup_ord,'')
        ELSE COALESCE(cup_movgest.testo_cup_movgest,'') end cup
from cap
  left join elenco_movgest on cap.elem_id=elenco_movgest.elem_id
  left join elenco_ord on elenco_ord.movgest_id=elenco_movgest.movgest_id
  left join elenco_pdci_IV on elenco_pdci_IV.elem_id=cap.elem_id 
  left join elenco_pdci_V on elenco_pdci_V.elem_id=cap.elem_id 
  left join elenco_class_capitoli on elenco_class_capitoli.elem_id=cap.elem_id
  left join elenco_class_movgest on elenco_class_movgest.movgest_id=elenco_movgest.movgest_id
  left join elenco_class_ord on elenco_class_ord.ord_id=elenco_ord.ord_id 
  left join cup_movgest on (cup_movgest.movgest_id=elenco_movgest.movgest_id
  					and cup_movgest.movgest_ts_id=elenco_movgest.movgest_ts_id)
  left join cupord on cupord.ord_id=elenco_ord.ord_id  
  --left join fondo_plur on cap.elem_id=fondo_plur.elem_id 
  left join fondo_plur on fondo_plur.movgest_id=elenco_movgest.movgest_id 
)
select --SIAC-8750 10/05/2023: occorre aggiungere un distinct per evitare di estrarre piu' volte un impegno
		--se e' collegato a piu' di un ordinativo.
	distinct
    p_anno::varchar bil_anno,
    ''::varchar missione_tipo_code,
    clas.missione_tipo_desc::varchar,
    clas.missione_code::varchar,
    clas.missione_desc::varchar,
    ''::varchar programma_tipo_code,
    clas.programma_tipo_desc::varchar,
    clas.programma_code::varchar,
    clas.programma_desc::varchar,
    ''::varchar	titusc_tipo_code,
    clas.titusc_tipo_desc::varchar,
    clas.titusc_code::varchar,
    clas.titusc_desc::varchar,
    ''::varchar macroag_tipo_code,
    clas.macroag_tipo_desc::varchar,
    clas.macroag_code::varchar,
    clas.macroag_desc::varchar,
    capall.bil_ele_code::varchar,
    capall.bil_ele_desc::varchar,
    capall.bil_ele_code2::varchar,
    capall.bil_ele_desc2::varchar,
    capall.bil_ele_id::integer,
    capall.bil_ele_id_padre::integer,
    capall.bil_ele_code3::varchar,
    capall.code_cofog::varchar,
    capall.code_transaz_ue::varchar,        
    capall.pdc_iv::varchar,
    capall.perim_sanitario_spesa::varchar,
    capall.ricorrente_spesa::varchar,  
    capall.cup::varchar,      
    	--SIAC-8750 10/05/2023: escludo i dati dell'ordinativo perche' se ne esiste  piu' di 1 collegato all'impegno 
    	--estraggo l'impegno piu' volte.
    --coalesce(capall.ord_id,0)::integer ord_id ,
    --coalesce(capall.ord_importo,0)::numeric ord_importo,
    coalesce(capall.movgest_id,0)::integer movgest_id,
    coalesce(capall.anno_movgest,0)::integer anno_movgest , 
    coalesce(capall.movgest_importo,0)::numeric movgest_importo,
--SIAC-8734 24/05/2022.
--Devo prendere tutti gli importi.    
   -- case when lag(clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
   -- perim_sanitario_spesa||ricorrente_spesa||cup::varchar)
	--	OVER (order by clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
   -- perim_sanitario_spesa||ricorrente_spesa||cup::varchar) = 
   -- clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
  --  perim_sanitario_spesa||ricorrente_spesa||cup::varchar then 0
  --  	else capall.fondo_plur_vinc end fondo_plur_vinc,            
    coalesce(capall.fondo_plur_vinc,0)::numeric fondo_plur_vinc,
    clas.missione_code||clas.programma_code||code_cofog||code_transaz_ue||pdc_iv||
    perim_sanitario_spesa||ricorrente_spesa||cup::varchar tupla_group
FROM capall left join clas on 
    clas.programma_id = capall.programma_id and    
    clas.macroag_id=capall.macroag_id
 where 
   capall.bil_ele_id is not null
   and coalesce(capall.fondo_plur_vinc,0) >0)
  as zz 
  group by zz.missione_code, zz.programma_code, zz.code_cofog, 
  zz.code_transaz_ue,  zz.pdc_iv, zz.perim_sanitario_spesa, 
  zz.ricorrente_spesa,zz.cup,  zz.tupla_group   ;


exception
    when no_data_found THEN
   		raise notice 'nessun dato trovato per struttura bilancio';
    	return;
    when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    	return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR153_struttura_dca_spese_fpv_anno_succ" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
--SIAC-8750 - Maurizio - FINE

--siac-task-issue #99 - Maurizio - INIZIO
  
DROP FUNCTION if exists siac."BILR125_rendiconto_gestione"(p_ente_prop_id integer, p_anno varchar, p_classificatori varchar);


CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;
v_anno_int integer; -- SIAC-5487
v_anno_prec_int integer; -- SIAC-5487

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

v_importo_anno_prec NUMERIC;

BEGIN

/*
Valori parametro p_classificatori:

- 1 - Conto Economico; BILR125;
- 2 - Stato Patrimoniale - Attivo; BILR128;
- 3 - Stato Patrimoniale - Passivo; BILR129;

*/

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer; -- SIAC-5487
v_anno_prec_int := p_anno::integer-1; -- SIAC-5487

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

--16/05/2023 siac-task-issue #99
--La seguente query estraeva i dati sia dell'anno corrente che di quello precedente.
--E' stata spezzata in 2 query, una per l'anno corrente l'altra per l'anno precedente per permettere la corretta gestione
--della validita' della relazione tra conto economico e la relativa classificazione (siac_r_pdce_conto_class).
WITH Importipn AS ( --Anno corrente
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    --16/05/2023 siac-task-issue #99: solo anno corrente.
    AND anno_eserc.anno IN (p_anno)--,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    --SIAC-8578 19/01/2022 i conti PP di ottavo livello devono essere esclusi.
    --AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND (pdce_fam.pdce_fam_code IN ('PP','OP') and 
    	pdce_conto.livello <> 8)
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    --16/05/2023 siac-task-issue #99: verifico solo la validita' e non la cancellazione.
   -- AND   a.data_cancellazione is null
    AND   v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;

WITH Importipn AS ( --anno precedente.
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    --16/05/2023 siac-task-issue #99: solo anno precedente.
    AND anno_eserc.anno IN (v_anno_prec) 
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    --SIAC-8578 19/01/2022 i conti PP di ottavo livello devono essere esclusi.
    --AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND (pdce_fam.pdce_fam_code IN ('PP','OP') and 
    	pdce_conto.livello <> 8)
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    --16/05/2023 siac-task-issue #99: verifico solo la validita' e non la cancellazione.
    --AND   a.data_cancellazione is null
    AND   v_anno_prec_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_prec_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;
END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       --case when zz.classif_code='26' then 'E.26' else zz.classif_code end codice_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       --case when zz.ordine='26' then 'E.26' else zz.ordine end codice_codifica_albero,
       case when zz.ordine='E.26' then 3 else zz.level end livello_codifica,
       --zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           and c.classif_id=rt1.classif_id
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
/*           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)*/
           AND v_anno_int BETWEEN date_part('year',tt1.validita_inizio) AND 
           date_part('year',COALESCE(tt1.validita_fine,now())) --SIAC-5487
           AND v_anno_int BETWEEN date_part('year',rt1.validita_inizio) AND 
           date_part('year',COALESCE(rt1.validita_fine,now())) 
           AND v_anno_int BETWEEN date_part('year',c.validita_inizio) AND 
           date_part('year',COALESCE(c.validita_fine,now())) 
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
        WHERE tp.classif_id = tn.classif_id_padre 
        and c2.classif_id=tn.classif_id
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND v_anno_int BETWEEN date_part('year',tn.validita_inizio) AND 
           date_part('year',COALESCE(tn.validita_fine,now())) 
AND v_anno_int BETWEEN date_part('year',c2.validita_inizio) AND 
           date_part('year',COALESCE(c2.validita_fine,now()))            
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, 
--case when zz.ordine='26' then 'E.26' else zz.ordine end asc
zz.ordine
/*
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc     */

LOOP
    
        
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
      	raise notice 'Codifica: % - importo_passivo 2022 = % - importo passivo 2021 = % - albero = %', 
        	classifGestione.descrizione_codifica, importo_dati_passivo, importo_dati_passivo_prec, classifGestione.codice_codifica_albero;

    END IF;
    

    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

--18/01/2022 SIAC-8196, SIAC-8557 e SIAC-8578.
--Se il conto e' passivo e se il livello e' 8 nel report BILR128 (SP Attivo)
--devo considerare il conto PP come fosse attivo (AP).
    FOR pdce IN
    SELECT case when p_classificatori ='2' and d.pdce_fam_code ='PP' and
    		b.livello = 8
    	then 'AP'
        else d.pdce_fam_code end codice_pdce_fam_code,
    e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
/*    AND   (v_anno_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           v_anno_prec_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )*/
       AND   (i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )  
    AND  v_anno_int BETWEEN date_part('year',a.validita_inizio)::integer
    AND coalesce (date_part('year',a.validita_fine)::integer ,v_anno_int) 
    GROUP BY codice_pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
        
    IF p_classificatori IN ('1','3') THEN
           
      IF pdce.movep_det_segno = 'Dare' THEN
         IF pdce.anno = p_anno THEN
            v_imp_dare := pdce.importo;
         ELSE
            v_imp_dare_prec := pdce.importo;
         END IF;   
      ELSIF pdce.movep_det_segno = 'Avere' THEN
         IF pdce.anno = p_anno THEN
            v_imp_avere := pdce.importo;
         ELSE
            v_imp_avere_prec := pdce.importo;
         END IF;                   
      END IF;               
    
      IF pdce.anno = p_anno THEN
         v_pdce_fam_code := pdce.codice_pdce_fam_code;
      ELSE
         v_pdce_fam_code_prec := pdce.codice_pdce_fam_code;
      END IF;    
        
    ELSIF p_classificatori = '2' THEN  
      IF pdce.codice_pdce_fam_code = 'AP' THEN 
      
        IF pdce.movep_det_segno = 'Dare' THEN
           IF pdce.anno = p_anno THEN
              v_imp_dare := pdce.importo;
           ELSE
              v_imp_dare_prec := pdce.importo;
           END IF;   
        ELSIF pdce.movep_det_segno = 'Avere' THEN
           IF pdce.anno = p_anno THEN
              v_imp_avere := pdce.importo;
           ELSE
              v_imp_avere_prec :=pdce.importo;
           END IF;                   
        END IF;       
      
        IF pdce.anno = p_anno THEN
           v_pdce_fam_code := pdce.codice_pdce_fam_code;
        ELSE
           v_pdce_fam_code_prec := pdce.codice_pdce_fam_code;
        END IF;      
      
      END IF;        
    END IF;  
                                                                        
    END LOOP;


        
    IF p_classificatori IN ('1','3') THEN
      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
        
    END IF;
    
/* SIAC-6296. 11/07/2018: per risolvere il problema relativo all'estrazione
	dei dati dell'anno precedente che in alcuni casi non sono estratti 
    correttamente a causa delle date di fine validita'.
    E' chiamata una copia della procedura passando in input l'anno 
    precedente.
    In questo modo si e' sicuri che i dati dell'anno precedente sono
    uguali a quelli ottenuti nel report con input anno precente. */ 
    
/* siac-task-issue #89 04/05/2023.
  La ricerca deve essere effettuata per ID del classificare e non per codice/descrizione perche' ci sono classificatori
  che hanno codice e descrizione identici ma padri differenti.       
    select a.importo_codice_bilancio
    into v_importo_anno_prec
    from "BILR125_rendiconto_gestione_anno_prec"(p_ente_prop_id, anno_prec, 
    	p_classificatori, classifGestione.codice_codifica,
        classifGestione.descrizione_codifica) a; */
select a.importo_codice_bilancio
    into v_importo_anno_prec
    from "BILR125_rendiconto_gestione_anno_prec"(p_ente_prop_id, anno_prec, 
    	p_classificatori, classifGestione.codice_codifica,
        classifGestione.descrizione_codifica, classifGestione.classif_id) a;        
  --  where a.codice_codifica = classifGestione.codice_codifica
   -- and a.descrizione_codifica = classifGestione.descrizione_codifica
   -- and a.tipo_codifica = classifGestione.tipo_codifica
   -- and a.livello_codifica = classifGestione.livello_codifica;
    
           
	v_importo_prec:=v_importo_anno_prec;
        
    raise notice 'codice_codifica = %, classif_id = % - descr_codifica = %, importo_prec = %', 
    	classifGestione.codice_codifica, classifGestione.classif_id, classifGestione.descrizione_codifica,
        v_importo_anno_prec; 
        
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

raise notice 'classif_id = %, descrizione_codifica = %, codice_raggruppamento = %, codice_subraggruppamento = %, v_importo = %, v_importo_prec = %',
    	classifGestione.classif_id,
        classifGestione.descrizione_codifica, codice_raggruppamento,
        codice_subraggruppamento, 
        v_importo, v_importo_prec;
        
    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR125_rendiconto_gestione" (p_ente_prop_id integer, p_anno varchar, p_classificatori varchar)
  OWNER TO siac;  
  
--siac-task-issue #99 - Maurizio - FINE  




-- INIZIO 4.SIAC-8750-TASK108.sql



\echo 4.SIAC-8750-TASK108.sql


--siac-task-issues #108- Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR029_soggetti_persona_giuridica" (
  p_ente_prop_id integer,
  p_codice_soggetto varchar = NULL::character varying,
  p_denominazione varchar = NULL::character varying,
  p_stato_soggetto varchar = NULL::character varying,
  p_classe_soggetto varchar = NULL::character varying,
  p_tipo_estrazione varchar = NULL::character varying
)
RETURNS TABLE (
  ambito_id integer,
  soggetto_code varchar,
  codice_fiscale varchar,
  codice_fiscale_estero varchar,
  partita_iva varchar,
  soggetto_desc varchar,
  soggetto_tipo_code varchar,
  soggetto_tipo_desc varchar,
  forma_giuridica_cat_id varchar,
  forma_giuridica_desc varchar,
  forma_giuridica_istat_codice varchar,
  soggetto_id integer,
  stato varchar,
  classe_soggetto varchar,
  desc_tipo_indirizzo varchar,
  tipo_indirizzo varchar,
  via_indirizzo varchar,
  toponimo_indirizzo varchar,
  numero_civico_indirizzo varchar,
  interno_indirizzo varchar,
  frazione_indirizzo varchar,
  comune_indirizzo varchar,
  provincia_indirizzo varchar,
  provincia_sigla_indirizzo varchar,
  stato_indirizzo varchar,
  indirizzo_id integer,
  avviso varchar,
  sede_indirizzo_id integer,
  sede_via_indirizzo varchar,
  sede_toponimo_indirizzo varchar,
  sede_numero_civico_indirizzo varchar,
  sede_interno_indirizzo varchar,
  sede_frazione_indirizzo varchar,
  sede_comune_indirizzo varchar,
  sede_provincia_indirizzo varchar,
  sede_provincia_sigla_indirizzo varchar,
  sede_stato_indirizzo varchar,
  mp_soggetto_id integer,
  mp_soggetto_desc varchar,
  mp_accredito_tipo_code varchar,
  mp_accredito_tipo_desc varchar,
  mp_modpag_stato_desc varchar,
  ricevente varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  note varchar,
  ricevente_cod_fis varchar,
  ricevente_piva varchar,
  quietanzante varchar,
  quietanzante_cod_fis varchar,
  bic varchar,
  conto_corrente varchar,
  iban varchar,
  mp_data_scadenza date,
  data_scadenza_cessione date
) AS
$body$
DECLARE
	dati_soggetto record;
    DEF_NULL	constant varchar:=''; 
    DEF_SPACES	constant varchar:=' '; 
    RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    user_table	varchar;
  
  BEGIN
  
select fnc_siac_random_user()
into	user_table;


if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_giuridica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            b.ragione_sociale,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_giuridica
        select 	a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_giuridica
	select 		a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            --19/05/2023. siac-tassk-issues #108.
            --bisogna prendere la tabella siac_t_persona_giuridica e non siac_t_persona_fisica
            --siac_t_persona_fisica 	b
            siac_t_persona_giuridica b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)          
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_giuridica
            select 	a.ambito_id,
                    a.soggetto_code,
                    a.codice_fiscale,
                    a.codice_fiscale_estero,
                    a.partita_iva,
                    b.ragione_sociale,
                    d.soggetto_tipo_code,
                    d.soggetto_tipo_desc,
                    m.forma_giuridica_cat_id,
                    m.forma_giuridica_desc,
                    m.forma_giuridica_istat_codice,
                    a.soggetto_id,
                    f.soggetto_stato_desc,
                    h.soggetto_classe_desc,
                    b.ente_proprietario_id,
                    user_table utente           
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_giuridica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_giuridica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_giuridica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_giuridica_modpag
       select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL  
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;
if coalesce(p_codice_soggetto ,DEF_NULL)=DEF_NULL	then
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione				      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and 	a.utente	=	user_table
       				and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    and 	a.utente	=	user_table
       and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    and 	a.utente	=	user_table
       and	d.utente	=	user_table)
       --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
        --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
     where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'        
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
     end loop;


  raise notice 'fine OK';
else
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione				      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and 	a.utente	=	user_table
       				and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    and 	a.utente	=	user_table
       and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    and 	a.utente	=	user_table
       and	d.utente	=	user_table)
        where a.soggetto_code	=	p_codice_soggetto
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
     	codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        soggetto_id=0;
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
       indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
       	note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;
     end loop;


  raise notice 'fine OK';
end if;    
delete from siac_rep_persona_giuridica where utente=user_table;
delete from siac_rep_persona_giuridica_recapiti where utente=user_table;
delete from siac_rep_persona_giuridica_sedi where utente=user_table;	
delete from siac_rep_persona_giuridica_modpag where utente=user_table;	

EXCEPTION
when no_data_found THEN
	raise notice 'nessun soggetto  trovato';
	return;
when others  THEN
 RTN_MESSAGGIO:='Ricerca dati soggetto';
 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR029_soggetti_persona_giuridica" (p_ente_prop_id integer, p_codice_soggetto varchar, p_denominazione varchar, p_stato_soggetto varchar, p_classe_soggetto varchar, p_tipo_estrazione varchar)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac."BILR029_soggetti_persona_fisica_e_giuridica" (
  p_ente_prop_id integer,
  p_denominazione varchar = NULL::character varying,
  p_stato_soggetto varchar = NULL::character varying,
  p_classe_soggetto varchar = NULL::character varying,
  p_tipo_estrazione varchar = NULL::character varying
)
RETURNS TABLE (
  ambito_id integer,
  soggetto_code varchar,
  codice_fiscale varchar,
  codice_fiscale_estero varchar,
  partita_iva varchar,
  soggetto_desc varchar,
  soggetto_tipo_code varchar,
  soggetto_tipo_desc varchar,
  forma_giuridica_cat_id varchar,
  forma_giuridica_desc varchar,
  forma_giuridica_istat_codice varchar,
  cognome varchar,
  nome varchar,
  comune_id_nascita integer,
  nascita_data date,
  sesso varchar,
  comune_desc varchar,
  comune_istat_code varchar,
  provincia_desc varchar,
  sigla_automobilistica varchar,
  nazione_desc varchar,
  soggetto_id integer,
  stato varchar,
  classe_soggetto varchar,
  desc_tipo_indirizzo varchar,
  tipo_indirizzo varchar,
  via_indirizzo varchar,
  toponimo_indirizzo varchar,
  numero_civico_indirizzo varchar,
  interno_indirizzo varchar,
  frazione_indirizzo varchar,
  comune_indirizzo varchar,
  provincia_indirizzo varchar,
  provincia_sigla_indirizzo varchar,
  stato_indirizzo varchar,
  indirizzo_id integer,
  avviso varchar,
  sede_indirizzo_id integer,
  sede_via_indirizzo varchar,
  sede_toponimo_indirizzo varchar,
  sede_numero_civico_indirizzo varchar,
  sede_interno_indirizzo varchar,
  sede_frazione_indirizzo varchar,
  sede_comune_indirizzo varchar,
  sede_provincia_indirizzo varchar,
  sede_provincia_sigla_indirizzo varchar,
  sede_stato_indirizzo varchar,
  mp_soggetto_id integer,
  mp_soggetto_desc varchar,
  mp_accredito_tipo_code varchar,
  mp_accredito_tipo_desc varchar,
  mp_modpag_stato_desc varchar,
  ricevente varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  note varchar,
  ricevente_cod_fis varchar,
  ricevente_piva varchar,
  quietanzante varchar,
  quietanzante_cod_fis varchar,
  bic varchar,
  conto_corrente varchar,
  iban varchar,
  tipologia_soggetto varchar,
  mp_data_scadenza date,
  data_scadenza_cessione date
) AS
$body$
DECLARE
	dati_soggetto record;
    DEF_NULL	constant varchar:=''; 
    DEF_SPACES	constant varchar:=' '; 
    RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    user_table	varchar;
  
  BEGIN
  
select fnc_siac_random_user()
into	user_table;
  
  tipologia_soggetto:='PF'; 

if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_fisica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            a.soggetto_desc,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            b.cognome,
            b.nome,
            b.comune_id_nascita,
            b.nascita_data,
            b.sesso,
            n.comune_desc,
            n.comune_istat_code,
            q.provincia_desc,
            q.sigla_automobilistica,
            r.nazione_desc,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)
            FULL  join  siac_t_comune	n	
            on    	(n.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	n.validita_fine	is null)
            FULL  join  siac_r_comune_provincia	o	
            on    	(o.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	o.validita_fine	is null)
            FULL  join  siac_t_provincia	q	
            on    	(q.provincia_id	=	o.provincia_id
                        and	q.ente_proprietario_id	=	o.ente_proprietario_id
                        and	q.validita_fine	is null)
            FULL  join  siac_t_nazione	r	
            on    	(n.nazione_id	=	r.nazione_id
                        and	r.ente_proprietario_id	=	n.ente_proprietario_id
                        and	r.validita_fine	is null)           
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_fisica
        select 	a.ambito_id					ambito_id,
                a.soggetto_code				soggetto_code,
                a.codice_fiscale			codice_fiscale,
                a.codice_fiscale_estero		codice_fiscale_estero, 
                a.partita_iva				partita_iva, 
                a.soggetto_desc				soggetto_desc, 
                d.soggetto_tipo_code		soggetto_tipo_code, 
                d.soggetto_tipo_desc		soggetto_tipo_desc,
                m.forma_giuridica_cat_id	forma_giuridica_cat_id,
                m.forma_giuridica_desc		forma_giuridica_desc,
                m.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
                b.cognome					cognome,
                b.nome						nome,  
                b.comune_id_nascita			comune_id_nascita, 
                b.nascita_data				nascita_data,
                b.sesso						sesso,
                n.comune_desc 				comune_desc,
                n.comune_istat_code 		comune_istat_code,
                q.provincia_desc			provincia_desc,
                q.sigla_automobilistica		sigla_automobilistica,
                r.nazione_desc				nazione_desc, 
                a.soggetto_id				soggetto_id,
                f.soggetto_stato_desc		stato,
                h.soggetto_classe_desc		classe_soggetto,
                b.ente_proprietario_id,
                user_table utente             
        from 	
                siac_r_soggetto_tipo 	c, 
                siac_d_soggetto_tipo 	d,
                siac_r_soggetto_stato	e,
                siac_d_soggetto_stato	f,
                siac_t_soggetto 		a,
                siac_t_persona_fisica 	b
                FULL  join siac_r_soggetto_classe	g
                on    	(b.soggetto_id		=	g.soggetto_id
                            and	g.ente_proprietario_id	=	b.ente_proprietario_id
                            and	g.validita_fine	is null)
                FULL  join  siac_d_soggetto_classe	h	
                on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                            and	h.ente_proprietario_id	=	g.ente_proprietario_id
                            and	h.validita_fine	is null)
                FULL  join  siac_r_forma_giuridica	p	
                on    	(b.soggetto_id			=	p.soggetto_id
                            and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                FULL  join  siac_t_forma_giuridica	m	
                on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                            and	p.ente_proprietario_id	=	m.ente_proprietario_id
                            and	p.validita_fine	is null)
                FULL  join  siac_t_comune	n	
                on    	(n.comune_id	=	b.comune_id_nascita
                            and	n.ente_proprietario_id	=	b.ente_proprietario_id
                            and	n.validita_fine	is null)
                FULL  join  siac_r_comune_provincia	o	
                on    	(o.comune_id	=	b.comune_id_nascita
                            and	n.ente_proprietario_id	=	b.ente_proprietario_id
                            and	o.validita_fine	is null)
                FULL  join  siac_t_provincia	q	
                on    	(q.provincia_id	=	o.provincia_id
                            and	q.ente_proprietario_id	=	o.ente_proprietario_id
                            and	q.validita_fine	is null)
                FULL  join  siac_t_nazione	r	
                on    	(n.nazione_id	=	r.nazione_id
                            and	r.ente_proprietario_id	=	n.ente_proprietario_id
                            and	r.validita_fine	is null)           
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_fisica
select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            a.soggetto_desc,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            b.cognome,
            b.nome,
            b.comune_id_nascita,
            b.nascita_data,
            b.sesso,
            n.comune_desc,
            n.comune_istat_code,
            q.provincia_desc,
            q.sigla_automobilistica,
            r.nazione_desc,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_fisica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)
            FULL  join  siac_t_comune	n	
            on    	(n.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	n.validita_fine	is null)
            FULL  join  siac_r_comune_provincia	o	
            on    	(o.comune_id	=	b.comune_id_nascita
                        and	n.ente_proprietario_id	=	b.ente_proprietario_id
                        and	o.validita_fine	is null)
            FULL  join  siac_t_provincia	q	
            on    	(q.provincia_id	=	o.provincia_id
                        and	q.ente_proprietario_id	=	o.ente_proprietario_id
                        and	q.validita_fine	is null)
            FULL  join  siac_t_nazione	r	
            on    	(n.nazione_id	=	r.nazione_id
                        and	r.ente_proprietario_id	=	n.ente_proprietario_id
                        and	r.validita_fine	is null)           
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_fisica
            select 	a.ambito_id					ambito_id,
                    a.soggetto_code				soggetto_code,
                    a.codice_fiscale			codice_fiscale,
                    a.codice_fiscale_estero		codice_fiscale_estero, 
                    a.partita_iva				partita_iva, 
                    a.soggetto_desc				soggetto_desc, 
                    d.soggetto_tipo_code		soggetto_tipo_code, 
                    d.soggetto_tipo_desc		soggetto_tipo_desc,
                    m.forma_giuridica_cat_id	forma_giuridica_cat_id,
                    m.forma_giuridica_desc		forma_giuridica_desc,
                    m.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
                    b.cognome					cognome,
                    b.nome						nome,  
                    b.comune_id_nascita			comune_id_nascita, 
                    b.nascita_data				nascita_data,
                    b.sesso						sesso,
                    n.comune_desc 				comune_desc,
                    n.comune_istat_code 		comune_istat_code,
                    q.provincia_desc			provincia_desc,
                    q.sigla_automobilistica		sigla_automobilistica,
                    r.nazione_desc				nazione_desc, 
                    a.soggetto_id				soggetto_id,
                    f.soggetto_stato_desc		stato,
                    h.soggetto_classe_desc		classe_soggetto,
                    b.ente_proprietario_id,
                    user_table utente             
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    FULL  join  siac_t_comune	n	
                    on    	(n.comune_id	=	b.comune_id_nascita
                                and	n.ente_proprietario_id	=	b.ente_proprietario_id
                                and	n.validita_fine	is null)
                    FULL  join  siac_r_comune_provincia	o	
                    on    	(o.comune_id	=	b.comune_id_nascita
                                and	n.ente_proprietario_id	=	b.ente_proprietario_id
                                and	o.validita_fine	is null)
                    FULL  join  siac_t_provincia	q	
                    on    	(q.provincia_id	=	o.provincia_id
                                and	q.ente_proprietario_id	=	o.ente_proprietario_id
                                and	q.validita_fine	is null)
                    FULL  join  siac_t_nazione	r	
                    on    	(n.nazione_id	=	r.nazione_id
                                and	r.ente_proprietario_id	=	n.ente_proprietario_id
                                and	r.validita_fine	is null)           
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_fisica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_fisica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_fisica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_fisica_modpag
    select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL  
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;

for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.cognome					cognome,
            a.nome						nome,  
            a.comune_id_nascita			comune_id_nascita, 
            a.nascita_data				nascita_data,
            a.sesso						sesso,
            a.comune_desc 				comune_desc,
            a.comune_istat_code 		comune_istat_code,
            coalesce (a.provincia_desc,DEF_SPACES)				provincia_desc,
            coalesce (a.sigla_automobilistica,DEF_SPACES)		sigla_automobilistica,
            coalesce (a.nazione_desc,DEF_SPACES)				nazione_desc, 
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
            d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione	
            
    from siac_rep_persona_fisica	a
    LEFT join	siac_rep_persona_fisica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  	and a.utente	=	user_table
                    and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_fisica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    	and a.utente	=	user_table
        and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_fisica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    	and a.utente	=	user_table
        and	d.utente	=	user_table)
    --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
    --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
    where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'
    order by a.soggetto_desc
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        cognome:=dati_soggetto.cognome;
        nome:=dati_soggetto.nome;
        comune_id_nascita:=dati_soggetto.comune_id_nascita;
        nascita_data:=dati_soggetto.nascita_data;
        sesso:=dati_soggetto.sesso;
        soggetto_id:=dati_soggetto.soggetto_id;
        comune_desc:=dati_soggetto.comune_desc;
        comune_istat_code:=dati_soggetto.comune_istat_code;
        provincia_desc:=dati_soggetto.provincia_desc;
        sigla_automobilistica:=dati_soggetto.sigla_automobilistica;
        nazione_desc:=dati_soggetto.nazione_desc;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
        mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        ------tipologia_soggetto:=dati_soggetto.tipologia_soggetto;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
        codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        cognome='';
       nome='';
        comune_id_nascita=0;
        nascita_data=NULL;
        sesso='';
        soggetto_id=0;
        comune_desc='';
        comune_istat_code='';
        provincia_desc='';
        sigla_automobilistica='';
        nazione_desc='';
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
        indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';				
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
        note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;   
     end loop;
     
 tipologia_soggetto:='PG';      

if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_giuridica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            b.ragione_sociale,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_giuridica
        select 	a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_giuridica
	select 		a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            --19/05/2023. siac-tassk-issues #108.
            --bisogna prendere la tabella siac_t_persona_giuridica e non siac_t_persona_fisica            
           -- siac_t_persona_fisica 	b
            siac_t_persona_giuridica b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)          
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_giuridica
            select 	a.ambito_id,
                    a.soggetto_code,
                    a.codice_fiscale,
                    a.codice_fiscale_estero,
                    a.partita_iva,
                    b.ragione_sociale,
                    d.soggetto_tipo_code,
                    d.soggetto_tipo_desc,
                    m.forma_giuridica_cat_id,
                    m.forma_giuridica_desc,
                    m.forma_giuridica_istat_codice,
                    a.soggetto_id,
                    f.soggetto_stato_desc,
                    h.soggetto_classe_desc,
                    b.ente_proprietario_id,
                    user_table utente           
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_giuridica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_giuridica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_giuridica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_giuridica_modpag
       select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL 
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza 
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;

for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
    on (a.soggetto_id	=	b.soggetto_id
       and 	a.utente	=	user_table
       and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    	and a.utente	=	user_table
        and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    	and a.utente	=	user_table
        and	d.utente	=	user_table)
    --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
    --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
    where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'
    
    order by a.soggetto_desc	
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        -------tipologia_soggetto:=dati_soggetto.tipologia_soggetto;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
     	codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        soggetto_id=0;
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
       indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
       	note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;
     end loop;


  raise notice 'fine OK';
  
delete from siac_rep_persona_fisica where utente=user_table;
delete from siac_rep_persona_fisica_recapiti where utente=user_table;
delete from siac_rep_persona_fisica_sedi where utente=user_table;	
delete from siac_rep_persona_fisica_modpag where utente=user_table;
delete from siac_rep_persona_giuridica where utente=user_table;
delete from siac_rep_persona_giuridica_recapiti where utente=user_table;
delete from siac_rep_persona_giuridica_sedi where utente=user_table;	
delete from siac_rep_persona_giuridica_modpag where utente=user_table;	
  
EXCEPTION
when no_data_found THEN
	raise notice 'nessun soggetto  trovato';
	return;
when others  THEN
 RTN_MESSAGGIO:='Ricerca dati soggetto';
 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR029_soggetti_persona_fisica_e_giuridica" (p_ente_prop_id integer, p_denominazione varchar, p_stato_soggetto varchar, p_classe_soggetto varchar, p_tipo_estrazione varchar)
  OWNER TO siac;

  
--siac-task-issues #108 - Maurizio - FINE  




-- INIZIO 5.SIAC-8750-TASK87.sql



\echo 5.SIAC-8750-TASK87.sql


--siac-task-issues #87 - Maurizio - INIZIO

--Imposto la posizione delle variabili esistenti.
update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=1
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>1
and rep_imp.repimp_codice='ava_amm_sc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=2
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>2
and rep_imp.repimp_codice='rip_dis_prec'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=3
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>3
and rep_imp.repimp_codice='fpv_vinc_sc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=4
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>4
and rep_imp.repimp_codice='ent_est_prestiti_cc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=5
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>5
and rep_imp.repimp_codice='ent_est_prestiti'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=6
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>6
and rep_imp.repimp_codice='ent_disp_legge'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=7
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>7
and rep_imp.repimp_codice='di_cui_fondo_ant_liq_spese'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=8
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>8
and rep_imp.repimp_codice='di_cui_est_ant_pre'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=9
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>9
and rep_imp.repimp_codice='ava_amm_si'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=10
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>10
and rep_imp.repimp_codice='fpv_vinc_cc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=11
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>11
and rep_imp.repimp_codice='disava_pregr'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=12
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>12
and rep_imp.repimp_codice='ava_amm_af'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=13
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>13
and rep_imp.repimp_codice='fpv_incr_att_fin_inscr_ent'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=15
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>15
and rep_imp.repimp_codice='s_fpv_sc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=16
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>16
and rep_imp.repimp_codice='s_entrate_tit123_vinc_dest'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=17
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>17
and rep_imp.repimp_codice='s_entrate_tit123_ssn'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=18
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>18
and rep_imp.repimp_codice='s_spese_vinc_dest'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=19
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>19
and rep_imp.repimp_codice='s_fpv_pc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - siac-task-issue#87',
    posizione_stampa=20
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,4,5,10,11,14,16)
and rep.rep_codice='BILR006'
and per.anno::integer >=2022
and r_rep_imp.posizione_stampa<>20
and rep_imp.repimp_codice='s_sc_ssn'
and r_rep_imp.data_cancellazione IS NULL);
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'util_ris_amm_fin_spese_corr',
	'Utilizzo risultato di amministrazione destinato al finanziamento di spese correnti e al rimborso di prestiti al netto del Fondo anticipazione di liquidita''',
	NULL,
	'N',
	22,
	bil.bil_id,
    per2.periodo_id,
	now(),
	NULL,
	bil.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'siac-task-issue#87'
from  siac_t_bil bil, 
siac_t_periodo per, siac_d_periodo_tipo tipo_per,
siac_t_periodo per2, siac_d_periodo_tipo tipo_per2
where bil.periodo_id = per.periodo_id
and tipo_per.periodo_tipo_id=per.periodo_tipo_id
and per2.ente_proprietario_id=per.ente_proprietario_id
and tipo_per2.periodo_tipo_id=per2.periodo_tipo_id
and bil.ente_proprietario_id  in (2,4,5,10,11,14,16)
and per.anno::integer >= 2022  --anno di bilancio
and tipo_per.periodo_tipo_code='SY'
and per2.anno in (per.anno)  --anno della variabile
and tipo_per2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=bil.ente_proprietario_id 
	  and z.bil_id = bil.bil_id
	  and z.periodo_id = per2.periodo_id
      and z.repimp_codice='util_ris_amm_fin_spese_corr');

--Inserisco la nuova variabile in posizione 14.

      
      

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR006'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
14 posizione_stampa, 
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'siac-task-issue#87' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('util_ris_amm_fin_spese_corr')
and c.anno::INTEGER>=2022
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR006'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));  
				

--correggo la descrizione di 2 variabili per i caratteri accentati.
update siac_t_report_importi
set repimp_desc='Utilizzo risultato presunto di amministrazione per il finanziamento di spese d''investimento',
	data_modifica=now(),
	login_operazione=login_operazione || ' - siac-task-issue#87'
where repimp_codice in('ava_amm_si')
and repimp_id in(select r_rep_imp.repimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id=r_rep_imp.rep_id
	and r_rep_imp.repimp_id=rep_imp.repimp_id
    and rep_imp.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and rep.rep_codice='BILR006'
    and per.anno::INTEGER >= 2022);    

update siac_t_report_importi
set repimp_desc='Utilizzo risultato presunto di amministrazione al finanziamento di attivia'' finanziarie',
	data_modifica=now(),
	login_operazione=login_operazione || ' - siac-task-issue#87'
where repimp_codice in('ava_amm_af')
and repimp_id in(select r_rep_imp.repimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id=r_rep_imp.rep_id
	and r_rep_imp.repimp_id=rep_imp.repimp_id
    and rep_imp.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and rep.rep_codice='BILR006'
    and per.anno::INTEGER >= 2022);    
	
--aggiorno la tabella di appoggio la configurazione delle variabili.
delete from bko_t_report_importi rep
where rep.rep_codice in('BILR006');

insert into bko_t_report_importi(
	rep_codice, rep_desc,  repimp_codice ,  repimp_desc,
  repimp_importo,  repimp_modificabile,  repimp_progr_riga, posizione_stampa)
select DISTINCT rep.rep_codice, rep.rep_desc, rep_imp.repimp_codice,
rep_imp.repimp_desc, case when rep_imp.repimp_codice ='util_ris_amm_fin_spese_corr' then NULL else 0 end, 
rep_imp.repimp_modificabile,
rep_imp.repimp_progr_riga, r_rep_imp.posizione_stampa
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id=r_rep_imp.rep_id
	and r_rep_imp.repimp_id=rep_imp.repimp_id
    and rep_imp.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
    and per.anno='2022'
    and rep.rep_codice in('BILR006')
    and rep.data_cancellazione IS NULL
    and rep_imp.data_cancellazione IS NULL
    and r_rep_imp.data_cancellazione IS NULL
	and not exists (select 1
				    from bko_t_report_importi
                    where rep_codice = rep.rep_codice
                    and repimp_codice=rep_imp.repimp_codice); 

					
					
--siac-task-issues #87 - Maurizio - FINE  




-- INIZIO 6.SIAC-TASK-109.sql



\echo 6.SIAC-TASK-109.sql


CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_capitolo_spesa(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE

  rec_elem_id record;
  rec_classif_id record;
  rec_attr record;
  rec_elem_dett record;
  -- Variabili per campi estratti dal cursore rec_elem_id
  v_ente_proprietario_id INTEGER := null;
  v_ente_denominazione VARCHAR := null;
  v_anno VARCHAR := null;
  v_fase_operativa_code VARCHAR := null;
  v_fase_operativa_desc VARCHAR := null;
  v_elem_code VARCHAR := null;
  v_elem_code2 VARCHAR := null;
  v_elem_code3 VARCHAR := null;
  v_elem_desc VARCHAR := null;
  v_elem_desc2 VARCHAR := null;
  v_elem_tipo_code VARCHAR := null;
  v_elem_tipo_desc VARCHAR := null;
  v_elem_stato_code VARCHAR := null;
  v_elem_stato_desc VARCHAR := null;
  v_elem_cat_code VARCHAR := null;
  v_elem_cat_desc VARCHAR := null;
  -- Variabili per classificatori in gerarchia
  v_codice_titolo_spesa VARCHAR;
  v_descrizione_titolo_spesa VARCHAR;
  v_codice_macroaggregato_spesa VARCHAR;
  v_descrizione_macroaggregato_spesa VARCHAR;
  v_codice_missione_spesa VARCHAR;
  v_descrizione_missione_spesa VARCHAR;
  v_codice_programma_spesa VARCHAR;
  v_descrizione_programma_spesa VARCHAR;
  v_codice_pdc_finanziario_I VARCHAR := null;
  v_descrizione_pdc_finanziario_I VARCHAR := null;
  v_codice_pdc_finanziario_II VARCHAR := null;
  v_descrizione_pdc_finanziario_II VARCHAR := null;
  v_codice_pdc_finanziario_III VARCHAR := null;
  v_descrizione_pdc_finanziario_III VARCHAR := null;
  v_codice_pdc_finanziario_IV VARCHAR := null;
  v_descrizione_pdc_finanziario_IV VARCHAR := null;
  v_codice_pdc_finanziario_V VARCHAR := null;
  v_descrizione_pdc_finanziario_V VARCHAR := null;
  v_codice_cofog_divisione VARCHAR := null;
  v_descrizione_cofog_divisione VARCHAR := null;
  v_codice_cofog_gruppo VARCHAR := null;
  v_descrizione_cofog_gruppo VARCHAR := null;
  v_codice_cdr VARCHAR := null;
  v_descrizione_cdr VARCHAR := null;
  v_codice_cdc VARCHAR := null;
  v_descrizione_cdc VARCHAR := null;
  v_codice_siope_I_spesa VARCHAR := null;
  v_descrizione_siope_I_spesa VARCHAR := null;
  v_codice_siope_II_spesa VARCHAR := null;
  v_descrizione_siope_II_spesa VARCHAR := null;
  v_codice_siope_III_spesa VARCHAR := null;
  v_descrizione_siope_III_spesa VARCHAR := null;
  -- Variabili per classificatori non in gerarchia
  v_codice_spesa_ricorrente VARCHAR := null;
  v_descrizione_spesa_ricorrente VARCHAR := null;
  v_codice_transazione_spesa_ue VARCHAR := null;
  v_descrizione_transazione_spesa_ue VARCHAR := null;
  v_codice_tipo_fondo VARCHAR := null;
  v_descrizione_tipo_fondo VARCHAR := null;
  v_codice_tipo_finanziamento VARCHAR := null;
  v_descrizione_tipo_finanziamento VARCHAR := null;
  v_codice_politiche_regionali_unitarie VARCHAR := null;
  v_descrizione_politiche_regionali_unitarie VARCHAR := null;
  v_codice_perimetro_sanitario_spesa VARCHAR := null;
  v_descrizione_perimetro_sanitario_spesa VARCHAR := null;
  v_classificatore_generico_1 VARCHAR := null;
  v_classificatore_generico_1_descrizione_valore VARCHAR := null;
  v_classificatore_generico_1_valore VARCHAR := null;
  v_classificatore_generico_2 VARCHAR := null;
  v_classificatore_generico_2_descrizione_valore VARCHAR := null;
  v_classificatore_generico_2_valore VARCHAR := null;
  v_classificatore_generico_3 VARCHAR := null;
  v_classificatore_generico_3_descrizione_valore VARCHAR := null;
  v_classificatore_generico_3_valore VARCHAR := null;
  v_classificatore_generico_4 VARCHAR := null;
  v_classificatore_generico_4_descrizione_valore VARCHAR := null;
  v_classificatore_generico_4_valore VARCHAR := null;
  v_classificatore_generico_5 VARCHAR := null;
  v_classificatore_generico_5_descrizione_valore VARCHAR := null;
  v_classificatore_generico_5_valore VARCHAR := null;
  v_classificatore_generico_6 VARCHAR := null;
  v_classificatore_generico_6_descrizione_valore VARCHAR := null;
  v_classificatore_generico_6_valore VARCHAR := null;
  v_classificatore_generico_7 VARCHAR := null;
  v_classificatore_generico_7_descrizione_valore VARCHAR := null;
  v_classificatore_generico_7_valore VARCHAR := null;
  v_classificatore_generico_8 VARCHAR := null;
  v_classificatore_generico_8_descrizione_valore VARCHAR := null;
  v_classificatore_generico_8_valore VARCHAR := null;
  v_classificatore_generico_9 VARCHAR := null;
  v_classificatore_generico_9_descrizione_valore VARCHAR := null;
  v_classificatore_generico_9_valore VARCHAR := null;
  v_classificatore_generico_10 VARCHAR := null;
  v_classificatore_generico_10_descrizione_valore VARCHAR := null;
  v_classificatore_generico_10_valore VARCHAR := null;
  v_classificatore_generico_11 VARCHAR := null;
  v_classificatore_generico_11_descrizione_valore VARCHAR := null;
  v_classificatore_generico_11_valore VARCHAR := null;
  v_classificatore_generico_12 VARCHAR := null;
  v_classificatore_generico_12_descrizione_valore VARCHAR := null;
  v_classificatore_generico_12_valore VARCHAR := null;
  v_classificatore_generico_13 VARCHAR := null;
  v_classificatore_generico_13_descrizione_valore VARCHAR := null;
  v_classificatore_generico_13_valore VARCHAR:= null;
  v_classificatore_generico_14 VARCHAR := null;
  v_classificatore_generico_14_descrizione_valore VARCHAR := null;
  v_classificatore_generico_14_valore VARCHAR := null;
  v_classificatore_generico_15 VARCHAR := null;
  v_classificatore_generico_15_descrizione_valore VARCHAR := null;
  v_classificatore_generico_15_valore VARCHAR := null;
  v_codice_risorse_accantonamento VARCHAR     := null;
  v_descrizione_risorse_accantonamento VARCHAR := null;
  -- Variabili per attributi
  v_FlagEntrateRicorrenti VARCHAR := null;
  v_FlagFunzioniDelegate VARCHAR := null;
  v_FlagImpegnabile VARCHAR := null;
  v_FlagPerMemoria VARCHAR := null;
  v_FlagRilevanteIva VARCHAR := null;
  v_FlagTrasferimentoOrganiComunitari VARCHAR := null;
  v_Note VARCHAR := null;
  -- Variabili per stipendio
  v_codice_stipendio VARCHAR := null;
  v_descrizione_stipendio VARCHAR := null;
  -- Variabili per attivita' iva
  v_codice_attivita_iva VARCHAR := null;
  v_descrizione_attivita_iva VARCHAR := null;
  -- Variabili per i campi di detaglio degli elementi
  v_massimo_impegnabile_anno1 NUMERIC := null;
  v_stanziamento_cassa_anno1 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno1  NUMERIC := null;
  v_stanziamento_anno1 NUMERIC := null;
  v_stanziamento_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_anno1  NUMERIC := null;
  v_flag_anno1 VARCHAR := null;
  v_massimo_impegnabile_anno2 NUMERIC := null;
  v_stanziamento_cassa_anno2 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno2 NUMERIC := null;
  v_stanziamento_anno2 NUMERIC := null;
  v_stanziamento_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_anno2 NUMERIC := null;
  v_flag_anno2 VARCHAR := null;
  v_massimo_impegnabile_anno3 NUMERIC := null;
  v_stanziamento_cassa_anno3 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno3 NUMERIC := null;
  v_stanziamento_anno3 NUMERIC := null;
  v_stanziamento_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_anno3 NUMERIC := null;
  v_flag_anno3 VARCHAR := null;
  -- Variabili per campi funzione
  v_disponibilita_impegnare_anno1 NUMERIC := null;
  v_disponibilita_impegnare_anno2 NUMERIC := null;
  v_disponibilita_impegnare_anno3 NUMERIC := null;
  -- Variabili utili per il caricamento
  v_classif_code VARCHAR := null;
  v_classif_desc VARCHAR := null;
  v_classif_tipo_code VARCHAR := null;
  v_classif_tipo_desc VARCHAR := null;
  v_elem_id INTEGER := null;
  v_classif_id INTEGER := null;
  v_classif_id_part INTEGER := null;
  v_classif_id_padre INTEGER := null;
  v_classif_tipo_id INTEGER := null;
  v_classif_fam_id INTEGER := null;
  v_conta_ciclo_classif INTEGER := null;
  v_anno_elem_dett INTEGER := null;
  v_anno_appo INTEGER := null;
  v_flag_attributo VARCHAR := null;
  v_bil_id INTEGER := null;

  v_fnc_result VARCHAR := null;
  --SIAC-5895
  v_bil_id_prec INTEGER:=null;
  v_anno_prec INTEGER:=null;
  v_elem_tipo_id INTEGER:=null;
  v_ex_anno VARCHAR:=null;
  v_ex_capitolo VARCHAR:= null;
  v_ex_articolo VARCHAR:=null;

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
'fnc_siac_dwh_capitolo_spesa',
params,
clock_timestamp(),
v_user_table
);

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

-- SIAC-5895
esito:= '  Inizio Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;
select tb.bil_id,tp.anno
into v_bil_id_prec, v_anno_prec
from siac.siac_t_periodo tp
INNER JOIN siac.siac_t_bil tb  ON tb.periodo_id = tp.periodo_id
where tp.ente_proprietario_id = p_ente_proprietario_id
and   tp.anno::integer = p_anno_bilancio::integer-1;
esito:= '  Fine Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;

-- SIAC-6007
esito:= '  Inizio Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;
select elem_tipo_id
into v_elem_tipo_id
from siac_d_bil_elem_tipo
where elem_tipo_code = 'CAP-UG'
and   ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id
AND bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre gli elementi
FOR rec_elem_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
       dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
       tbe.elem_id, tb.bil_id
       --, tbe.elem_tipo_id COMMENTATO PER SIAC-6007
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tb.periodo_id = tp.periodo_id
INNER JOIN siac.siac_t_ente_proprietario tep ON tb.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                               AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                               AND rbec.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                              AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                              AND dbec.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dbet.elem_tipo_code in ('CAP-UG', 'CAP-UP')
AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
AND tbe.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
AND dbet.data_cancellazione IS NULL
AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
AND rbes.data_cancellazione IS NULL
AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
AND dbes.data_cancellazione IS NULL

LOOP
v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_elem_code := null;
v_elem_code2 := null;
v_elem_code3 := null;
v_elem_desc := null;
v_elem_desc2 := null;
v_elem_tipo_code := null;
v_elem_tipo_desc := null;
v_elem_stato_code := null;
v_elem_stato_desc := null;
v_elem_cat_code := null;
v_elem_cat_desc := null;

v_elem_id := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null;

v_ente_proprietario_id := rec_elem_id.ente_proprietario_id;
v_ente_denominazione := rec_elem_id.ente_denominazione;
v_anno := rec_elem_id.anno;
v_elem_code := rec_elem_id.elem_code;
v_elem_code2 := rec_elem_id.elem_code2;
v_elem_code3 := rec_elem_id.elem_code3;

-- 14.02.2020 Sofia jira SIAC-7329
 --v_elem_desc := rec_elem_id.elem_desc;
v_elem_desc := translate( rec_elem_id.elem_desc,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

/* sostuito con translate
  v_elem_desc := replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
     replace(
      replace(
       replace(
         replace(rec_elem_id.elem_desc::text,chr(1),' '),
          chr(2),' '),
          chr(3),' '),
          chr(4),' '),
          chr(5),' '),
          chr(6),' '),
          chr(6),' '),
          chr(7),' '),
          chr(8),' '),
          chr(9),' '),
          chr(10),' '),
          chr(11),' '),
          chr(12),' '),
          chr(13),' '),
          chr(14),' '),
          chr(15),' '),
          chr(16),' '),
          chr(17),' '),
          chr(18),' '),
          chr(19),' '),
          chr(20),' '),
          chr(21),' '),
          chr(22),' '),
          chr(23),' '),
          chr(24),' '),
          chr(25),' '),
          chr(26),' '),
          chr(27),' '),
          chr(28),' '),
          chr(29),' '),
          chr(30),' '),
          chr(31),' '),
          chr(126),' '),
          chr(127),' ');*/

-- 14.02.2020 Sofia jira SIAC-7329
--v_elem_desc2 := rec_elem_id.elem_desc2;

v_elem_desc2 :=
translate( rec_elem_id.elem_desc2,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

/* sostituito con translate
 v_elem_desc2 := replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
     replace(
      replace(
       replace(
         replace(rec_elem_id.elem_desc2::text,chr(1),' '),
          chr(2),' '),
          chr(3),' '),
          chr(4),' '),
          chr(5),' '),
          chr(6),' '),
          chr(6),' '),
          chr(7),' '),
          chr(8),' '),
          chr(9),' '),
          chr(10),' '),
          chr(11),' '),
          chr(12),' '),
          chr(13),' '),
          chr(14),' '),
          chr(15),' '),
          chr(16),' '),
          chr(17),' '),
          chr(18),' '),
          chr(19),' '),
          chr(20),' '),
          chr(21),' '),
          chr(22),' '),
          chr(23),' '),
          chr(24),' '),
          chr(25),' '),
          chr(26),' '),
          chr(27),' '),
          chr(28),' '),
          chr(29),' '),
          chr(30),' '),
          chr(31),' '),
          chr(126),' '),
          chr(127),' ');*/

v_elem_tipo_code := rec_elem_id.elem_tipo_code;
v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
v_elem_stato_code := rec_elem_id.elem_stato_code;
v_elem_stato_desc := rec_elem_id.elem_stato_desc;
v_elem_cat_code := rec_elem_id.elem_cat_code;
v_elem_cat_desc := rec_elem_id.elem_cat_desc;

v_elem_id := rec_elem_id.elem_id;
v_anno_appo := rec_elem_id.anno::integer;
v_bil_id := rec_elem_id.bil_id;

-- Sezione per estrarre i classificatori
v_codice_titolo_spesa := null;
v_descrizione_titolo_spesa := null;
v_codice_macroaggregato_spesa := null;
v_descrizione_macroaggregato_spesa := null;
v_codice_missione_spesa := null;
v_descrizione_missione_spesa := null;
v_codice_programma_spesa := null;
v_descrizione_programma_spesa := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_cofog_divisione := null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_codice_cdr := null;
v_descrizione_cdr := null;
v_codice_cdc := null;
v_descrizione_cdc := null;
v_codice_siope_I_spesa := null;
v_descrizione_siope_I_spesa := null;
v_codice_siope_II_spesa:= null;
v_descrizione_siope_II_spesa := null;
v_codice_siope_III_spesa := null;
v_descrizione_siope_III_spesa := null;

v_codice_spesa_ricorrente := null;
v_descrizione_spesa_ricorrente := null;
v_codice_transazione_spesa_ue := null;
v_descrizione_transazione_spesa_ue := null;
v_codice_tipo_fondo := null;
v_descrizione_tipo_fondo := null;
v_codice_tipo_finanziamento := null;
v_descrizione_tipo_finanziamento := null;
v_codice_politiche_regionali_unitarie := null;
v_descrizione_politiche_regionali_unitarie := null;
v_codice_perimetro_sanitario_spesa := null;
v_descrizione_perimetro_sanitario_spesa := null;
v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;
v_classificatore_generico_6:= null;
v_classificatore_generico_6_descrizione_valore:= null;
v_classificatore_generico_6_valore:= null;
v_classificatore_generico_7:= null;
v_classificatore_generico_7_descrizione_valore:= null;
v_classificatore_generico_7_valore:= null;
v_classificatore_generico_8:= null;
v_classificatore_generico_8_descrizione_valore:= null;
v_classificatore_generico_8_valore:= null;
v_classificatore_generico_9:= null;
v_classificatore_generico_9_descrizione_valore:= null;
v_classificatore_generico_9_valore:= null;
v_classificatore_generico_10:= null;
v_classificatore_generico_10_descrizione_valore:= null;
v_classificatore_generico_10_valore:= null;
v_classificatore_generico_11:= null;
v_classificatore_generico_11_descrizione_valore:= null;
v_classificatore_generico_11_valore:= null;
v_classificatore_generico_12:= null;
v_classificatore_generico_12_descrizione_valore:= null;
v_classificatore_generico_12_valore:= null;
v_classificatore_generico_13:= null;
v_classificatore_generico_13_descrizione_valore:= null;
v_classificatore_generico_13_valore:= null;
v_classificatore_generico_14:= null;
v_classificatore_generico_14_descrizione_valore:= null;
v_classificatore_generico_14_valore:= null;
v_classificatore_generico_15:= null;
v_classificatore_generico_15_descrizione_valore:= null;
v_classificatore_generico_15_valore:= null;
v_codice_risorse_accantonamento      := null;
v_descrizione_risorse_accantonamento := null;
--SIAC-5895
--v_elem_tipo_id := rec_elem_id.elem_tipo_id; COMMENTATO PER SIAC-6007
v_ex_anno :=null;
v_ex_capitolo := null;
v_ex_articolo :=null;
esito:= '  Inizio ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Ciclo per estrarre i classificatori relativi ad un dato elemento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
FROM siac.siac_r_bil_elem_class rbec, siac.siac_t_class tc
WHERE tc.classif_id = rbec.classif_id
AND   rbec.elem_id = v_elem_id
AND   rbec.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code , dct.classif_tipo_desc
  INTO   v_classif_tipo_code, v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_SPESA' THEN
     v_codice_spesa_ricorrente      := v_classif_code;
     v_descrizione_spesa_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_SPESA' THEN
     v_codice_transazione_spesa_ue      := v_classif_code;
     v_descrizione_transazione_spesa_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FONDO' THEN
     v_codice_tipo_fondo      := v_classif_code;
     v_descrizione_tipo_fondo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FINANZIAMENTO' THEN
     v_codice_tipo_finanziamento      := v_classif_code;
     v_descrizione_tipo_finanziamento := v_classif_desc;
  ELSIF v_classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE' THEN
     v_codice_politiche_regionali_unitarie      := v_classif_code;
     v_descrizione_politiche_regionali_unitarie := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA' THEN
     v_codice_perimetro_sanitario_spesa      := v_classif_code;
     v_descrizione_perimetro_sanitario_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'RISACC' THEN
     v_codice_risorse_accantonamento      := v_classif_code;
     v_descrizione_risorse_accantonamento := v_classif_desc;   /*Haitham 22-05-2023 Issues #109*/
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_1' THEN
     v_classificatore_generico_1      :=  v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_2' THEN
     v_classificatore_generico_2      := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_3' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_4' THEN
     v_classificatore_generico_4      := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_5' THEN
     v_classificatore_generico_5    := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_6' THEN
     v_classificatore_generico_6      := v_classif_tipo_desc;
     v_classificatore_generico_6_descrizione_valore := v_classif_desc;
     v_classificatore_generico_6_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_7' THEN
     v_classificatore_generico_7      := v_classif_tipo_desc;
     v_classificatore_generico_7_descrizione_valore := v_classif_desc;
     v_classificatore_generico_7_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_8' THEN
     v_classificatore_generico_8      := v_classif_tipo_desc;
     v_classificatore_generico_8_descrizione_valore := v_classif_desc;
     v_classificatore_generico_8_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_9' THEN
     v_classificatore_generico_9      := v_classif_tipo_desc;
     v_classificatore_generico_9_descrizione_valore := v_classif_desc;
     v_classificatore_generico_9_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_10' THEN
     v_classificatore_generico_10     := v_classif_tipo_desc;
     v_classificatore_generico_10_descrizione_valore := v_classif_desc;
     v_classificatore_generico_10_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_31' THEN
     v_classificatore_generico_11    := v_classif_tipo_desc;
     v_classificatore_generico_11_descrizione_valore := v_classif_desc;
     v_classificatore_generico_11_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_32' THEN
     v_classificatore_generico_12     := v_classif_tipo_desc;
     v_classificatore_generico_12_descrizione_valore := v_classif_desc;
     v_classificatore_generico_12_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_33' THEN
     v_classificatore_generico_13      := v_classif_tipo_desc;
     v_classificatore_generico_13_descrizione_valore := v_classif_desc;
     v_classificatore_generico_13_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_34' THEN
     v_classificatore_generico_14      := v_classif_tipo_desc;
     v_classificatore_generico_14_descrizione_valore := v_classif_desc;
     v_classificatore_generico_14_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_35' THEN
     v_classificatore_generico_15      := v_classif_tipo_desc;
     v_classificatore_generico_15_descrizione_valore := v_classif_desc;
     v_classificatore_generico_15_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatoree' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc:=null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code, dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code, v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF    v_classif_tipo_code = 'TITOLO_SPESA' THEN
        v_codice_titolo_spesa := v_classif_code;
        v_descrizione_titolo_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MACROAGGREGATO' THEN
        v_codice_macroaggregato_spesa := v_classif_code;
        v_descrizione_macroaggregato_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MISSIONE' THEN
        v_codice_missione_spesa := v_classif_code;
        v_descrizione_missione_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PROGRAMMA' THEN
        v_codice_programma_spesa := v_classif_code;
        v_descrizione_programma_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDR' THEN
        v_codice_cdr := v_classif_code;
        v_descrizione_cdr := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDC' THEN
        v_codice_cdc := v_classif_code;
        v_descrizione_cdc := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_I' THEN
        v_codice_siope_I_spesa := v_classif_code;
        v_descrizione_siope_I_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_II' THEN
        v_codice_siope_II_spesa := v_classif_code;
        v_descrizione_siope_II_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_III' THEN
        v_codice_siope_III_spesa := v_classif_code;
        v_descrizione_siope_III_spesa := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
 esito:= '    Inizio step attributi - '||clock_timestamp();
 return next;
v_FlagEntrateRicorrenti := null;
v_FlagFunzioniDelegate := null;
v_FlagImpegnabile := null;
v_FlagPerMemoria := null;
v_FlagRilevanteIva := null;
v_FlagTrasferimentoOrganiComunitari := null;
v_Note := null;
v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rbea.tabella_id, rbea.percentuale, rbea."boolean" true_false, rbea.numerico, rbea.testo
FROM   siac.siac_r_bil_elem_attr rbea, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rbea.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rbea.elem_id = v_elem_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rbea.validita_inizio AND COALESCE(rbea.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'FlagEntrateRicorrenti' THEN
     v_FlagEntrateRicorrenti := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagFunzioniDelegate' THEN
     v_FlagFunzioniDelegate := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagImpegnabile' THEN
     v_FlagImpegnabile := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagPerMemoria' THEN
     v_FlagPerMemoria := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagRilevanteIva' THEN
     v_FlagRilevanteIva := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagTrasferimentoOrganiComunitari' THEN
     v_FlagTrasferimentoOrganiComunitari := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  END IF;

END LOOP;
esito:= '    Fine step attributi - '||clock_timestamp();
return next;
esito:= '    Inizio step stipendi - '||clock_timestamp();
return next;
-- Sezione per i dati di stipendio
v_codice_stipendio := null;
v_descrizione_stipendio := null;

SELECT dsc.stipcode_code, dsc.stipcode_desc
INTO v_codice_stipendio, v_descrizione_stipendio
FROM  siac.siac_r_bil_elem_stipendio_codice rbesc, siac.siac_d_stipendio_codice dsc
WHERE rbesc.stipcode_id = dsc.stipcode_id
AND   rbesc.elem_id = v_elem_id
AND   rbesc.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL
AND   p_data between rbesc.validita_inizio and coalesce(rbesc.validita_fine, p_data)
AND   p_data between dsc.validita_inizio and coalesce(dsc.validita_fine, p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step iva - '||clock_timestamp();
return next;
-- Sezione per i dati di iva
v_codice_attivita_iva := null;
v_descrizione_attivita_iva := null;

SELECT tia.ivaatt_code, tia.ivaatt_desc
INTO v_codice_attivita_iva, v_descrizione_attivita_iva
FROM siac.siac_r_bil_elem_iva_attivita rbeia, siac.siac_t_iva_attivita tia
WHERE rbeia.ivaatt_id = tia.ivaatt_id
AND   rbeia.elem_id = v_elem_id
AND   rbeia.data_cancellazione IS NULL
AND   tia.data_cancellazione IS NULL
AND   p_data between rbeia.validita_inizio and coalesce(rbeia.validita_fine,p_data)
AND   p_data between tia.validita_inizio and coalesce(tia.validita_fine,p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step dettagli elementi - '||clock_timestamp();
return next;
-- Sezione per i dati di dettaglio degli elementi
v_massimo_impegnabile_anno1 := null;
v_stanziamento_cassa_anno1 := null;
v_stanziamento_cassa_iniziale_anno1 := null;
v_stanziamento_residuo_iniziale_anno1 := null;
v_stanziamento_anno1 := null;
v_stanziamento_iniziale_anno1 := null;
v_stanziamento_residuo_anno1 := null;
v_flag_anno1 := null;
v_massimo_impegnabile_anno2 := null;
v_stanziamento_cassa_anno2 := null;
v_stanziamento_cassa_iniziale_anno2 := null;
v_stanziamento_residuo_iniziale_anno2 := null;
v_stanziamento_anno2 := null;
v_stanziamento_iniziale_anno2 := null;
v_stanziamento_residuo_anno2 := null;
v_flag_anno2 := null;
v_massimo_impegnabile_anno3 := null;
v_stanziamento_cassa_anno3 := null;
v_stanziamento_cassa_iniziale_anno3 := null;
v_stanziamento_residuo_iniziale_anno3 := null;
v_stanziamento_anno3 := null;
v_stanziamento_iniziale_anno3 := null;
v_stanziamento_residuo_anno3 := null;
v_flag_anno3 := null;

v_anno_elem_dett := null;

FOR rec_elem_dett IN
SELECT dbedt.elem_det_tipo_code, tbed.elem_det_flag, tbed.elem_det_importo, tp.anno
FROM  siac.siac_t_bil_elem_det tbed, siac.siac_d_bil_elem_det_tipo dbedt, siac.siac_t_periodo tp
WHERE tbed.elem_det_tipo_id = dbedt.elem_det_tipo_id
AND   tbed.periodo_id = tp.periodo_id
AND   tbed.elem_id = v_elem_id
AND   tbed.data_cancellazione IS NULL
AND   dbedt.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   p_data between tbed.validita_inizio and coalesce(tbed.validita_fine,p_data)
AND   p_data between dbedt.validita_inizio and coalesce(dbedt.validita_fine,p_data)
AND   p_data between tp.validita_inizio and coalesce(tp.validita_fine,p_data)

LOOP
v_anno_elem_dett := rec_elem_dett.anno::integer;
  IF v_anno_elem_dett = v_anno_appo THEN
    v_flag_anno1 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno1 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 1) THEN
    v_flag_anno2 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno2 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 2) THEN
    v_flag_anno3 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno3 := rec_elem_dett.elem_det_importo;
    END IF;
  END IF;
END LOOP;
esito:= '    Fine step dettagli elementi - '||clock_timestamp();
return next;
esito:= '    Inizio step dati da funzione - '||clock_timestamp();
return next;
-- Sezione per valorizzazione delle variabili per i campi di funzione
v_disponibilita_impegnare_anno1 := null;
v_disponibilita_impegnare_anno2 := null;
v_disponibilita_impegnare_anno3 := null;

IF v_elem_tipo_code = 'CAP-UG' THEN
   v_disponibilita_impegnare_anno1 := siac.fnc_siac_disponibilitaimpegnareug_anno1(v_elem_id);
   v_disponibilita_impegnare_anno2 := siac.fnc_siac_disponibilitaimpegnareug_anno2(v_elem_id);
   v_disponibilita_impegnare_anno3 := siac.fnc_siac_disponibilitaimpegnareug_anno3(v_elem_id);
END IF;
esito:= '    Fine step dati da funzione - '||clock_timestamp();
return next;

-- SIAC-5895
esito:= '    Inizio step dati ex capitolo - '||clock_timestamp();
return next;

select per.anno,elem.elem_code,elem.elem_code2
into v_ex_anno, v_ex_capitolo, v_ex_articolo
from siac_r_bil_elem_rel_tempo r_ex
, siac_t_bil_elem elem
, siac_t_bil bil
, siac_t_periodo per
where r_ex.elem_id = v_elem_id
and   r_ex.data_cancellazione is null
and   p_data between r_ex.validita_inizio and coalesce(r_ex.validita_fine,p_data)
and   elem.elem_id = r_ex.elem_id_old
and   elem.bil_id = bil.bil_id
and   bil.periodo_id = per.periodo_id;

IF NOT FOUND then
--SIAC-6007 Indipendentemente dal tipo di capitolo, sia esso di previsione o gestione,
--il capitolo ricercato e di Gestione
  select
    v_anno_prec, elem.elem_code,elem.elem_code2
    into v_ex_anno, v_ex_capitolo, v_ex_articolo
  from siac_t_bil_elem elem
  where elem.elem_code =  v_elem_code
  and   elem.elem_code2 = v_elem_code2
  and   elem.elem_code3 = v_elem_code3
  and   elem.elem_tipo_id = v_elem_tipo_id
  and   elem.bil_id = v_bil_id_prec
  and   elem.data_cancellazione is null;  -- Haitham 10/02/2022 SIAC-8621
END IF;

esito:= '    Fine step dati ex capitolo - '||clock_timestamp();
return next;
INSERT INTO siac.siac_dwh_capitolo_spesa
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
cod_tipo_capitolo,
desc_tipo_capitolo,
cod_stato_capitolo,
desc_stato_capitolo,
cod_classificazione_capitolo,
desc_classificazione_capitolo,
cod_titolo_spesa,
desc_titolo_spesa,
cod_macroaggregato_spesa,
desc_macroaggregato_spesa,
cod_missione_spesa,
desc_missione_spesa,
cod_programma_spesa,
desc_programma_spesa,
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
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
cod_cdr,
desc_cdr,
cod_cdc,
desc_cdc,
cod_siope_i_spesa,
desc_siope_i_spesa,
cod_siope_ii_spesa,
desc_siope_ii_spesa,
cod_siope_iii_spesa,
desc_siope_iii_spesa,
cod_spesa_ricorrente,
desc_spesa_ricorrente,
cod_transazione_spesa_ue,
desc_transazione_spesa_ue,
cod_tipo_fondo,
desc_tipo_fondo,
cod_tipo_finanziamento,
desc_tipo_finanziamento,
cod_politiche_regionali_unit,
desc_politiche_regionali_unit,
cod_perimetro_sanita_spesa,
desc_perimetro_sanita_spesa,
codice_risorse_accantonamento,            /*Haitham 22-05-2023 Issues #109*/
descrizione_risorse_accantonamento,       /*Haitham 22-05-2023 Issues #109*/
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
classificatore_6,
classificatore_6_valore,
classificatore_6_desc_valore,
classificatore_7,
classificatore_7_valore,
classificatore_7_desc_valore,
classificatore_8,
classificatore_8_valore,
classificatore_8_desc_valore,
classificatore_9,
classificatore_9_valore,
classificatore_9_desc_valore,
classificatore_10,
classificatore_10_valore,
classificatore_10_desc_valore,
classificatore_11,
classificatore_11_valore,
classificatore_11_desc_valore,
classificatore_12,
classificatore_12_valore,
classificatore_12_desc_valore,
classificatore_13,
classificatore_13_valore,
classificatore_13_desc_valore,
classificatore_14,
classificatore_14_valore,
classificatore_14_desc_valore,
classificatore_15,
classificatore_15_valore,
classificatore_15_desc_valore,
flagentratericorrenti,
flagfunzionidelegate,
flagimpegnabile,
flagpermemoria,
flagrilevanteiva,
flag_trasf_organi_comunitari,
note,
cod_stipendio,
desc_stipendio,
cod_attivita_iva,
desc_attivita_iva,
massimo_impegnabile_anno1,
stanz_cassa_anno1,
stanz_cassa_iniziale_anno1,
stanz_residuo_iniziale_anno1,
stanz_anno1,
stanz_iniziale_anno1,
stanz_residuo_anno1,
flag_anno1,
massimo_impegnabile_anno2,
stanz_cassa_anno2,
stanz_cassa_iniziale_anno2,
stanz_residuo_iniziale_anno2,
stanz_anno2,
stanz_iniziale_anno2,
stanz_residuo_anno2,
flag_anno2,
massimo_impegnabile_anno3,
stanz_cassa_anno3,
stanz_cassa_iniziale_anno3,
stanz_residuo_iniziale_anno3,
stanz_anno3,
stanz_iniziale_anno3,
stanz_residuo_anno3,
flag_anno3,
disponibilita_impegnare_anno1,
disponibilita_impegnare_anno2,
disponibilita_impegnare_anno3
--SIAC-5895
,ex_anno
,ex_capitolo
,ex_articolo
)
VALUES (v_ente_proprietario_id,
        v_ente_denominazione,
        v_anno,
        v_fase_operativa_code,
        v_fase_operativa_desc,
        v_elem_code,
        v_elem_code2,
        v_elem_code3,
        v_elem_desc,
        v_elem_desc2,
        v_elem_tipo_code,
        v_elem_tipo_desc,
        v_elem_stato_code,
        v_elem_stato_desc,
        v_elem_cat_code,
        v_elem_cat_desc,
		v_codice_titolo_spesa,
		v_descrizione_titolo_spesa,
		v_codice_macroaggregato_spesa,
		v_descrizione_macroaggregato_spesa,
		v_codice_missione_spesa,
		v_descrizione_missione_spesa,
		v_codice_programma_spesa,
		v_descrizione_programma_spesa,
        v_codice_pdc_finanziario_I,
        v_descrizione_pdc_finanziario_I,
        v_codice_pdc_finanziario_II,
        v_descrizione_pdc_finanziario_II,
        v_codice_pdc_finanziario_III,
        v_descrizione_pdc_finanziario_III,
        v_codice_pdc_finanziario_IV,
        v_descrizione_pdc_finanziario_IV,
        v_codice_pdc_finanziario_V,
        v_descrizione_pdc_finanziario_V,
        v_codice_cofog_divisione,
        v_descrizione_cofog_divisione,
        v_codice_cofog_gruppo,
        v_descrizione_cofog_gruppo,
        v_codice_cdr,
        v_descrizione_cdr,
        v_codice_cdc,
        v_descrizione_cdc,
        v_codice_siope_I_spesa,
        v_descrizione_siope_I_spesa,
        v_codice_siope_II_spesa,
        v_descrizione_siope_II_spesa,
        v_codice_siope_III_spesa,
        v_descrizione_siope_III_spesa,
        v_codice_spesa_ricorrente,
        v_descrizione_spesa_ricorrente,
        v_codice_transazione_spesa_ue,
        v_descrizione_transazione_spesa_ue,
        v_codice_tipo_fondo,
        v_descrizione_tipo_fondo,
        v_codice_tipo_finanziamento,
        v_descrizione_tipo_finanziamento,
	    v_codice_politiche_regionali_unitarie,
	    v_descrizione_politiche_regionali_unitarie,
        v_codice_perimetro_sanitario_spesa,
        v_descrizione_perimetro_sanitario_spesa,
        v_codice_risorse_accantonamento,        /*Haitham 22-05-2023 Issues #109*/
        v_descrizione_risorse_accantonamento,   /*Haitham 22-05-2023 Issues #109*/
        v_classificatore_generico_1,
        v_classificatore_generico_1_valore,
        v_classificatore_generico_1_descrizione_valore,
        v_classificatore_generico_2,
        v_classificatore_generico_2_valore,
        v_classificatore_generico_2_descrizione_valore,
        v_classificatore_generico_3,
        v_classificatore_generico_3_valore,
        v_classificatore_generico_3_descrizione_valore,
        v_classificatore_generico_4,
        v_classificatore_generico_4_valore,
        v_classificatore_generico_4_descrizione_valore,
        v_classificatore_generico_5,
        v_classificatore_generico_5_valore,
        v_classificatore_generico_5_descrizione_valore,
        v_classificatore_generico_6,
        v_classificatore_generico_6_valore,
        v_classificatore_generico_6_descrizione_valore,
        v_classificatore_generico_7,
        v_classificatore_generico_7_valore,
        v_classificatore_generico_7_descrizione_valore,
        v_classificatore_generico_8,
        v_classificatore_generico_8_valore,
        v_classificatore_generico_8_descrizione_valore,
        v_classificatore_generico_9,
        v_classificatore_generico_9_valore,
        v_classificatore_generico_9_descrizione_valore,
        v_classificatore_generico_10,
        v_classificatore_generico_10_valore,
        v_classificatore_generico_10_descrizione_valore,
        v_classificatore_generico_11,
        v_classificatore_generico_11_valore,
        v_classificatore_generico_11_descrizione_valore,
        v_classificatore_generico_12,
        v_classificatore_generico_12_valore,
        v_classificatore_generico_12_descrizione_valore,
        v_classificatore_generico_13,
        v_classificatore_generico_13_valore,
        v_classificatore_generico_13_descrizione_valore,
        v_classificatore_generico_14,
        v_classificatore_generico_14_valore,
        v_classificatore_generico_14_descrizione_valore,
        v_classificatore_generico_15,
        v_classificatore_generico_15_valore,
        v_classificatore_generico_15_descrizione_valore,
        v_FlagEntrateRicorrenti,
		v_FlagFunzioniDelegate,
        v_FlagImpegnabile,
        v_FlagPerMemoria,
        v_FlagRilevanteIva,
        v_FlagTrasferimentoOrganiComunitari,
        v_Note,
        v_codice_stipendio,
        v_descrizione_stipendio,
        v_codice_attivita_iva,
        v_descrizione_attivita_iva,
        v_massimo_impegnabile_anno1,
        v_stanziamento_cassa_anno1,
        v_stanziamento_cassa_iniziale_anno1,
        v_stanziamento_residuo_iniziale_anno1,
        v_stanziamento_anno1,
        v_stanziamento_iniziale_anno1,
        v_stanziamento_residuo_anno1,
        v_flag_anno1,
        v_massimo_impegnabile_anno2,
        v_stanziamento_cassa_anno2,
        v_stanziamento_cassa_iniziale_anno2,
        v_stanziamento_residuo_iniziale_anno2,
        v_stanziamento_anno2,
        v_stanziamento_iniziale_anno2,
        v_stanziamento_residuo_anno2,
        v_flag_anno2,
        v_massimo_impegnabile_anno3,
        v_stanziamento_cassa_anno3,
        v_stanziamento_cassa_iniziale_anno3,
        v_stanziamento_residuo_iniziale_anno3,
        v_stanziamento_anno3,
        v_stanziamento_iniziale_anno3,
        v_stanziamento_residuo_anno3,
        v_flag_anno3,
        v_disponibilita_impegnare_anno1,
        v_disponibilita_impegnare_anno2,
        v_disponibilita_impegnare_anno3
        --SIAC-5895
        ,v_ex_anno
        ,v_ex_capitolo
        ,v_ex_articolo
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;





-- INIZIO 7.SIAC-8857.sql



\echo 7.SIAC-8857.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-8857 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR264_stampa_riepilogo_variaz_bozza_pluriennale_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  stanziamento_anno1 numeric,
  variazione_aumento_stanziato_anno1 numeric,
  variazione_diminuzione_stanziato_anno1 numeric,
  stanziamento_anno2 numeric,
  variazione_aumento_stanziato_anno2 numeric,
  variazione_diminuzione_stanziato_anno2 numeric,
  anno_riferimento varchar,
  ente_denominazione varchar,
  display_error varchar,
  tipo varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
sql_query varchar;
bilancio_id integer;
annoCapImp1 varchar;
annoCapImp2 varchar;
nome_ente varchar;

BEGIN

/* 
  30/05/2023 - Procedura nata per il report BILR264 per la SIAC-8857.
  Nasce come copia dela "BILR241_stampa_variazione_bozza_pluriennale_entrate" per estrarre i dati di entrata delle variazioni 
  in bozza fornite in input sui 3 anni.
  I dati che interessano al report sono solo gli stanziamenti per capitolo ma sono estratti anche i dati di cassa e residuo.
  Il report fornisce anche il campo "tipo" dove viene riportato se il capitolo e' tipo "Parte corrente" o "Parte capitale) 
  (valori: corrente/capitale).
  Le regole fornite per questa suddivisione sono:
  - Parte corrente = capitoli dei titoli 1, 2 e 3;
  - Parte capitale = capitoli del titolo 4.
  La procedura fornisce le informazioni anche dei capitoli degli altri titoli come "altro"; e' il report che si occupa di
  filtrare i dati di interesse.

*/

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
annocapimp1:=(p_anno::INTEGER + 1)::varchar;
annocapimp2:=(p_anno::INTEGER + 2)::varchar;

elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
ente_denominazione ='';
display_error='';

select fnc_siac_random_user()
into	user_table;

select bilancio.bil_id
	into bilancio_id
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id=p_ente_prop_id
    and anno_eserc.anno=p_anno
    and bilancio.data_cancellazione IS NULL    
    and anno_eserc.data_cancellazione IS NULL;
    

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;
    
select a.ente_denominazione
into nome_ente
from siac_t_ente_proprietario a
where a.ente_proprietario_id=p_ente_prop_id
    and a.data_cancellazione IS NULL;
        
 RTN_MESSAGGIO:='Estrazione delle variazioni.';  

sql_query='insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id	,
        anno_importo.anno      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id ';
sql_query=sql_query ||' and		tipo_capitolo.elem_tipo_code =	'''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
--10/10/2022 SIAC-8827  Aggiunto lo stato BD.
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'', ''BD'')
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno'  ;    
            
raise notice 'sql_query = %',sql_query;
                    
EXECUTE sql_query;

 RTN_MESSAGGIO:='Estrazione degli importi dei capitoli.'; 
 
 INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
    	and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and capitolo_importi.ente_proprietario_id = p_ente_prop_id  																			
        and	capitolo.bil_id						=	bilancio_id 			  						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode        
		and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
    
 RTN_MESSAGGIO:='Return dei dati.';     
return QUERY
with strutt_bilancio as (select * 
		from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,'')),
capitoli as (select cl.classif_id,
          p_anno anno_bilancio,
          e.*
         from 	siac_r_bil_elem_class rc,
                siac_t_bil_elem e,
                siac_d_class_tipo ct,
                siac_t_class cl,
                siac_d_bil_elem_tipo tipo_elemento, 
                siac_d_bil_elem_stato stato_capitolo,
                siac_r_bil_elem_stato r_capitolo_stato,
                siac_d_bil_elem_categoria cat_del_capitolo,
                siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id				=	cl.classif_tipo_id
        and cl.classif_id					=	rc.classif_id 
        and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
        and e.elem_id						=	rc.elem_id 
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and ct.classif_tipo_code			=	'CATEGORIA'
        and e.ente_proprietario_id=p_ente_prop_id
        and e.bil_id						=	bilancio_id 
        and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
        and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
   UNION  -- Unisco i capitoli senza struttura
    select null,
        p_anno anno_bilancio,
        e.*
       from 	
              siac_t_bil_elem e,              
              siac_d_bil_elem_tipo tipo_elemento, 
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
      and e.ente_proprietario_id			= 	p_ente_prop_id
      and e.bil_id						=	bilancio_id       
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode      								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and r_capitolo_stato.data_cancellazione	is null
      and tipo_elemento.data_cancellazione	is null
      and stato_capitolo.data_cancellazione 	is null
      and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = e.elem_id
                and a.classif_tipo_code='CATEGORIA')),
		importi_stanz_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id 
                        and a.periodo_anno=p_anno                       
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id) ,
		importi_stanz_anno1 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),     
		importi_stanz_anno2 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id)    
select  p_anno::varchar bil_anno,
        ''::varchar titoloe_tipo_code,
        strutt_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
		strutt_bilancio.titolo_code::varchar titoloe_code,
        strutt_bilancio.titolo_desc::varchar titoloe_desc,
		''::varchar tipologia_tipo_code,
        strutt_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
        strutt_bilancio.tipologia_code::varchar tipologia_code,
        strutt_bilancio.tipologia_desc::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        strutt_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
        strutt_bilancio.categoria_code::varchar categoria_code,
        strutt_bilancio.categoria_desc::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre, 
		COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa_anno,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo_anno,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo_anno,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo_anno,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        p_anno::varchar  anno_riferimento,
        nome_ente::varchar ente_denominazione,
        ''::varchar display_error,                   
        case when strutt_bilancio.titolo_code in('1','2','3') 
        	then 'corrente'::varchar
            else case when strutt_bilancio.titolo_code in('4') 
            	then 'capitale'::varchar
                else 'altro'::varchar end 
            end tipo         
from strutt_bilancio
      LEFT JOIN capitoli
          ON strutt_bilancio.categoria_id = capitoli.classif_id
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id            
where capitoli.elem_id is not null
 and exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_eg_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.classif_id = aa.classif_id
                 		--and aa.classif_id_padre = strutt_bilancio.titusc_id 
                      --  and bb.programma_id=strutt_bilancio.categoria_id
                        and cc.utente=user_table) 
UNION
select  p_anno::varchar bil_anno,
        ''::varchar titoloe_tipo_code,
        'Titolo'::varchar titoloe_tipo_desc,
		'0'::varchar titoloe_code,
        ' '::varchar titoloe_desc,
		''::varchar tipologia_tipo_code,
        'Tipologia'::varchar tipologia_tipo_desc,
        '0000000'::varchar tipologia_code,
        ' '::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        'Categoria'::varchar categoria_tipo_desc,
        '0000000'::varchar categoria_code,
        ' '::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre, 
		COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa_anno,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo_anno,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo_anno,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        p_anno::varchar  anno_riferimento,
        nome_ente::varchar ente_denominazione,
        ''::varchar display_error,                  
            'altro'::varchar tipo            
from capitoli
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id            
where capitoli.elem_id is not null
and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = capitoli.elem_id
                and x.ente_proprietario_id = p_ente_prop_id
                and a.classif_tipo_code='CATEGORIA');                                               


delete from siac_rep_cap_eg_imp where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;




raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'Variazioni non trovate' ;
		--return next;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
	when others  THEN
		--raise notice 'errore nella lettura delle variazioni ';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR264_stampa_riepilogo_variaz_bozza_pluriennale_entrate" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;
  
  CREATE OR REPLACE FUNCTION siac."BILR264_verifica_parametri" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  display_error varchar
) AS
$body$
DECLARE

strApp varchar;
intApp integer;

BEGIN


/* 
  30/05/2023 - Procedura nata per il report BILR264 per la SIAC-8857.
 Serve solo per effettuare il controllo di corrrettezza del parametro p_ele_variazioni e restituire un eventuale errore.
 Questo perche' nel report i dati di spesa ed entrata sono uniti e testare l'eventuale proveniente da queste procedure
 non era possibile.

*/


display_error:='';

-- Verifico che il parametro con l'elenco delle variazioni abbia solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;

return next;
 
raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR264_verifica_parametri" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;
  
  CREATE OR REPLACE FUNCTION siac."BILR264_stampa_riepilogo_variaz_bozza_pluriennale_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  stanziamento_anno1 numeric,
  variazione_aumento_stanziato_anno1 numeric,
  variazione_diminuzione_stanziato_anno1 numeric,
  stanziamento_anno2 numeric,
  variazione_aumento_stanziato_anno2 numeric,
  variazione_diminuzione_stanziato_anno2 numeric,
  anno_riferimento varchar,
  display_error varchar,
  tipo varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
sql_query varchar;
strApp varchar;
intApp numeric;
bilancio_id	integer;
strQuery varchar;


BEGIN


/* 
  30/05/2023 - Procedura nata per il report BILR264 per la SIAC-8857.
  Nasce come copia dela "BILR241_stampa_variazione_bozza_pluriennale_spese" per estrarre i dati di spesa delle variazioni 
  in bozza fornite in input sui 3 anni.
  I dati che interessano al report sono solo gli stanziamenti per capitolo ma sono estratti anche i dati di cassa e residuo.
  Il report fornisce anche il campo "tipo" dove viene riportato se il capitolo e' tipo "Parte corrente" o "Parte capitale) 
  (valori: corrente/capitale).
  Le regole fornite per questa suddivisione sono:
  - Parte corrente = capitoli del titolo 1;
  - Parte capitale = capitoli del titolo 2.
  La procedura fornisce le informazioni anche dei capitoli degli altri titoli come "altro"; e' il report che si occupa di
  filtrare i dati di interesse.

*/


annocapimp1:=(p_anno::INTEGER + 1)::varchar;
annocapimp2:=(p_anno::INTEGER + 2)::varchar;



TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui


-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

-- se ?? presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;


bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
display_error='';


select fnc_siac_random_user()
into	user_table;

select bilancio.bil_id
	into bilancio_id
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id=p_ente_prop_id
    and anno_eserc.anno=p_anno
    and bilancio.data_cancellazione IS NULL    
    and anno_eserc.data_cancellazione IS NULL;
        
 RTN_MESSAGGIO:='Estrazione delle variazioni.';  

sql_query='insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id,
        anno_importo.anno     	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id   
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id 
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
sql_query=sql_query ||'and		tipo_capitolo.elem_tipo_code						= '''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
--10/10/2022 SIAC-8827  Aggiunto lo stato BD.
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'', ''BD'') and 
		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno';

raise notice 'Query variazioni = %', sql_query;
execute  sql_query;
              
 RTN_MESSAGGIO:='Estrazione degli importi dei capitoli.';  

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,            
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
	 	and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id       
        and	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  								
        and	capitolo.bil_id						=	bilancio_id 			         						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        --and	capitolo_imp_periodo.anno = p_anno_variazione							
        and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
        and capitolo_imp_tipo.elem_det_tipo_code in ('STA', 'SCA','STR')						
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null         
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;  

 RTN_MESSAGGIO:='Return dei dati.';       
        
return QUERY
with strutt_bilancio as (select * 
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        p_anno anno_bilancio,
       	capitolo.*
from siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and        
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and        
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	capitolo.bil_id=bilancio_id												and
    programma_tipo.classif_tipo_code='PROGRAMMA' 							and	
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							   		 
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null
    UNION  -- Unisco i capitoli senza struttura
    select null, null,
        p_anno anno_bilancio,
        e.*
       from 	
              siac_t_bil_elem e,              
              siac_d_bil_elem_tipo tipo_elemento, 
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
      and e.ente_proprietario_id			= 	p_ente_prop_id
      and e.bil_id						=	bilancio_id       
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode      								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and r_capitolo_stato.data_cancellazione	is null
      and tipo_elemento.data_cancellazione	is null
      and stato_capitolo.data_cancellazione 	is null
      and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = e.elem_id
                and a.classif_tipo_code='PROGRAMMA')),
		importi_stanz_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id 
                        and a.periodo_anno=p_anno                       
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id) ,
		importi_stanz_anno1 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),     
		importi_stanz_anno2 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id)                                                                      
select distinct p_anno::varchar bil_anno,
        strutt_bilancio.missione_tipo_desc::varchar missione_tipo_desc ,
        strutt_bilancio.missione_code::varchar missione_code,
        strutt_bilancio.missione_desc::varchar missione_desc,
        strutt_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
        strutt_bilancio.programma_code::varchar programma_code,
        strutt_bilancio.programma_desc::varchar programma_desc,
        strutt_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
        strutt_bilancio.titusc_code::varchar titusc_code,
        strutt_bilancio.titusc_desc::varchar titusc_desc,
        strutt_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
        strutt_bilancio.macroag_code::varchar macroag_code,
        strutt_bilancio.macroag_desc::varchar macroag_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        p_anno::varchar  anno_riferimento,
        ''::varchar display_error,                   
        case when strutt_bilancio.titusc_code in('1') 
        	then 'corrente'::varchar
            else case when strutt_bilancio.titusc_code in('2') 
            	then 'capitale'::varchar
                else 'altro'::varchar end 
            end tipo             
from strutt_bilancio
      LEFT JOIN capitoli
          ON (strutt_bilancio.programma_id = capitoli.programma_id
              and strutt_bilancio.macroag_id = capitoli.macroaggregato_id)
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id            
where capitoli.elem_id is not null
 and exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_ug_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.macroaggregato_id = aa.classif_id
                 		and aa.classif_id_padre = strutt_bilancio.titusc_id 
                        and bb.programma_id=strutt_bilancio.programma_id
                        and cc.utente=user_table)
union
select distinct p_anno::varchar bil_anno,
        'Missione'::varchar missione_tipo_desc ,
        '00'::varchar missione_code,
        ' '::varchar missione_desc,
        'Programma'::varchar programma_tipo_desc,
        '0000'::varchar programma_code,
        ' '::varchar programma_desc,
        'Titolo Spesa'::varchar titusc_tipo_desc,
        '0'::varchar titusc_code,
        ' '::varchar titusc_desc,
        'Macroaggregato'::varchar macroag_tipo_desc,
        '0000000'::varchar macroag_code,
        ' '::varchar macroag_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre,
        COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        p_anno::varchar  anno_riferimento,
        ''::varchar display_error,                    
        'altro'::varchar tipo
from capitoli
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id               
where capitoli.elem_id is not null
	and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = capitoli.elem_id
                and x.ente_proprietario_id = p_ente_prop_id
                and a.classif_tipo_code='PROGRAMMA');          
        
delete from siac_rep_cap_ug_imp where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;
         
 
raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR264_stampa_riepilogo_variaz_bozza_pluriennale_spese" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;
  
--SIAC-8857 - Maurizio - FINE




-- INIZIO 8.SIAC-TASK24.sql



\echo 8.SIAC-TASK24.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-TASK #24 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR077_peg_entrate_gestione"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR077_peg_spese_gestione"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR079_peg_entrate_gestione_struttura"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR079_peg_spese_gestione_struttura"(p_ente_prop_id integer, p_anno varchar);

  
CREATE OR REPLACE FUNCTION siac."BILR077_peg_entrate_gestione" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric,
  num_cap_old varchar,
  num_art_old varchar,
  upb varchar
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN
/*
	Questa Procedura nasce come copia della procedura BILR047_peg_entrate_previsione.
    Le modifiche effettuate sono quelle per estrarre i dati  dei capitoli di
    GESTIONE invece che di PREVISIONE.
    Per comodità sono state lasciate le stesse tabelle di appoggio (es. siac_rep_cap_ep_imp_riga)
    usate dalla procedura di previsione.
    Anche i nomi dei campi di output sono gli stessi in modo da non dover effettuare
    troppi cambiamenti al report BILR077_peg_senza_fpv_gestione che è copiato dal
    BILR046_peg_senza_fpv.
*/

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo Gestione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
num_cap_old='';
num_art_old='';
upb='';

select fnc_siac_random_user()
into	user_table;

/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/


--05/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;
 
 
--27/04/2016: aggiunta estrazione del campo UPB che è utilizzato solo per la 
-- regione (report BILR081_peg_gestione).
-- il report BILR077_peg_gestione utilizza questa procedura ma non visualizza
-- il campo UPB.
insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
    (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
                class_upb.classif_tipo_code='CLASSIFICATORE_36' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	)
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;



insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    

for classifBilRec in

select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        bil_elem.elem_code				num_cap_old,
        bil_elem.elem_code2				num_art_old,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb.pdc,' ')upb 
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
            	/* aggiunto questo join x estrarre l'eventuale riferimento all'ex capitolo */
            left 	join 	siac_r_bil_elem_rel_tempo rel_tempo on rel_tempo.elem_id 	=  tb.elem_id and rel_tempo.data_cancellazione is null
            left	join 	siac_t_bil_elem		bil_elem	on bil_elem.elem_id = rel_tempo.elem_id_old and bil_elem.data_cancellazione is null
--01/06/2023 siac-task-issue #24.
--Sono restituiti i dati in cui almeno uno degli importi non e' 0.
where COALESCE (tb1.stanziamento_prev_anno,0) <> 0 OR COALESCE (tb1.stanziamento_prev_anno1,0) <> 0 OR 
		COALESCE (tb1.stanziamento_prev_anno2,0) <> 0 OR COALESCE (tb1.residui_presunti,0) <> 0 OR 
        COALESCE (tb1.previsioni_anno_prec,0) <> 0 OR COALESCE (tb1.stanziamento_prev_cassa_anno,0) <> 0
order by v1.titolo_code,v1.tipologia_code,v1.categoria_code,tb.elem_code::INTEGER,tb.elem_code2::INTEGER            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;
num_cap_old=classifBilRec.num_cap_old;
num_art_old=classifBilRec.num_art_old;
upb:=classifBilRec.upb;

return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
num_cap_old='';
num_art_old='';
upb='';

end loop;
delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR077_peg_entrate_gestione" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac."BILR077_peg_spese_gestione" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  num_cap_old varchar,
  num_art_old varchar,
  upb varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN
/*
	Questa Procedura nasce come copia della procedura BILR046_peg_spese_previsione.
    Le modifiche effettuate sono quelle per estrarre i dati  dei capitoli di
    GESTIONE invece che di PREVISIONE.
    Per comodità sono state lasciate le stesse tabelle di appoggio (es. siac_rep_cap_ep_imp_riga)
    usate dalla procedura di previsione.
    Anche i nomi dei campi di output sono gli stessi in modo da non dover effettuare
    troppi cambiamenti al report BILR077_peg_senza_fpv_gestione che è copiato dal
    BILR046_peg_senza_fpv.
*/
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;


select fnc_siac_random_user()
into	user_table;

/*
begin
     RTN_MESSAGGIO:='lettura anno di bilancio''.';  
for classifBilRec in
select 	anno_eserc.anno BIL_ANNO, 
        r_fase.bil_fase_operativa_id, 
        fase.fase_operativa_desc, 
        fase.fase_operativa_code fase_bilancio
from 	siac_t_bil 						bilancio,
		siac_t_periodo 					anno_eserc,
        siac_d_periodo_tipo				tipo_periodo,
        siac_r_bil_fase_operativa 		r_fase,
        siac_d_fase_operativa  			fase
where	anno_eserc.anno						=	p_anno							and	
		bilancio.periodo_id					=	anno_eserc.periodo_id			and
        tipo_periodo.periodo_tipo_code		=	'SY'							and
        anno_eserc.ente_proprietario_id		=	p_ente_prop_id					and
/*        bilancio.ente_proprietario_id		=	anno_eserc.ente_proprietario_id	and
        tipo_periodo.ente_proprietario_id	=	anno_eserc.ente_proprietario_id	and
        r_fase.ente_proprietario_id			=	anno_eserc.ente_proprietario_id	and
        fase.ente_proprietario_id			=	anno_eserc.ente_proprietario_id	and*/
        tipo_periodo.periodo_tipo_id		=	anno_eserc.periodo_tipo_id		and
        r_fase.bil_id						=	bilancio.bil_id					AND
        r_fase.fase_operativa_id			=	fase.fase_operativa_id			and
        bilancio.data_cancellazione			is null								and							
		anno_eserc.data_cancellazione		is null								and	
        tipo_periodo.data_cancellazione		is null								and	
       	r_fase.data_cancellazione			is null								and	
        fase.data_cancellazione				is null								and
        now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())			and		
        now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())		and
        now() between tipo_periodo.validita_inizio and coalesce (tipo_periodo.validita_fine, now())	and        
        now() between r_fase.validita_inizio and coalesce (r_fase.validita_fine, now())				and
		now() between fase.validita_inizio and coalesce (fase.validita_fine, now())

loop
   fase_bilancio:=classifBilRec.fase_bilancio;
raise notice 'Fase bilancio  %',classifBilRec.fase_bilancio;

anno_bil_impegni:=p_anno;

  if classifBilRec.fase_bilancio = 'P'  then
      anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
  else
      anno_bil_impegni:=p_anno;
  end if;
end loop;

exception
	when no_data_found THEN
		raise notice 'Fase del bilancio non trovata';
	return;
	when others  THEN
        RTN_MESSAGGIO:='errore ricerca fase bilancio';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
       return;
end;*/

anno_bil_impegni:=p_anno;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
tipologia_capitolo='';
num_cap_old='';
num_art_old='';
upb='';

     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/


-- 05/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 05/09/2016: start filtro per mis-prog-macro*/
   , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 05/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;


RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
     
--27/04/2016: aggiunta estrazione del campo UPB che è utilizzato solo per la 
-- regione (report BILR081_peg_gestione).
-- il report BILR077_peg_gestione utilizza questa procedura ma non visualizza
-- il campo UPB.     
insert into siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
                class_upb.classif_tipo_code='CLASSIFICATORE_1' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                capitolo.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	),
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ---------and	cat_del_capitolo.elem_cat_code	=	'STD'	
        -- 05/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
	and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
    and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
    and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
    and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
    and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
    and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	

-----------------   importo capitoli di tipo standard ------------------------

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  

insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=tipo_elemento.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            -- 05/09/2016: aggiunto FPVC
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV							
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp fpv''.';  


/* -- ANNA 2206 FPV	
insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=tipo_elemento.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code	=	'FPV'								
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;
*/ -- ANNA 2206 FPV

-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and     -- 05/09/2016: aggiunto FPVC
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		and	tb2.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		and	tb3.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV		 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		and	tb4.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo	in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		in ('STD','FSC','FPV','FPVC');  -- ANNA 2206 FPV

/*   -- ANNA 2206 FPV
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.';  
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV';
        
*/-- ANNA 2206 FPV

     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        	--27/04/2016: gestito l'UPB 
        tb.codice_pdc	upb, --'',
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			FULL  join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id  
            and tbprec.data_cancellazione is null    
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;


 

 
 raise notice 'anno_bil_impegni  %',anno_bil_impegni;
 raise notice 'tipo_capitolo  %',tipo_capitolo;
 
 raise notice 'tipo capitolo % ', tipo_capitolo;
 
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni''.'; 

/*     
insert into siac_rep_impegni
select tb2.elem_id,
tb.movgest_anno,
p_ente_prop_id,
user_table utente,
tb.importo 
from (
select    
capitolo.elem_id,
movimento.movgest_anno,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where 
           bilancio.periodo_id     = anno_eserc.periodo_id 
      and anno_eserc.anno       =   anno_bil_impegni  
      and bilancio.bil_id      =capitolo.bil_id
      -----and movimento.bil_id       = bilancio.bil_id 
      and capitolo.elem_tipo_id      = t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    = elemTipoCode 
      and movimento.movgest_anno ::text in (annoCapImp, annoCapImp1, annoCapImp2)
      and r_mov_capitolo.elem_id    =capitolo.elem_id
      and r_mov_capitolo.movgest_id    = movimento.movgest_id 
      and movimento.movgest_tipo_id    = tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    = 'I' 
      and movimento.movgest_id      = ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    = r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    = dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      ---------and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      ---------and	now() between tipo_mov.validita_inizio and coalesce (tipo_mov.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      -------and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      --------and	now() between tipo_stato.validita_inizio and coalesce (tipo_stato.validita_fine, now())
      -------and	now() between dt_movimento.validita_inizio and coalesce (dt_movimento.validita_fine, now())
      ------and	now() between dt_mov_tipo.validita_inizio and coalesce (dt_mov_tipo.validita_fine, now())  
      --------and	now() between ts_mov_tipo.validita_inizio and coalesce (ts_mov_tipo.validita_fine, now()) 
      and anno_eserc.data_cancellazione    is null 
      and bilancio.data_cancellazione     is null 
      and capitolo.data_cancellazione     is null 
      and r_mov_capitolo.data_cancellazione   is null 
      and t_capitolo.data_cancellazione    is null 
      and movimento.data_cancellazione     is null 
      and tipo_mov.data_cancellazione     is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione    is null 
      and tipo_stato.data_cancellazione    is null 
      and dt_movimento.data_cancellazione    is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id, movimento.movgest_anno)
tb 
,
(select * from  siac_t_bil_elem    capitolo_up,
      siac_d_bil_elem_tipo    t_capitolo_up
      where capitolo_up.elem_tipo_id=t_capitolo_up.elem_tipo_id 
      and t_capitolo_up.elem_tipo_code = elemTipoCode) tb2
where
 tb2.elem_code =tb.elem_code and 
 tb2.elem_code2 =tb.elem_code2 
and tb2.elem_code3 =tb.elem_code3;    
*/

--insert ottimizzata Giuliano 20160929
insert into siac_rep_impegni
select tb.elem_id
,tb.movgest_anno,
p_ente_prop_id
,user_table utente
,sum(tb.movgest_ts_det_importo) importo
 from (
select    
c.elem_id,f.movgest_anno,c.elem_code,c.elem_code2,c.elem_code3, 
movgest_ts_det_importo,
m.data_cancellazione data_cancellazione_movgest_ts_det
    from 
      siac_t_bil      a, 
      siac_t_periodo     b, 
      siac_t_bil_elem     c , 
      siac_r_movgest_bil_elem   d, 
      siac_d_bil_elem_tipo    e, 
      siac_t_movgest     f, 
      siac_d_movgest_tipo    g, 
      siac_t_movgest_ts    h, 
      siac_r_movgest_ts_stato   i, 
      siac_d_movgest_stato    l, 
      siac_t_movgest_ts_det   m, 
      siac_d_movgest_ts_tipo   n, 
      siac_d_movgest_ts_det_tipo  o 
      where 
           a.periodo_id     = b.periodo_id 
      and b.anno       =   anno_bil_impegni  
      and a.bil_id      =c.bil_id
      and c.elem_tipo_id      = e.elem_tipo_id
      and e.elem_tipo_code    =  elemTipoCode 
      and f.movgest_anno ::text in (annoCapImp, annoCapImp1, annoCapImp2)
      and d.elem_id    =c.elem_id
      and d.movgest_id    = f.movgest_id 
      and f.movgest_tipo_id    = g.movgest_tipo_id 
      and g.movgest_tipo_code    = 'I' 
      and f.movgest_id      = h.movgest_id 
      and h.movgest_ts_id    = i.movgest_ts_id 
      and i.movgest_stato_id  = l.movgest_stato_id 
      and l.movgest_stato_code   in ('D','N') ------ P,A,N 
      and h.movgest_ts_tipo_id  = n.movgest_ts_tipo_id 
      and n.movgest_ts_tipo_code  = 'T' 
      and h.movgest_ts_id    = m.movgest_ts_id 
      and m.movgest_ts_det_tipo_id  = o.movgest_ts_det_tipo_id 
      and o.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
     and	now() between d.validita_inizio and coalesce (d.validita_fine, now())
      and	now() between i.validita_inizio and coalesce (i.validita_fine, now())
        and b.ente_proprietario_id   = p_ente_prop_id
        ) tb where 
       tb.data_cancellazione_movgest_ts_det  is  null
       group by tb.elem_id, tb.movgest_anno;
      

raise notice 'anno  %',annoCapImp;
raise notice 'anno  %',annoCapImp1;
raise notice 'anno  %',annoCapImp2;

      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
      
      
insert into siac_rep_impegni_riga
select 
    v1.elem_id,
    v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    v3.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v3.elem_id=v1.elem_id
and v1.periodo_anno::integer+2=v3.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
union
--2015, 2016 
 select v1.elem_id,
    v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer+2=v3.periodo_anno::INTEGER
)
union
--2015, 2017
select 
v1.elem_id,
    v1.importo	as impegnato_anno,
    NULL as impegnato_anno1,
    v2.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+2=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer+1=v3.periodo_anno::INTEGER
)
union
--2016, 2017
 select 
 v1.elem_id,
    NULL as impegnato_anno,
    v1.importo	as impegnato_anno1,
    v2.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp1
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer-1=v3.periodo_anno::INTEGER
)
 union --solo 2015
select 
v1.elem_id,
    v1.importo	as impegnato_anno,
    NULL as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
 union --solo 2016
select 
v1.elem_id,
    null as impegnato_anno,
    v1.importo as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp1
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
 union --solo 2017
select 
v1.elem_id,
null 	as impegnato_anno,
NULL as impegnato_anno1,
v1.importo as impegnato_anno2,  
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp2
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
;      
 
      RTN_MESSAGGIO:='preparazione file output ''.'; 
 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,
        	bil_elem.elem_code		num_cap_old,
        	bil_elem.elem_code2		num_art_old,            
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
            COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
            COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
            COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
            COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,  
            --------t1.elem_id_old		elem_id_old,
            COALESCE(t2.impegnato_anno,0) impegnato_anno,
            COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
            COALESCE(t2.impegnato_anno2,0) impegnato_anno2,
            COALESCE(t1.codice_pdc,' ')upb 
    from siac_rep_mptm_up_cap_importi t1
            ----full join siac_rep_impegni_riga  t2
            left join siac_rep_impegni_riga  t2
            on (t1.elem_id	=	t2.elem_id  ---------da sostituire con   --------t1.elem_id_old	=	t2.elem_id
                --and	t1.ente_proprietario_id	=	t2.ente_proprietario
                and	t1.utente	=	t2.utente
                and	t1.utente	=	user_table)
            	/* aggiunto questo join x estrarre l'eventuale riferimento all'ex capitolo */
            left 	join 	siac_r_bil_elem_rel_tempo rel_tempo on rel_tempo.elem_id 	=  t1.elem_id and rel_tempo.data_cancellazione is null
            left	join 	siac_t_bil_elem		bil_elem	on bil_elem.elem_id = rel_tempo.elem_id_old and bil_elem.data_cancellazione is null               
	--01/06/2023 siac-task-issue #24.
	--Sono restituiti i dati in cui almeno uno degli importi non e' 0.
    where COALESCE(t1.stanziamento_prev_anno,0) <> 0 OR COALESCE(t1.stanziamento_prev_anno1,0) <> 0 OR
    		COALESCE(t1.stanziamento_prev_anno2,0) <> 0 OR COALESCE(t1.stanziamento_prev_res_anno,0) <> 0 OR
            COALESCE(t1.stanziamento_anno_prec,0) <> 0 OR COALESCE(t1.stanziamento_prev_cassa_anno,0) <> 0 OR
            COALESCE(t1.stanziamento_fpv_anno_prec,0) <> 0 OR COALESCE(t1.stanziamento_fpv_anno,0) <> 0 OR
            COALESCE(t1.stanziamento_fpv_anno1,0) <> 0 OR COALESCE(t1.stanziamento_fpv_anno2,0) <> 0 OR
            COALESCE(t2.impegnato_anno,0) <> 0 OR COALESCE(t2.impegnato_anno1,0) <> 0 OR
            COALESCE(t2.impegnato_anno2,0) <> 0
order by missione_code,programma_code,titusc_code,macroag_code   	
loop
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
      impegnato_anno:=classifBilRec.impegnato_anno;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2=classifBilRec.impegnato_anno2;
	  num_cap_old=classifBilRec.num_cap_old;
	  num_art_old=classifBilRec.num_art_old;
	  fase_bilancio='P';
      
      upb=classifBilRec.upb;
	return next;
    bil_anno='';
    missione_tipo_code='';
    missione_tipo_desc='';
    missione_code='';
    missione_desc='';
    programma_tipo_code='';
    programma_tipo_desc='';
    programma_code='';
    programma_desc='';
    titusc_tipo_code='';
    titusc_tipo_desc='';
    titusc_code='';
    titusc_desc='';
    macroag_tipo_code='';
    macroag_tipo_desc='';
    macroag_code='';
    macroag_desc='';
    bil_ele_code='';
    bil_ele_desc='';
    bil_ele_code2='';
    bil_ele_desc2='';
    bil_ele_id=0;
    bil_ele_id_padre=0;
    stanziamento_prev_res_anno=0;
    stanziamento_anno_prec=0;
    stanziamento_prev_cassa_anno=0;
    stanziamento_prev_anno=0;
    stanziamento_prev_anno1=0;
    stanziamento_prev_anno2=0;
    impegnato_anno=0;
    impegnato_anno1=0;
    impegnato_anno2=0;
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;
    num_cap_old='';
	num_art_old='';
	upb='';
    
end loop;
--end if;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga	where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_impegni where utente=user_table;
delete from siac_rep_impegni_riga  where utente=user_table;


raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR077_peg_spese_gestione" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;


CREATE OR REPLACE FUNCTION siac."BILR079_peg_spese_gestione_struttura" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  num_cap_old varchar,
  num_art_old varchar,
  direz_code varchar,
  direz_descr varchar,
  sett_code varchar,
  sett_descr varchar,
  upb varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
classif_id_padre integer;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN
/*
	Questa Procedura nasce come copia della procedura BILR046_peg_spese_previsione.
    Le modifiche effettuate sono quelle per estrarre i dati  dei capitoli di
    GESTIONE invece che di PREVISIONE.
    Per comodità sono state lasciate le stesse tabelle di appoggio (es. siac_rep_cap_ep_imp_riga)
    usate dalla procedura di previsione.
    Anche i nomi dei campi di output sono gli stessi in modo da non dover effettuare
    troppi cambiamenti al report BILR077_peg_senza_fpv_gestione che è copiato dal
    BILR046_peg_senza_fpv.
*/
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;


select fnc_siac_random_user()
into	user_table;

anno_bil_impegni:=p_anno;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
tipologia_capitolo='';
num_cap_old='';
num_art_old='';
direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;
upb='';

     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/

-- 05/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 05/09/2016: start filtro per mis-prog-macro*/
   , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 05/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;


     RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
     
     
--29/04/2016: aggiunta estrazione del campo UPB che è utilizzato solo per la 
-- regione (report BILR082_peg_gestione_struttura).
-- il report BILR079_peg_gestione_struttura utilizza questa procedura ma non 
-- visualizza il campo UPB.     
insert into siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
                class_upb.classif_tipo_code='CLASSIFICATORE_1' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                capitolo.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	),
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ---------and	cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 05/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') -- ANNA 2206 FPV e FSC
    and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
	and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
    and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
    and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
    and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
    and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
    and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	

-----------------   importo capitoli di tipo standard ------------------------

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  

insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 05/09/2016: aggiunto FPVC
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV E FSC						
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp fpv''.';  

/* -- ANNA 2206 FPV	
insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=tipo_elemento.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code	=	'FPV'								
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;
 */ -- ANNA 2206 FPV	

-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  


insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		stanziamento_prev_res_anno,
    	tb5.importo		as		stanziamento_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        0,0,0,0,
        tb1.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and -- 05/09/2016: aggiunto FPVC
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp			and	tb1.tipo_capitolo 		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 		and	tb2.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp		and	tb3.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV				 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpRes		and	tb4.tipo_capitolo		in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo	in ('STD','FSC','FPV','FPVC')  -- ANNA 2206 FPV	
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa	and	tb6.tipo_capitolo		in ('STD','FSC','FPV','FPVC');  -- ANNA 2206 FPV	

/*   -- ANNA 2206 FPV
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga FPV''.';  
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where		
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV';
        
*/   -- ANNA 2206 FPV
     RTN_MESSAGGIO:='insert tabella siac_rep_mptm_up_cap_importi''.';  

insert into siac_rep_mptm_up_cap_importi
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	tb1.stanziamento_prev_anno		stanziamento_prev_anno,
    	tb1.stanziamento_prev_anno1		stanziamento_prev_anno1,
    	tb1.stanziamento_prev_anno2		stanziamento_prev_anno2,
   	 	tb1.stanziamento_prev_res_anno	stanziamento_prev_res_anno,
    	tb1.stanziamento_anno_prec		stanziamento_anno_prec,
    	tb1.stanziamento_prev_cassa_anno	stanziamento_prev_cassa_anno,
        v1.ente_proprietario_id,
        user_table utente,
        tbprec.elem_id_old,
        tb.codice_pdc	upb,
        tb1.stanziamento_fpv_anno_prec	stanziamento_fpv_anno_prec,
  		tb1.stanziamento_fpv_anno		stanziamento_fpv_anno,
  		tb1.stanziamento_fpv_anno1		stanziamento_fpv_anno1,
  		tb1.stanziamento_fpv_anno2		stanziamento_fpv_anno2        
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			LEFT  join siac_rep_cap_ug tb
           		on  (v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_up_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id     
            and tbprec.data_cancellazione is null 
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;


 
 raise notice 'anno_bil_impegni  %',anno_bil_impegni;
 raise notice 'tipo_capitolo  %',tipo_capitolo;
 
 raise notice 'tipo capitolo % ', tipo_capitolo;
 
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni''.'; 
     
insert into siac_rep_impegni
select tb2.elem_id,
tb.movgest_anno,
p_ente_prop_id,
user_table utente,
tb.importo 
from (
select    
capitolo.elem_id,
movimento.movgest_anno,
capitolo.elem_code,
capitolo.elem_code2,
capitolo.elem_code3,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where 
           bilancio.periodo_id     = anno_eserc.periodo_id 
      and anno_eserc.anno       =   anno_bil_impegni  
      and bilancio.bil_id      =capitolo.bil_id
      -----and movimento.bil_id       = bilancio.bil_id 
      and capitolo.elem_tipo_id      = t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    = elemTipoCode 
      and movimento.movgest_anno ::text in (annoCapImp, annoCapImp1, annoCapImp2)
      and r_mov_capitolo.elem_id    =capitolo.elem_id
      and r_mov_capitolo.movgest_id    = movimento.movgest_id 
      and movimento.movgest_tipo_id    = tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    = 'I' 
      and movimento.movgest_id      = ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    = r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    = dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      ---------and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      ---------and	now() between tipo_mov.validita_inizio and coalesce (tipo_mov.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      -------and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      --------and	now() between tipo_stato.validita_inizio and coalesce (tipo_stato.validita_fine, now())
      -------and	now() between dt_movimento.validita_inizio and coalesce (dt_movimento.validita_fine, now())
      ------and	now() between dt_mov_tipo.validita_inizio and coalesce (dt_mov_tipo.validita_fine, now())  
      --------and	now() between ts_mov_tipo.validita_inizio and coalesce (ts_mov_tipo.validita_fine, now()) 
      and anno_eserc.data_cancellazione    is null 
      and bilancio.data_cancellazione     is null 
      and capitolo.data_cancellazione     is null 
      and r_mov_capitolo.data_cancellazione   is null 
      and t_capitolo.data_cancellazione    is null 
      and movimento.data_cancellazione     is null 
      and tipo_mov.data_cancellazione     is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione    is null 
      and tipo_stato.data_cancellazione    is null 
      and dt_movimento.data_cancellazione    is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id, movimento.movgest_anno)
tb 
,
(select * from  siac_t_bil_elem    capitolo_up,
      siac_d_bil_elem_tipo    t_capitolo_up
      where capitolo_up.elem_tipo_id=t_capitolo_up.elem_tipo_id 
      and t_capitolo_up.elem_tipo_code = elemTipoCode) tb2
where
 tb2.elem_code =tb.elem_code and 
 tb2.elem_code2 =tb.elem_code2 
and tb2.elem_code3 =tb.elem_code3;    
      

raise notice 'anno  %',annoCapImp;
raise notice 'anno  %',annoCapImp1;
raise notice 'anno  %',annoCapImp2;

      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
      
      
insert into siac_rep_impegni_riga
select 
    v1.elem_id,
    v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    v3.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v3.elem_id=v1.elem_id
and v1.periodo_anno::integer+2=v3.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
union
--2015, 2016 
 select v1.elem_id,
    v1.importo	as impegnato_anno,
    v2.importo	as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer+2=v3.periodo_anno::INTEGER
)
union
--2015, 2017
select 
v1.elem_id,
    v1.importo	as impegnato_anno,
    NULL as impegnato_anno1,
    v2.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+2=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer+1=v3.periodo_anno::INTEGER
)
union
--2016, 2017
 select 
 v1.elem_id,
    NULL as impegnato_anno,
    v1.importo	as impegnato_anno1,
    v2.importo	as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	         
         from siac_rep_impegni v1, siac_rep_impegni v2--, siac_rep_impegni v3
where v1.elem_id=v2.elem_id
and v1.periodo_anno::integer+1=v2.periodo_anno::INTEGER
and v1.periodo_anno=annoCapImp1
and not exists (select 1 from siac_rep_impegni v3 where v3.elem_id=v1.elem_id and 
v1.periodo_anno::integer-1=v3.periodo_anno::INTEGER
)
 union --solo 2015
select 
v1.elem_id,
    v1.importo	as impegnato_anno,
    NULL as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
 union --solo 2016
select 
v1.elem_id,
    null as impegnato_anno,
    v1.importo as impegnato_anno1,
    NULL as impegnato_anno2,
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp1
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
 union --solo 2017
select 
v1.elem_id,
null 	as impegnato_anno,
NULL as impegnato_anno1,
v1.importo as impegnato_anno2,  
    v1.ente_proprietario,
    v1.utente	
from siac_rep_impegni v1 where  v1.periodo_anno=annoCapImp2
and v1.elem_id in (         
select v.elem_id from siac_rep_impegni v
group by v.elem_id
having count(*)=1)
;      
      
      
 RTN_MESSAGGIO:='preparazione file output ''.'; 
 
 for classifBilRec in
	select 	t1.missione_tipo_desc	missione_tipo_desc,
            t1.missione_code		missione_code,
            t1.missione_desc		missione_desc,
            t1.programma_tipo_desc	programma_tipo_desc,
            t1.programma_code		programma_code,
            t1.programma_desc		programma_desc,
            t1.titusc_tipo_desc		titusc_tipo_desc,
            t1.titusc_code			titusc_code,
            t1.titusc_desc			titusc_desc,
            t1.macroag_tipo_desc	macroag_tipo_desc,
            t1.macroag_code			macroag_code,
            t1.macroag_desc			macroag_desc,
            t1.bil_anno   			BIL_ANNO,
            t1.elem_code     		BIL_ELE_CODE,
            t1.elem_code2     		BIL_ELE_CODE2,
            t1.elem_code3			BIL_ELE_CODE3,
            t1.elem_desc     		BIL_ELE_DESC,
            t1.elem_desc2     		BIL_ELE_DESC2,
            t1.elem_id      		BIL_ELE_ID,
            t1.elem_id_padre    	BIL_ELE_ID_PADRE,
        	bil_elem.elem_code		num_cap_old,
        	bil_elem.elem_code2		num_art_old,            
            COALESCE(t1.stanziamento_prev_anno,0)	stanziamento_prev_anno,
            COALESCE(t1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
            COALESCE(t1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
            COALESCE(t1.stanziamento_prev_res_anno,0)	stanziamento_prev_res_anno,
            COALESCE(t1.stanziamento_anno_prec,0)	stanziamento_anno_prec,
            COALESCE(t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
            COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        	COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        	COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        	COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2,  
            --------t1.elem_id_old		elem_id_old,
            COALESCE(t2.impegnato_anno,0) impegnato_anno,
            COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
            COALESCE(t2.impegnato_anno2,0) impegnato_anno2,
            COALESCE(t1.codice_pdc,' ')upb 
    from siac_rep_mptm_up_cap_importi t1
            ----full join siac_rep_impegni_riga  t2
            left join siac_rep_impegni_riga  t2
            on (t1.elem_id	=	t2.elem_id  ---------da sostituire con   --------t1.elem_id_old	=	t2.elem_id
                --and	t1.ente_proprietario_id	=	t2.ente_proprietario
                and	t1.utente	=	t2.utente
                and	t1.utente	=	user_table)
            	/* aggiunto questo join x estrarre l'eventuale riferimento all'ex capitolo */
            left 	join 	siac_r_bil_elem_rel_tempo rel_tempo on rel_tempo.elem_id 	=  t1.elem_id and rel_tempo.data_cancellazione is null
            left	join 	siac_t_bil_elem		bil_elem	on bil_elem.elem_id = rel_tempo.elem_id_old and bil_elem.data_cancellazione is null               
	--01/06/2023 siac-task-issue #24.
	--Sono restituiti i dati in cui almeno uno degli importi non e' 0.
    where COALESCE(t1.stanziamento_prev_anno,0) <> 0 OR COALESCE(t1.stanziamento_prev_anno1,0) <> 0 OR
    		COALESCE(t1.stanziamento_prev_anno2,0) <> 0 OR COALESCE(t1.stanziamento_prev_res_anno,0) <> 0 OR
            COALESCE(t1.stanziamento_anno_prec,0) <> 0 OR COALESCE(t1.stanziamento_prev_cassa_anno,0) <> 0 OR
            COALESCE(t1.stanziamento_fpv_anno_prec,0) <> 0 OR COALESCE(t1.stanziamento_fpv_anno,0) <> 0 OR
            COALESCE(t1.stanziamento_fpv_anno1,0) <> 0 OR COALESCE(t1.stanziamento_fpv_anno2,0) <> 0 OR
            COALESCE(t2.impegnato_anno,0) <> 0 OR COALESCE(t2.impegnato_anno1,0) <> 0 OR
            COALESCE(t2.impegnato_anno2,0) <> 0
	order by missione_code,programma_code,titusc_code,macroag_code   	
loop
      missione_tipo_desc:= classifBilRec.missione_tipo_desc;
      missione_code:= classifBilRec.missione_code;
      missione_desc:= classifBilRec.missione_desc;
      programma_tipo_desc:= classifBilRec.programma_tipo_desc;
      programma_code:= classifBilRec.programma_code;
      programma_desc:= classifBilRec.programma_desc;
      titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
      titusc_code:= classifBilRec.titusc_code;
      titusc_desc:= classifBilRec.titusc_desc;
      macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
      macroag_code:= classifBilRec.macroag_code;
      macroag_desc:= classifBilRec.macroag_desc;
      bil_anno:=classifBilRec.bil_anno;
      bil_ele_code:=classifBilRec.bil_ele_code;
      bil_ele_desc:=classifBilRec.bil_ele_desc;
      bil_ele_code2:=classifBilRec.bil_ele_code2;
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
      impegnato_anno:=classifBilRec.impegnato_anno;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2=classifBilRec.impegnato_anno2;
	  num_cap_old=classifBilRec.num_cap_old;
	  num_art_old=classifBilRec.num_art_old;
	  upb=classifBilRec.upb;

      IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
              /* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
                  la direzione */
          BEGIN    
              SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
              INTO sett_code, sett_descr, classif_id_padre      
                  from siac_r_bil_elem_class r_bil_elem_class,
                      siac_r_class_fam_tree r_class_fam_tree,
                      siac_t_class			t_class,
                      siac_d_class_tipo		d_class_tipo ,
                      siac_t_bil_elem    		capitolo               
              where 
                  r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                  and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and t_class.classif_id 					= 	r_class_fam_tree.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL
                   and r_class_fam_tree.data_cancellazione is NULL;    
                                
                  IF NOT FOUND THEN
                      /* se il settore non esiste restituisco un codice fittizio
                          e cerco se esiste la direzione */
                      sett_code='999';
                      sett_descr='SETTORE NON CONFIGURATO';
              
                    BEGIN
                    SELECT  t_class.classif_code, t_class.classif_desc
                        INTO direz_code, direz_descr
                        from siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class			t_class,
                            siac_d_class_tipo		d_class_tipo ,
                            siac_t_bil_elem    		capitolo               
                    where 
                        r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                        and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                        and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                       -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilità (Direzione)'
                       and d_class_tipo.classif_tipo_code='CDR'
                        and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                         AND r_bil_elem_class.data_cancellazione is NULL
                         AND t_class.data_cancellazione is NULL
                         AND d_class_tipo.data_cancellazione is NULL
                         AND capitolo.data_cancellazione is NULL;	
                   IF NOT FOUND THEN
                      /* se non esiste la direzione restituisco un codice fittizio */
                    direz_code='999';
                    direz_descr='DIREZIONE NON CONFIGURATA';         
                    END IF;
                END;
              
             ELSE
                  /* cerco la direzione con l'ID padre del settore */
               BEGIN
                SELECT  t_class.classif_code, t_class.classif_desc
                    INTO direz_code, direz_descr
                from siac_t_class t_class
                where t_class.classif_id= classif_id_padre;
                IF NOT FOUND THEN
                  direz_code='999';
                  direz_descr='DIREZIONE NON CONFIGURATA';  
                END IF;
                END;
              
              END IF;
          END;    

      ELSE
              /* se non c'è l'ID capitolo restituisco i campi vuoti */
          direz_code='';
          direz_descr='';
          sett_code='';
          sett_descr='';
      END IF;

	return next;
    bil_anno='';
    missione_tipo_code='';
    missione_tipo_desc='';
    missione_code='';
    missione_desc='';
    programma_tipo_code='';
    programma_tipo_desc='';
    programma_code='';
    programma_desc='';
    titusc_tipo_code='';
    titusc_tipo_desc='';
    titusc_code='';
    titusc_desc='';
    macroag_tipo_code='';
    macroag_tipo_desc='';
    macroag_code='';
    macroag_desc='';
    bil_ele_code='';
    bil_ele_desc='';
    bil_ele_code2='';
    bil_ele_desc2='';
    bil_ele_id=0;
    bil_ele_id_padre=0;
    stanziamento_prev_res_anno=0;
    stanziamento_anno_prec=0;
    stanziamento_prev_cassa_anno=0;
    stanziamento_prev_anno=0;
    stanziamento_prev_anno1=0;
    stanziamento_prev_anno2=0;
    impegnato_anno=0;
    impegnato_anno1=0;
    impegnato_anno2=0;
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;
    num_cap_old='';
	num_art_old='';
    direz_code='';
    direz_descr='';
    sett_code='';
    sett_descr='';
	classif_id_padre=0;
    upb='';
    
end loop;
--end if;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga	where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_impegni where utente=user_table;
delete from siac_rep_impegni_riga  where utente=user_table;


raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR079_peg_spese_gestione_struttura" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;


CREATE OR REPLACE FUNCTION siac."BILR079_peg_entrate_gestione_struttura" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric,
  num_cap_old varchar,
  num_art_old varchar,
  direz_code varchar,
  direz_descr varchar,
  sett_code varchar,
  sett_descr varchar,
  upb varchar
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
classif_id_padre integer;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN
/*
	Questa Procedura nasce come copia della procedura BILR047_peg_entrate_previsione.
    Le modifiche effettuate sono quelle per estrarre i dati  dei capitoli di
    GESTIONE invece che di PREVISIONE.
    Per comodità sono state lasciate le stesse tabelle di appoggio (es. siac_rep_cap_ep_imp_riga)
    usate dalla procedura di previsione.
    Anche i nomi dei campi di output sono gli stessi in modo da non dover effettuare
    troppi cambiamenti al report BILR077_peg_senza_fpv_gestione che è copiato dal
    BILR046_peg_senza_fpv.
*/

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo Gestione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
num_cap_old='';
num_art_old='';
direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;
upb='';

select fnc_siac_random_user()
into	user_table;

/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/


--05/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;
 
 
--29/04/2016: aggiunta estrazione del campo UPB che è utilizzato solo per la 
-- regione (report BILR082_peg_gestione_struttura).
-- il report BILR079_peg_gestione_struttura utilizza questa procedura ma non 
-- visualizza il campo UPB.  
insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
   (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
                class_upb.classif_tipo_code='CLASSIFICATORE_36' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	)
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;



insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    

for classifBilRec in

select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        bil_elem.elem_code				num_cap_old,
        bil_elem.elem_code2				num_art_old,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb.pdc,' ')upb
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
            	/* aggiunto questo join x estrarre l'eventuale riferimento all'ex capitolo */
            left 	join 	siac_r_bil_elem_rel_tempo rel_tempo on rel_tempo.elem_id 	=  tb.elem_id and rel_tempo.data_cancellazione is null
            left	join 	siac_t_bil_elem		bil_elem	on bil_elem.elem_id = rel_tempo.elem_id_old and bil_elem.data_cancellazione is null
	--01/06/2023 siac-task-issue #24.
	--Sono restituiti i dati in cui almeno uno degli importi non e' 0.
where COALESCE (tb1.stanziamento_prev_anno,0) <> 0 OR COALESCE (tb1.stanziamento_prev_anno1,0) <> 0 OR
    COALESCE (tb1.stanziamento_prev_anno2,0) <> 0 OR COALESCE (tb1.residui_presunti,0) <> 0 OR
    COALESCE (tb1.previsioni_anno_prec,0) <> 0 OR COALESCE (tb1.stanziamento_prev_cassa_anno,0) <> 0
order by v1.titolo_code,v1.tipologia_code,v1.categoria_code,tb.elem_code::INTEGER,tb.elem_code2::INTEGER            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;
num_cap_old=classifBilRec.num_cap_old;
num_art_old=classifBilRec.num_art_old;
upb=classifBilRec.upb;

IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
		/* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
        	la direzione */
	BEGIN    
		SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
		INTO sett_code, sett_descr, classif_id_padre      
            from siac_r_bil_elem_class r_bil_elem_class,
            	siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo ,
                siac_t_bil_elem    		capitolo               
        where 
            r_bil_elem_class.elem_id 			= 	capitolo.elem_id
            and t_class.classif_id 					= 	r_bil_elem_class.classif_id
            and t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
           AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
            and capitolo.elem_id=classifBilRec.BIL_ELE_ID
             AND r_bil_elem_class.data_cancellazione is NULL
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL
             AND capitolo.data_cancellazione is NULL
             and r_class_fam_tree.data_cancellazione is NULL;    
                          
       		IF NOT FOUND THEN
       			/* se il settore non esiste restituisco un codice fittizio
                	e cerco se esiste la direzione */
     			sett_code='999';
				sett_descr='SETTORE NON CONFIGURATO';
        
              BEGIN
              SELECT  t_class.classif_code, t_class.classif_desc
                  INTO direz_code, direz_descr
                  from siac_r_bil_elem_class r_bil_elem_class,
                      siac_t_class			t_class,
                      siac_d_class_tipo		d_class_tipo ,
                      siac_t_bil_elem    		capitolo               
              where 
                  r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                  and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilità (Direzione)'
                 and d_class_tipo.classif_tipo_code='CDR'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL;	
             IF NOT FOUND THEN
             	/* se non esiste la direzione restituisco un codice fittizio */
              direz_code='999';
              direz_descr='DIREZIONE NON CONFIGURATA';         
              END IF;
          END;
        
       ELSE
       		/* cerco la direzione con l'ID padre del settore */
         BEGIN
          SELECT  t_class.classif_code, t_class.classif_desc
              INTO direz_code, direz_descr
          from siac_t_class t_class
          where t_class.classif_id= classif_id_padre;
          IF NOT FOUND THEN
          	direz_code='999';
			direz_descr='DIREZIONE NON CONFIGURATA';  
          END IF;
          END;
        
        END IF;
    END;    

ELSE
		/* se non c'è l'ID capitolo restituisco i campi vuoti */
	direz_code='';
	direz_descr='';
	sett_code='';
	sett_descr='';
END IF;

return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
num_cap_old='';
num_art_old='';
direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;
upb='';

end loop;
delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR079_peg_entrate_gestione_struttura" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;  
  
--SIAC-TASK #24 - Maurizio - FINE




-- INIZIO 9.SIAC-8899_ripristino.sql



\echo 9.SIAC-8899_ripristino.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8899 Sofia 08.05.2023 inizio 

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp 
(
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean
);

DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_comp_anno ( integer,character varying);

drop FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean
);

drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_econb_anno
(
  id_in integer,
  anno_in varchar
);

create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno 
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;
BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;



 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
raise notice 'importoCurAttuale=%',importoCurAttuale;
/*select tb.importo into importoCurAttuale from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId))
    group by c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    and t.movgest_ts_tipo_code=TIPO_IMP_T;--'T'; */

 /* select
      coalesce(sum(e.movgest_ts_det_importo),0) into importoCurAttuale
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId));*/

  --raise notice 'importoCurAttuale:%', importoCurAttuale;
 --fine nuovo G
 /*for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=id_in
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilancioId
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo accertato anno_in='||anno_in||'Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;*/
 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code <> 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;
raise notice 'importoModifNeg=%',importoModifNeg;
  -- 10.08.2020 Sofia jira SIAC-6865 - inizio
  -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
  if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=id_in
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine
raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione;

  -- anna_economie inizio
   select tb.importo into importoModifINS
   from
   (
      select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
      from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
           siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
           siac_t_movgest_ts_det_mod moddet,
           siac_t_modifica mod, siac_r_modifica_stato rmodstato,
           siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
           siac_d_modifica_tipo tipom
      where rbil.elem_id=id_in
      and	  mov.movgest_id=rbil.movgest_id
      and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
      and   mov.movgest_anno=anno_in::integer
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rstato.movgest_ts_id=ts.movgest_ts_id
      and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
      and   tsdet.movgest_ts_id=ts.movgest_ts_id
      and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
      and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
      -- SIAC-7349
      -- abbiamo tolto il commento nella riga qui sotto perche' d'accordo con Pietro Gambino
      -- e visto che possono anche esserci modifiche ECONB positive
      -- e' bene escluderle dal calcolo importoModifINS
      and   moddet.movgest_ts_det_importo<0 -- importo negativo
      and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
      and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
      and   mod.mod_id=rmodstato.mod_id
      and   atto.attoamm_id=mod.attoamm_id
      and   attostato.attoamm_id=atto.attoamm_id
      and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
      and   tipom.mod_tipo_id=mod.mod_tipo_id
      and   tipom.mod_tipo_code = 'ECONB'
      -- date
      and rbil.data_cancellazione is null
      and rbil.validita_fine is null
      and mov.data_cancellazione is null
      and mov.validita_fine is null
      and ts.data_cancellazione is null
      and ts.validita_fine is null
      and rstato.data_cancellazione is null
      and rstato.validita_fine is null
      and tsdet.data_cancellazione is null
      and tsdet.validita_fine is null
      and moddet.data_cancellazione is null
      and moddet.validita_fine is null
      and mod.data_cancellazione is null
      and mod.validita_fine is null
      and rmodstato.data_cancellazione is null
      and rmodstato.validita_fine is null
      and attostato.data_cancellazione is null
      and attostato.validita_fine is null
      and atto.data_cancellazione is null
      and atto.validita_fine is null
      group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo tipo
    where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
    AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
    order by tipo.movgest_ts_tipo_code desc
    limit 1;

    if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;
raise notice 'importoModifINS=%',importoModifINS;

raise notice 'importoAttuale0=%',importoAttuale;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG
raise notice 'importoAttuale1=%',importoAttuale;

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine
raise notice 'importoAttuale2=%',importoAttuale;

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
raise notice 'importoAttuale3=%',importoAttuale;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean)
    OWNER TO siac;
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp (
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato di competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in and
	  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;


 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	 and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code <> 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

-- 10.08.2020 Sofia jira SIAC-6865 - inizio
  -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
  if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=id_in
      and   rmov.elem_det_comp_tipo_id=idcomp_in::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine

  -- anna_economie inizio
  select tb.importo into importoModifINS
  from
  (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code = 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;

  if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean)
    OWNER TO siac;
	
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno(id_in integer, anno_in character varying, verifica_mod_prov boolean DEFAULT true)
 RETURNS TABLE(annocompetenza character varying, dicuiimpegnato numeric)
AS 
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';
STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';
STATO_MOD_V  constant varchar:='V';
TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0; -- SIAC-7349
attoAmmStatoPId integer:=0;-- SIAC-7349
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;
modStatoVId integer:=0; -- SIAC-7349
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0; -- SIAC-7349
movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; -- SIAC-7349 --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

-- 10.08.2020 Sofia jira siac-6865
movGestStatoPId integer:=null;
importoCurAttAggiudicazione numeric:=0;
BEGIN


 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
      siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
   and bil.bil_id=bilElem.bil_id
   and per.periodo_id=bil.periodo_id;

 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;


 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select bilelem.elem_id into elemIdGestEq
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_code=elemCode
   and bilElem.elem_code2=elemCode2
   and bilElem.elem_code3=elemCode3
   and bilElem.ente_proprietario_id=enteProprietarioId
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and bilElem.bil_id=bilIdElemGestEq
   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

if NOT FOUND THEN
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;


-- SIAC-7349 INIZIO
strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;

	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;

	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;
-- SIAC-7349 FINE

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
	   -- SIAC-7349 INIZIO
          
/*  SIAC-8493 03.12.2021 Sofia spostato fuori ciclo      
    if importoCurAttuale>=0 then
              ----------------
              select tb.importo into importoModifDelta
	          from
	          (
	          	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	          	from siac_r_movgest_bil_elem rbil,
	          	 	siac_t_movgest mov,
	          	 	siac_t_movgest_ts ts,
	          		siac_r_movgest_ts_stato rstato,
	          	  siac_t_movgest_ts_det tsdet,
	          		siac_t_movgest_ts_det_mod moddet,
	          		siac_t_modifica mod,
	          	 	siac_r_modifica_stato rmodstato,
	          		siac_r_atto_amm_stato attostato,
	          	 	siac_t_atto_amm atto,
	          		siac_d_modifica_tipo tipom
	          	where
	          		rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
	          		and	 mov.movgest_id=rbil.movgest_id
	          		and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
	          		and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
	          		and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
	          		and  ts.movgest_id=mov.movgest_id
	          		and  rstato.movgest_ts_id=ts.movgest_ts_id
	          		and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
	          		and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
	          	  and  tsdet.movgest_ts_id=ts.movgest_ts_id
	          		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	          		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	          	 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	          		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	          		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	          		and   mod.mod_id=rmodstato.mod_id
	          		and   atto.attoamm_id=mod.attoamm_id
	          		and   attostato.attoamm_id=atto.attoamm_id
	          		and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
	          		and   tipom.mod_tipo_id=mod.mod_tipo_id
	          		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
	          		and rbil.data_cancellazione is null
	          		and rbil.validita_fine is null
	          		and mov.data_cancellazione is null
	          		and mov.validita_fine is null
	          		and ts.data_cancellazione is null
	          		and ts.validita_fine is null
	          		and rstato.data_cancellazione is null
	          		and rstato.validita_fine is null
	          		and tsdet.data_cancellazione is null
	          		and tsdet.validita_fine is null
	          		and moddet.data_cancellazione is null
	          		and moddet.validita_fine is null
	          		and mod.data_cancellazione is null
	          		and mod.validita_fine is null
	          		and rmodstato.data_cancellazione is null
	          		and rmodstato.validita_fine is null
	          		and attostato.data_cancellazione is null
	          		and attostato.validita_fine is null
	          		and atto.data_cancellazione is null
	          		and atto.validita_fine is null
	          		group by ts.movgest_ts_tipo_id
	          	  ) tb, siac_d_movgest_ts_tipo tipo
	          	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	          	  order by tipo.movgest_ts_tipo_code desc
	          	  limit 1;
	      	  -- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
	          if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;

                  /*Aggiunta delle modifiche ECONB*/
		        -- anna_economie inizio
	          select tb.importo into importoModifINS
		                from
		                (
		                	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
		                	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
	                   	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
		                  siac_t_movgest_ts_det_mod moddet,
	                   	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
		                  siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
	                    siac_d_modifica_tipo tipom
		                where rbil.elem_id=elemIdGestEq
		                and	 mov.movgest_id=rbil.movgest_id
		                and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
	                  and  mov.movgest_anno=anno_in::integer
	                  and  mov.bil_id=bilancioId
		                and  ts.movgest_id=mov.movgest_id
		                and  rstato.movgest_ts_id=ts.movgest_ts_id
		                and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		                and  tsdet.movgest_ts_id=ts.movgest_ts_id
		                and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		                and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
		                and   moddet.movgest_ts_det_importo<0 -- importo negativo
		                and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
		                and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
		                and   mod.mod_id=rmodstato.mod_id
		                and   atto.attoamm_id=mod.attoamm_id
		                and   attostato.attoamm_id=atto.attoamm_id
		                and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
	                   and   tipom.mod_tipo_id=mod.mod_tipo_id
	                   and   tipom.mod_tipo_code = 'ECONB'
		                -- date
		                and rbil.data_cancellazione is null
		                and rbil.validita_fine is null
		                and mov.data_cancellazione is null
		                and mov.validita_fine is null
		                and ts.data_cancellazione is null
		                and ts.validita_fine is null
		                and rstato.data_cancellazione is null
		                and rstato.validita_fine is null
		                and tsdet.data_cancellazione is null
		                and tsdet.validita_fine is null
		                and moddet.data_cancellazione is null
		                and moddet.validita_fine is null
		                and mod.data_cancellazione is null
		                and mod.validita_fine is null
		                and rmodstato.data_cancellazione is null
		                and rmodstato.validita_fine is null
		                and attostato.data_cancellazione is null
		                and attostato.validita_fine is null
		                and atto.data_cancellazione is null
		                and atto.validita_fine is null
	                   group by ts.movgest_ts_tipo_id
	                  ) tb, siac_d_movgest_ts_tipo tipo
	                  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	                  order by tipo.movgest_ts_tipo_code desc
	                  limit 1;

       			 if importoModifINS is null then
	 	            importoModifINS = 0;
	            end if;
            end if; SIAC-8493 03.12.2021 Sofia spostato fuori ciclo   - fine   */
    end if;
   importoAttuale:=importoAttuale+importoCurAttuale;
 
  -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
  --importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);

  -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
  --aggiunta per ECONB
  --importoAttuale:=importoAttuale+abs(importoModifINS);

 end loop;
 
 -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo    
 raise notice 'importoAttuale=%',importoAttuale::varchar;
 if  verifica_mod_prov=true then
  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo modifiche negative per anno_in='||anno_in||'.';
  select tb.importo into importoModifDelta
  from
  (
  	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
  	from siac_r_movgest_bil_elem rbil,
  	 	siac_t_movgest mov,
  	 	siac_t_movgest_ts ts,
  		siac_r_movgest_ts_stato rstato,
  	  siac_t_movgest_ts_det tsdet,
  		siac_t_movgest_ts_det_mod moddet,
  		siac_t_modifica mod,
  	 	siac_r_modifica_stato rmodstato,
  		siac_r_atto_amm_stato attostato,
  	 	siac_t_atto_amm atto,
  		siac_d_modifica_tipo tipom
  	where
  		rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
  		and	 mov.movgest_id=rbil.movgest_id
  		and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
  		and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
  		and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
  		and  ts.movgest_id=mov.movgest_id
  		and  rstato.movgest_ts_id=ts.movgest_ts_id
  		and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
  		and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
    	and  tsdet.movgest_ts_id=ts.movgest_ts_id
  		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
  		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
  	 	and   moddet.movgest_ts_det_importo<0 -- importo negativo
  		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
  		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
  		and   mod.mod_id=rmodstato.mod_id
  		and   atto.attoamm_id=mod.attoamm_id
  		and   attostato.attoamm_id=atto.attoamm_id
  		and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
  		and   tipom.mod_tipo_id=mod.mod_tipo_id
  		and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
  		and rbil.data_cancellazione is null
  		and rbil.validita_fine is null
  		and mov.data_cancellazione is null
  		and mov.validita_fine is null
  		and ts.data_cancellazione is null
  		and ts.validita_fine is null
  		and rstato.data_cancellazione is null
  		and rstato.validita_fine is null
  		and tsdet.data_cancellazione is null
  		and tsdet.validita_fine is null
  		and moddet.data_cancellazione is null
  		and moddet.validita_fine is null
  		and mod.data_cancellazione is null
  		and mod.validita_fine is null
  		and rmodstato.data_cancellazione is null
  		and rmodstato.validita_fine is null
  		and attostato.data_cancellazione is null
  		and attostato.validita_fine is null
  		and atto.data_cancellazione is null
  		and atto.validita_fine is null
  		group by ts.movgest_ts_tipo_id
  	  ) tb, siac_d_movgest_ts_tipo tipo
  	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  	  order by tipo.movgest_ts_tipo_code desc
  	  limit 1;
   
      if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;
      raise notice 'importoModifDelta=%',importoModifDelta::varchar;

      -- aggiunta negative	
      importoAttuale:=importoAttuale-(importoModifDelta);

      raise notice 'importoAttuale=%',importoAttuale::varchar;

      strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo modifiche negative ECONB per anno_in='||anno_in||'.';  
      select tb.importo into importoModifINS
	  from
	  (
		select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
		from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
			 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
		     siac_t_movgest_ts_det_mod moddet,
			 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
		  	 siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
	   		 siac_d_modifica_tipo tipom
		where rbil.elem_id=elemIdGestEq
		and	 mov.movgest_id=rbil.movgest_id
		and  mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
		and  mov.movgest_anno=anno_in::integer
		and  mov.bil_id=bilancioId
		and  ts.movgest_id=mov.movgest_id
		and  rstato.movgest_ts_id=ts.movgest_ts_id
		and  rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
		and  tsdet.movgest_ts_id=ts.movgest_ts_id
		and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
		and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
		and   moddet.movgest_ts_det_importo<0 -- importo negativo
		and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
		and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
		and   mod.mod_id=rmodstato.mod_id
		and   atto.attoamm_id=mod.attoamm_id
		and   attostato.attoamm_id=atto.attoamm_id
		and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
		and   tipom.mod_tipo_id=mod.mod_tipo_id
		and   tipom.mod_tipo_code = 'ECONB'
		-- date
        and rbil.data_cancellazione is null
        and rbil.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and ts.data_cancellazione is null
        and ts.validita_fine is null
        and rstato.data_cancellazione is null
        and rstato.validita_fine is null
        and tsdet.data_cancellazione is null
        and tsdet.validita_fine is null
        and moddet.data_cancellazione is null
        and moddet.validita_fine is null
        and mod.data_cancellazione is null
        and mod.validita_fine is null
        and rmodstato.data_cancellazione is null
        and rmodstato.validita_fine is null
        and attostato.data_cancellazione is null
        and attostato.validita_fine is null
        and atto.data_cancellazione is null
        and atto.validita_fine is null
        group by ts.movgest_ts_tipo_id
      ) tb, siac_d_movgest_ts_tipo tipo
	  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
	  order by tipo.movgest_ts_tipo_code desc
	  limit 1;
		
	  if importoModifINS is null then
		    importoModifINS = 0;
	  end if;   
      raise notice 'importoModifINS=%',importoModifINS::varchar;

      --aggiunta per ECONB
      importoAttuale:=importoAttuale+abs(importoModifINS);
	  raise notice 'importoAttuale=%',importoAttuale::varchar;
 end if;
 -- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo - fine

 -- 10.08.2020 Sofia Jira SIAC-6865 - inizio
 -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
 if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=elemIdGestEq
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilIdElemGestEq
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
    raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione::varchar;
    importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
    raise notice 'importoAttuale=%',importoAttuale::varchar;
  end if;
  -- 10.08.2020 Sofia Jira SIAC-6865 - fine

end if;


-- SIAC-8493 03.12.2021 Sofia spostato fuori ciclo
raise notice '@@@@@ in uscita importoAttuale=%',importoAttuale::varchar;
annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno (integer, varchar, boolean)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp (
  id_in integer,
  id_comp integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE
/*
Calcolo dell'impegnato di un capitolo di previsione id_in su una componente id_comp per l'anno anno_it,
utile al calcolo della disponibilita' a variare
quindi non tiene conto di grandezze da considerare solo per disponibilita' ad impegnare: limite massimo impegnabile e modifiche di impegno negative su provvedimento provvisorio
*/

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_ATTO_P constant varchar:='PROVVISORIO';
STATO_ATTO_D constant varchar:='DEFINITIVO';

STATO_MOD_V  constant varchar:='V';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

strMessaggio varchar(1500):=NVL_STR;

attoAmmStatoDId integer:=0;
attoAmmStatoPId integer:=0;
bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

modStatoVId integer:=0;
movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;
movGestStatoIdProvvisorio integer:=0;
movGestTsId integer:=0;


importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifDelta  numeric:=0;
importoModifINS numeric:=0; --aggiunta per ECONB

movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

-- 10.08.2020 Sofia jira siac-6865
movGestStatoPId integer:=null;
importoCurAttAggiudicazione numeric:=0;
BEGIN

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP elem_id='||id_in||'.';

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId e elem_tipo_code per elem_id='||id_in||'.';
 select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
       into strict elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
      siac_t_bil bil, siac_t_periodo per
 where bilElem.elem_id=id_in
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
   and bil.bil_id=bilElem.bil_id
   and per.periodo_id=bil.periodo_id;

 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
        RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo fase operativa per bilancioId='||bilancioId
               ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select  faseOp.fase_operativa_code into  faseOpCode
 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
 where bilFase.bil_id =bilancioId
   and bilfase.data_cancellazione is null
   and bilFase.validita_fine is null
   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
   and faseOp.data_cancellazione is null
 order by bilFase.bil_fase_operativa_id desc;

 if NOT FOUND THEN
   RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza UP.Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
 -- lettura elemento bil di gestione equivalente
 if faseOpCode is not null and faseOpCode!=NVL_STR then
  	if  faseOpCode = FASE_OP_BIL_PREV then
      	-- lettura bilancioId annoBilancio precedente per lettura elemento di bilancio equivalente
            	select bil.bil_id into strict bilIdElemGestEq
                from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
                where per.anno=((annoBilancio::integer)-1)::varchar
                  and per.ente_proprietario_id=enteProprietarioId
                  and bil.periodo_id=per.periodo_id
                  and perTipo.periodo_tipo_id=per.periodo_tipo_id
                  and perTipo.periodo_tipo_code='SY';
    else
        	bilIdElemGestEq:=bilancioId;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;

 -- lettura elemIdGestEq
 strMessaggio:='Calcolo impegnato competenza UP.Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
              ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';

 select bilelem.elem_id into elemIdGestEq
 from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
 where bilElem.elem_code=elemCode
   and bilElem.elem_code2=elemCode2
   and bilElem.elem_code3=elemCode3
   and bilElem.ente_proprietario_id=enteProprietarioId
   and bilElem.data_cancellazione is null
   and bilElem.validita_fine is null
   and bilElem.bil_id=bilIdElemGestEq
   and bilElemTipo.elem_tipo_id=bilElem.elem_tipo_id
   and bilElemTipo.elem_tipo_code=TIPO_CAP_UG;

if NOT FOUND THEN
else
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsTipoId.';
 select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoPId per attoamm_stato_code=PROVVISORIO';
	  select d.attoamm_stato_id into strict attoAmmStatoPId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and d.attoamm_stato_code=STATO_ATTO_P;

	 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'idcomp_in='||id_comp
				  ||'. Calcolo attoAmmStatoDId per attoamm_stato_code=DEFINTIVO';

	  select d.attoamm_stato_id into strict attoAmmStatoDId
	  from siac_d_atto_amm_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and  d.attoamm_stato_code=STATO_ATTO_D;

	select  movGestStato.movgest_stato_id into strict movGestStatoIdProvvisorio
	  from siac_d_movgest_stato movGestStato
	  where movGestStato.ente_proprietario_id=enteProprietarioId
	  and   movGestStato.movgest_stato_code=STATO_P;

	select d.mod_stato_id into strict modStatoVId
	  from siac_d_modifica_stato d
	  where d.ente_proprietario_id=enteProprietarioId
	  and   d.mod_stato_code=STATO_MOD_V;



 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
               ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'.Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
              ||'Per elemento gest equivalente elem_id='||elemIdGestEq||'. Inizio ciclo per anno_in='||anno_in||'.';
 for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=elemIdGestEq
     and   movGestRel.data_cancellazione is null
	 and movGestRel.elem_det_comp_tipo_id=id_comp
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilIdElemGestEq
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer
                   and   movGest.data_cancellazione is null
                   and   movGest.validita_fine is null)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId
                  and   movGestTsRel.validita_fine is null
                  and   movGestTsRel.data_cancellazione is null);



    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;

	   if importoCurAttuale>=0 then

		  select tb.importo into importoModifDelta
				from
				(
					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil,
					 	siac_t_movgest mov,
					 	siac_t_movgest_ts ts,
						siac_r_movgest_ts_stato rstato,
					  siac_t_movgest_ts_det tsdet,
						siac_t_movgest_ts_det_mod moddet,
						siac_t_modifica mod,
					 	siac_r_modifica_stato rmodstato,
						siac_r_atto_amm_stato attostato,
					 	siac_t_atto_amm atto,
						siac_d_modifica_tipo tipom
					where
						rbil.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
						and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349 deve essere sulla compoenente idcomp_in
						and	 mov.movgest_id=rbil.movgest_id
						and  mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
						and  mov.movgest_anno=anno_in::integer -- anno dell impegno = annoMovimento
						and  mov.bil_id=bilIdElemGestEq -- UID del bilancio in annoEsercizio
						and  ts.movgest_id=mov.movgest_id
						and  rstato.movgest_ts_id=ts.movgest_ts_id
						and  rstato.movgest_stato_id!=movGestStatoId -- Impegno non ANNULLATO
						and  rstato.movgest_stato_id!=movGestStatoIdProvvisorio -- Impegno non PROVVISORIO
					  and  tsdet.movgest_ts_id=ts.movgest_ts_id
						and  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
						and  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
						and   moddet.movgest_ts_det_importo<0 -- importo negativo
						and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
						and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
						and   mod.mod_id=rmodstato.mod_id
						and   atto.attoamm_id=mod.attoamm_id
						and   attostato.attoamm_id=atto.attoamm_id
						and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
						and   tipom.mod_tipo_id=mod.mod_tipo_id
						and   tipom.mod_tipo_code <> 'ECONB'  -- SIAC-7349 non tengo conto di questa condizione
						-- date
						and rbil.data_cancellazione is null
						and rbil.validita_fine is null
						and mov.data_cancellazione is null
						and mov.validita_fine is null
						and ts.data_cancellazione is null
						and ts.validita_fine is null
						and rstato.data_cancellazione is null
						and rstato.validita_fine is null
						and tsdet.data_cancellazione is null
						and tsdet.validita_fine is null
						and moddet.data_cancellazione is null
						and moddet.validita_fine is null
						and mod.data_cancellazione is null
						and mod.validita_fine is null
						and rmodstato.data_cancellazione is null
						and rmodstato.validita_fine is null
						and attostato.data_cancellazione is null
						and attostato.validita_fine is null
						and atto.data_cancellazione is null
						and atto.validita_fine is null
						group by ts.movgest_ts_tipo_id
					  ) tb, siac_d_movgest_ts_tipo tipo
					  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
					  order by tipo.movgest_ts_tipo_code desc
					  limit 1;
				-- 14.05.2020 Manuel - aggiunto parametro verifica_mod_prov
				if importoModifDelta is null or verifica_mod_prov is false then importoModifDelta:=0; end if;

		/*Aggiunta delle modifiche ECONB*/
				 -- anna_economie inizio
   				select tb.importo into importoModifINS
 				from
 				(
 					select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
					from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
 			   	 	siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
				    siac_t_movgest_ts_det_mod moddet,
 			   	 	siac_t_modifica mod, siac_r_modifica_stato rmodstato,
				    siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
 			        siac_d_modifica_tipo tipom
				where rbil.elem_id=elemIdGestEq
				and rbil.elem_det_comp_tipo_id=id_comp::integer --SIAC-7349
				and	  mov.movgest_id=rbil.movgest_id
				and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
 			   	and   mov.movgest_anno=anno_in::integer
 			   	and   mov.bil_id=bilancioId
				and   ts.movgest_id=mov.movgest_id
				and   rstato.movgest_ts_id=ts.movgest_ts_id
				and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
				and   tsdet.movgest_ts_id=ts.movgest_ts_id
				and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
				and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
				and   moddet.movgest_ts_det_importo<0 -- importo negativo
				and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
				and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
				and   mod.mod_id=rmodstato.mod_id
				and   atto.attoamm_id=mod.attoamm_id
				and   attostato.attoamm_id=atto.attoamm_id
				and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
 			   and   tipom.mod_tipo_id=mod.mod_tipo_id
 			   and   tipom.mod_tipo_code = 'ECONB'
				-- date
				and rbil.data_cancellazione is null
				and rbil.validita_fine is null
				and mov.data_cancellazione is null
				and mov.validita_fine is null
				and ts.data_cancellazione is null
				and ts.validita_fine is null
				and rstato.data_cancellazione is null
				and rstato.validita_fine is null
				and tsdet.data_cancellazione is null
				and tsdet.validita_fine is null
				and moddet.data_cancellazione is null
				and moddet.validita_fine is null
				and mod.data_cancellazione is null
				and mod.validita_fine is null
				and rmodstato.data_cancellazione is null
				and rmodstato.validita_fine is null
				and attostato.data_cancellazione is null
				and attostato.validita_fine is null
				and atto.data_cancellazione is null
				and atto.validita_fine is null
 			   group by ts.movgest_ts_tipo_id
 			 ) tb, siac_d_movgest_ts_tipo tipo
 			 where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
 			 order by tipo.movgest_ts_tipo_code desc
 			 limit 1;

			 if importoModifINS is null then
			 	importoModifINS = 0;
			 end if;



		   end if;

    end if;

    importoAttuale:=importoAttuale+importoCurAttuale-(importoModifDelta);
  --aggiunta per ECONB
	importoAttuale:=importoAttuale+abs(importoModifINS);
 end loop;

 -- 10.08.2020 Sofia Jira SIAC-6865 - inizio
 -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
 if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=elemIdGestEq
      and   rmov.elem_det_comp_tipo_id=id_comp::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilIdElemGestEq
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;

    importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
  end if;
  -- 10.08.2020 Sofia Jira SIAC-6865 - fine

end if;

annoCompetenza:=anno_in;
diCuiImpegnato:=importoAttuale;

return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoup_comp_anno_comp(integer, integer, character varying, boolean)
    OWNER TO siac;


create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno 
(
  id_in integer,
  anno_in varchar
)
RETURNS TABLE 
(
  annocompetenza varchar,
  dicuiimpegnato_econb numeric
) AS
$body$
DECLARE



strMessaggio varchar(1500):='';

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

importoModifNeg  numeric:=0;
importoModifEconb  numeric:=0;

esisteMovPerElemId INTEGER:=0;

BEGIN

strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Inizio.';
annoCompetenza:=anno_in;
diCuiImpegnato_EconB:=0;

strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Verifica esistenza movimenti..';
select 1 into esisteMovPerElemId 
from siac_r_movgest_bil_elem re, siac_t_movgest mov
where re.elem_id=id_in
and     mov.movgest_id=re.movgest_id
and     mov.movgest_anno=anno_in::integer
and     re.data_cancellazione  is null 
and     re.validita_fine  is null;
if esisteMovPerElemId is null then esisteMovPerElemId:=0; end if;
raise notice 'esisteMovPerElemId=%',esisteMovPerElemId;

if esisteMovPerElemId <>0 then



 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in='' then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
 into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and      bilElem.data_cancellazione is null
 and      bil.bil_id=bilElem.bil_id
 and      per.periodo_id=bil.periodo_id;


 strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'. Inizio calcolo totale modifiche negative prov. per anno_in='||anno_in||'.';
 raise notice 'strMessaggio %',strMessaggio;
 select tb.importo  into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id 
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
	       	  siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	          siac_t_movgest_ts_det_mod moddet,
    	 	  siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	  	      siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
              siac_d_modifica_tipo tipom,
              siac_d_movgest_tipo tipo ,
              siac_d_movgest_stato stato ,
              siac_d_modifica_stato stato_modif,
              siac_d_atto_amm_stato stato_atto
	where  rbil.elem_id= id_in -- <elem_id_in >
	and	      mov.movgest_id=rbil.movgest_id
	and  	  mov.movgest_tipo_id=tipo.movgest_tipo_id 
	and   	  tipo.movgest_tipo_code ='I'
    and       mov.movgest_anno=anno_in::integer -- <annoCompetenza>
    and       mov.bil_id=bilancioId
	and   	  ts.movgest_id=mov.movgest_id
	and       rstato.movgest_ts_id=ts.movgest_ts_id
	and       rstato.movgest_stato_id=stato.movgest_stato_id 
	and   	  stato.movgest_stato_code !='A'
	and   	  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  	  moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and  	  moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and  	  moddet.movgest_ts_det_importo<0 -- importo negativo
	and   	  rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   	  rmodstato.mod_stato_id=stato_modif.mod_stato_id 
	and   	  stato_modif.mod_stato_code ='V'
	and       mod.mod_id=rmodstato.mod_id
	and  	  atto.attoamm_id=mod.attoamm_id
	and   	  attostato.attoamm_id=atto.attoamm_id
	and   	  attostato.attoamm_stato_id=stato_atto.attoamm_stato_id 
    and   	  stato_atto.attoamm_stato_code ='PROVVISORIO'
    and   	  tipom.mod_tipo_id=mod.mod_tipo_id
    and   	  tipom.mod_tipo_code <> 'ECONB'
    and    	  not exists 
    (
    select 1 
    from siac_r_movgest_aggiudicazione  ragg 
    where ragg.movgest_id_da =mov.movgest_id 
    and     ragg.data_cancellazione  is null 
    and     ragg.validita_fine is null 
    )
	and 	  rbil.data_cancellazione is null
	and 	  rbil.validita_fine is null
	and		  mov.data_cancellazione is null
	and		  mov.validita_fine is null
	and 	  ts.data_cancellazione is null
	and 	  ts.validita_fine is null
	and 	  rstato.data_cancellazione is null
	and 	  rstato.validita_fine is null
	and 	  tsdet.data_cancellazione is null
	and 	  tsdet.validita_fine is null
	and 	  moddet.data_cancellazione is null
	and 	  moddet.validita_fine is null
	and 	  mod.data_cancellazione is null
	and 	  mod.validita_fine is null
	and       rmodstato.data_cancellazione is null
	and		  rmodstato.validita_fine is null
	and 	  attostato.data_cancellazione is null
	and 	  attostato.validita_fine is null
	and 	  atto.data_cancellazione is null
	and 	  atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T';
  if importoModifNeg is null then importoModifNeg:=0; end if;
  
  raise notice 'importoModifNeg=%',importoModifNeg::varchar;
 
  strMessaggio:='Calcolo totale movimenti modifiche negative prov e econb elem_id='||id_in||'. Inizio calcolo totale modifiche econb  per anno_in='||anno_in||'.';
  raise notice 'strMessaggio %',strMessaggio;
 select tb.importo into importoModifEconb
  from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
       	       siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	           siac_t_movgest_ts_det_mod moddet,
	       	   siac_t_modifica mod, siac_r_modifica_stato rmodstato,
  	           siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
               siac_d_modifica_tipo tipom,
	           siac_d_movgest_tipo tipo ,
               siac_d_movgest_stato stato ,
	           siac_d_modifica_stato stato_modif,
               siac_d_atto_amm_stato stato_atto
	where  rbil.elem_id= id_in -- <elem_id_id>
 	and	      mov.movgest_id=rbil.movgest_id
	and       mov.movgest_tipo_id=tipo.movgest_tipo_id 
	and       tipo.movgest_tipo_code ='I'
    and       mov.movgest_anno=anno_in::integer -- <annoCompetenza>
    and       mov.bil_id=bilancioId
	and       ts.movgest_id=mov.movgest_id
	and       rstato.movgest_ts_id=ts.movgest_ts_id
	and       rstato.movgest_stato_id=stato.movgest_stato_id 
	and       stato.movgest_stato_code !='A'
	and       tsdet.movgest_ts_id=ts.movgest_ts_id
	and       moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and       moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and       moddet.movgest_ts_det_importo<0 -- importo negativo
	and       rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and       rmodstato.mod_stato_id=stato_modif.mod_stato_id 
	and       stato_modif.mod_stato_code ='V'
	and       mod.mod_id=rmodstato.mod_id
	and       atto.attoamm_id=mod.attoamm_id
	and       attostato.attoamm_id=atto.attoamm_id
	and       attostato.attoamm_stato_id=stato_atto.attoamm_stato_id 
    and       stato_atto.attoamm_stato_code in ('PROVVISORIO','DEFINITIVO')
    and       tipom.mod_tipo_id=mod.mod_tipo_id
    and       tipom.mod_tipo_code = 'ECONB'
	and       rbil.data_cancellazione is null
	and       rbil.validita_fine is null
	and       mov.data_cancellazione is null
	and       mov.validita_fine is null
	and       ts.data_cancellazione is null
	and       ts.validita_fine is null
	and       rstato.data_cancellazione is null
	and       rstato.validita_fine is null
	and       tsdet.data_cancellazione is null
	and       tsdet.validita_fine is null
	and       moddet.data_cancellazione is null
	and       moddet.validita_fine is null
	and       mod.data_cancellazione is null
	and       mod.validita_fine is null
	and       rmodstato.data_cancellazione is null
	and       rmodstato.validita_fine is null
	and       attostato.data_cancellazione is null
	and       attostato.validita_fine is null
	and       atto.data_cancellazione is null
	and       atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T';
  if importoModifEconb is null then importoModifEconb:=0; end if;
  raise notice 'importoModifEconb=%',importoModifEconb::varchar;


  annoCompetenza:=anno_in;
  diCuiImpegnato_EconB:=importoModifNeg+importoModifEconb;

else

   annoCompetenza:=anno_in;
   diCuiImpegnato_EconB:=0;
   raise notice 'Movimento non esistenti.';
end if;

raise notice 'anno_in=%',anno_in;
raise notice 'diCuiImpegnato_EconB=%',diCuiImpegnato_EconB::varchar;

return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_econb_anno(integer, varchar)   OWNER TO siac;


-- SIAC-8899 Sofia 08.05.2023 fine 




-- INIZIO 1.DDL-tabelle.sql



\echo 1.DDL-tabelle.sql


drop view if exists siac.siac_v_dwh_mutuo;
drop view if exists siac.siac_v_dwh_mutuo_movgest_ts;
drop view if exists siac.siac_v_dwh_mutuo_programma;
drop view if exists siac.siac_v_dwh_mutuo_rata;
drop view if exists siac.siac_v_dwh_mutuo_variazione;
drop view if exists siac.siac_v_dwh_storico_mutuo;

--DROP TABLE if exists siac.siac_t_mutuo_num;
CREATE TABLE if not exists siac.siac_t_mutuo_num (
	mutuo_num_id serial4 NOT NULL,
	mutuo_numero int4 NOT NULL,
--
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_t_mutuo_num PRIMARY KEY (mutuo_num_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo_num 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
DROP INDEX IF EXISTS idx_siac_t_mutuo_num;
CREATE INDEX idx_siac_t_mutuo_num ON siac.siac_t_mutuo_num (ente_proprietario_id, mutuo_numero);



--DROP TABLE if exists siac.siac_d_mutuo_stato CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_stato (
	mutuo_stato_id serial4 NOT NULL,
	mutuo_stato_code varchar(200) NOT NULL,
	mutuo_stato_desc varchar(500) NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_stato PRIMARY KEY (mutuo_stato_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_stato 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);



--DROP TABLE if exists siac.siac_d_mutuo_periodo_rimborso CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_periodo_rimborso (
	mutuo_periodo_rimborso_id serial4 NOT NULL,
	mutuo_periodo_rimborso_code varchar(200) NOT NULL,
	mutuo_periodo_rimborso_desc varchar(500) NULL,
	mutuo_periodo_numero_mesi int4 NULL,	
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_periodo_rimborso PRIMARY KEY (mutuo_periodo_rimborso_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_stato 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

--DROP TABLE if exists siac.siac_d_mutuo_variazione_tipo CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_variazione_tipo (
	mutuo_variazione_tipo_id serial4 NOT NULL,
	mutuo_variazione_tipo_code varchar(200) NOT NULL,
	mutuo_variazione_tipo_desc varchar(500) NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_variazione_tipo PRIMARY KEY (mutuo_variazione_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_variazione_tipo 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);


--DROP TABLE if exists siac.siac_d_mutuo_tipo_tasso CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_tipo_tasso (
	mutuo_tipo_tasso_id serial4 NOT NULL,
	mutuo_tipo_tasso_code varchar(200) NOT NULL,
	mutuo_tipo_tasso_desc varchar(500) NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_tipo_tasso PRIMARY KEY (mutuo_tipo_tasso_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_stato 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);




--DROP TABLE if exists siac.siac_t_mutuo CASCADE;
CREATE TABLE if not exists siac.siac_t_mutuo (
	mutuo_id serial4 NOT NULL,
	mutuo_numero int4 NOT NULL,
	mutuo_oggetto varchar(500) NULL,
	mutuo_stato_id int4 NOT NULL,
	mutuo_tipo_tasso_id int4 NOT NULL,
	mutuo_data_atto timestamp NULL,
	mutuo_soggetto_id int4 NULL,
	mutuo_somma_iniziale numeric NULL,
	mutuo_somma_effettiva numeric NULL,
	mutuo_tasso numeric NULL,	
	mutuo_tasso_euribor numeric NULL,	
	mutuo_tasso_spread numeric NULL,	
	mutuo_durata_anni int4 NULL,	
	mutuo_anno_inizio int4 NULL,	
	mutuo_anno_fine int4 NULL,	
	mutuo_periodo_rimborso_id int4 NULL,
	mutuo_data_scadenza_prima_rata timestamp NULL,
	mutuo_annualita numeric NULL,
	mutuo_preammortamento numeric NULL,
	mutuo_contotes_id int4 NULL,
	mutuo_attoamm_id int4 NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200),
	CONSTRAINT pk_siac_t_mutuo PRIMARY KEY (mutuo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_soggetto_siac_t_mutuo 
		FOREIGN KEY (mutuo_soggetto_id) REFERENCES siac.siac_t_soggetto(soggetto_id),
	CONSTRAINT siac_d_mutuo_stato_siac_t_mutuo 
		FOREIGN KEY (mutuo_stato_id) REFERENCES siac.siac_d_mutuo_stato(mutuo_stato_id),
	CONSTRAINT siac_d_mutuo_periodo_rimborso_siac_t_mutuo 
		FOREIGN KEY (mutuo_periodo_rimborso_id) REFERENCES siac.siac_d_mutuo_periodo_rimborso(mutuo_periodo_rimborso_id),
	CONSTRAINT siac_d_mutuo_tipo_tasso_siac_t_mutuo 
		FOREIGN KEY (mutuo_tipo_tasso_id) REFERENCES siac.siac_d_mutuo_tipo_tasso(mutuo_tipo_tasso_id),
	CONSTRAINT siac_d_contotesoreria_siac_t_mutuo 
		FOREIGN KEY (mutuo_contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_atto_amm_siac_t_mutuo 
		FOREIGN KEY (mutuo_attoamm_id) REFERENCES siac.siac_t_atto_amm(attoamm_id)

		
);


--DROP TABLE if exists siac.siac_s_mutuo_storico CASCADE;
CREATE TABLE if not exists siac.siac_s_mutuo_storico (
	mutuo_storico_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	mutuo_numero int4 NOT NULL,
	mutuo_oggetto varchar(500) NULL,
	mutuo_stato_id int4 NOT NULL,
	mutuo_tipo_tasso_id int4 NOT NULL,
	mutuo_data_atto timestamp NULL,
	mutuo_soggetto_id int4 NULL,
	mutuo_somma_iniziale numeric NULL,
	mutuo_somma_effettiva numeric NULL,
	mutuo_tasso numeric NULL,	
	mutuo_tasso_euribor numeric NULL,	
	mutuo_tasso_spread numeric NULL,	
	mutuo_durata_anni int4 NULL,	
	mutuo_anno_inizio int4 NULL,	
	mutuo_anno_fine int4 NULL,	
	mutuo_periodo_rimborso_id int4 NULL,
	mutuo_data_scadenza_prima_rata timestamp NULL,
	mutuo_annualita numeric NULL,
	mutuo_preammortamento numeric NULL,
	mutuo_contotes_id int4 NULL,
	mutuo_attoamm_id int4 NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200),
	CONSTRAINT pk_siac_s_mutuo_storico PRIMARY KEY (mutuo_storico_id),
	CONSTRAINT siac_t_ente_proprietario_siac_s_mutuo_storico 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_soggetto_siac_s_mutuo_storico  
		FOREIGN KEY (mutuo_soggetto_id) REFERENCES siac.siac_t_soggetto(soggetto_id),
	CONSTRAINT siac_d_mutuo_stato_siac_s_mutuo_storico  
		FOREIGN KEY (mutuo_stato_id) REFERENCES siac.siac_d_mutuo_stato(mutuo_stato_id),
	CONSTRAINT siac_d_mutuo_periodo_rimborso_siac_s_mutuo_storico  
		FOREIGN KEY (mutuo_periodo_rimborso_id) REFERENCES siac.siac_d_mutuo_periodo_rimborso(mutuo_periodo_rimborso_id),
	CONSTRAINT siac_d_mutuo_tipo_tasso_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_tipo_tasso_id) REFERENCES siac.siac_d_mutuo_tipo_tasso(mutuo_tipo_tasso_id),
	CONSTRAINT siac_d_contotesoreria_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_atto_amm_siac_s_mutuo_storico 
		FOREIGN KEY (mutuo_attoamm_id) REFERENCES siac.siac_t_atto_amm(attoamm_id)
);


--DROP TABLE if exists siac.siac_t_mutuo_variazione CASCADE;
CREATE TABLE if not exists siac.siac_t_mutuo_variazione (
	mutuo_variazione_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	mutuo_variazione_tipo_id int4 NOT NULL,
	mutuo_variazione_anno int4 NULL,
	mutuo_variazione_num_rata int4 NULL,
	mutuo_variazione_anno_fine_piano_ammortamento int4 NULL,
	mutuo_variazione_num_rata_finale int4 NULL,
	mutuo_variazione_importo_rata numeric NULL,
	mutuo_variazione_tasso_euribor numeric NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_t_mutuo_variazione PRIMARY KEY (mutuo_variazione_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo_variazione 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_t_mutuo_variazione 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_d_mutuo_variazione_tipo_siac_t_mutuo_variazione 
		FOREIGN KEY (mutuo_variazione_tipo_id) REFERENCES siac.siac_d_mutuo_variazione_tipo(mutuo_variazione_tipo_id)

);

DROP TABLE if exists siac.siac_t_mutuo_piano_ammortamento CASCADE;

--DROP TABLE if exists siac.siac_t_mutuo_rata CASCADE;
CREATE TABLE if not exists siac.siac_t_mutuo_rata (
	mutuo_rata_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	mutuo_rata_anno int4 NOT NULL,
	mutuo_rata_num_rata_piano int4 NOT NULL,
	mutuo_rata_num_rata_anno int4 NOT NULL,
	mutuo_rata_data_scadenza date NOT NULL,
	mutuo_rata_importo numeric NULL,
	mutuo_rata_importo_quota_interessi numeric NULL,
	mutuo_rata_importo_quota_capitale numeric NULL,
	mutuo_rata_importo_quota_oneri numeric NULL,
	mutuo_rata_debito_residuo numeric NOT NULL,
	mutuo_rata_debito_iniziale numeric NOT null,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_t_mutuo_rata PRIMARY KEY (mutuo_rata_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_mutuo_rata
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_t_mutuo_rata 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id)
);



--DROP TABLE if exists siac.siac_r_mutuo_movgest_ts CASCADE;
CREATE TABLE if not exists siac.siac_r_mutuo_movgest_ts (
	mutuo_movgest_ts_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	movgest_ts_id int4 NOT NULL,
	mutuo_movgest_ts_importo_iniziale numeric NULL,
	mutuo_movgest_ts_importo_finale numeric NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_r_mutuo_movgest_ts PRIMARY KEY (mutuo_movgest_ts_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_mutuo_movgest_ts 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_r_mutuo_movgest_ts 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_movgest_ts_siac_r_mutuo_movgest_ts 
		FOREIGN KEY (movgest_ts_id) REFERENCES siac.siac_t_movgest_ts(movgest_ts_id)
);


--DROP TABLE if exists siac.siac_r_mutuo_programma CASCADE;
CREATE TABLE if not exists siac.siac_r_mutuo_programma (
	mutuo_programma_id serial4 NOT NULL,
	mutuo_id int4 NOT NULL,
	programma_id int4 NOT NULL,
	mutuo_programma_importo_iniziale numeric NULL,
	mutuo_programma_importo_finale numeric NULL,
	--
	ente_proprietario_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_r_mutuo_programma PRIMARY KEY (mutuo_programma_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_mutuo_programma 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_r_mutuo_programma 
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_programma_siac_r_mutuo_programma
		FOREIGN KEY (programma_id) REFERENCES siac.siac_t_programma(programma_id)
);

alter table siac.siac_t_mutuo add column if not exists 	mutuo_data_inizio_piano_ammortamento date NULL;
alter table siac.siac_t_mutuo add column if not exists 	mutuo_data_scadenza_ultima_rata date NULL;
alter table siac.siac_s_mutuo_storico add column if not exists 	mutuo_data_inizio_piano_ammortamento date NULL;
alter table siac.siac_s_mutuo_storico add column if not exists 	mutuo_data_scadenza_ultima_rata date NULL;

alter table siac.siac_t_mutuo alter column mutuo_data_scadenza_prima_rata  type date;
alter table siac.siac_t_mutuo alter column mutuo_data_atto  type date;
alter table siac.siac_s_mutuo_storico alter column mutuo_data_scadenza_prima_rata type date;
alter table siac.siac_s_mutuo_storico alter column mutuo_data_atto type date;

alter table siac.siac_t_mutuo_rata add column if not exists mutuo_rata_debito_iniziale numeric NULL;

create table if not exists siac_bko_t_mutuo (
	bko_mutuo_id serial4 NOT NULL,
	bko_mutuo_numero int4 NOT NULL,
	bko_mutuo_tipo_tasso varchar(1) NOT NULL,
	bko_mutuo_istituto_codice varchar(10) NULL,
	bko_mutuo_istituto varchar(500) NULL,
	bko_mutuo_somma_mutuata numeric NULL,
	bko_mutuo_oggetto varchar(500) NULL,
	bko_mutuo_documento_anno int4 NULL,
	bko_mutuo_documento_numero int4 NULL,
	bko_mutuo_tasso numeric NULL,
	bko_mutuo_tasso_euribor numeric NULL,	
	bko_mutuo_tasso_spread numeric NULL,
	bko_mutuo_durata_anni int4 NULL,
	bko_mutuo_anno_inizio int4 NULL,
	bko_mutuo_anno_fine int4 NULL,
	bko_mutuo_importo_oneri numeric NULL,	
	bko_mutuo_periodo_rimborso int4 NULL,
	bko_mutuo_scadenza_giorono int4 NULL,
	bko_mutuo_scadenza_mese int4 NULL,
	bko_mutuo_numero_rate_anno int4 NULL,
	bko_mutuo_data_atto date NULL
);

create table if not exists siac_bko_t_mutuo_rata (
	bko_mutuo_rata_id serial4 NOT NULL,
	bko_mutuo_numero int4 NOT NULL,
	bko_mutuo_rata_anno int4 NOT NULL,
	bko_mutuo_rata_num_rata int4 NOT NULL,
	bko_mutuo_rata_importo_quota_interessi numeric NULL,
	bko_mutuo_rata_importo_quota_capitale numeric NULL,
	bko_mutuo_rata_importo_quota_oneri numeric NULL,
	bko_mutuo_rata_debito_residuo numeric NULL,
	bko_mutuo_rata_debito_iniziale numeric null
);




-- INIZIO 2.SIAC-TASK-20.sql



\echo 2.SIAC-TASK-20.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-TASK-20  Sofia 16.05.2023 inizio 

drop view if exists siac.siac_v_dwh_mutuo;
create or replace view siac.siac_v_dwh_mutuo
(
    ente_proprietario_id,
    mutuo_numero,
    mutuo_oggetto,
	mutuo_stato_code,
	mutuo_stato_desc,
	mutuo_tipo_tasso_code,
	mutuo_tipo_tasso_desc,
	mutuo_data_atto,
	mutuo_soggetto_id,
	mutuo_soggetto_code,
	mutuo_soggetto_desc,
	mutuo_soggetto_codice_fiscale,
	mutuo_soggetto_partiva,
	mutuo_somma_iniziale,
	mutuo_somma_effettiva,
	mutuo_tasso,	
	mutuo_tasso_euribor,	
	mutuo_tasso_spread,	
	mutuo_durata_anni,	
	mutuo_anno_inizio,	
	mutuo_anno_fine,	
	mutuo_periodo_rimborso_code,
	mutuo_periodo_rimborso_desc,
	mutuo_periodo_rimborso_mesi,
	mutuo_data_scadenza_prima_rata,
	mutuo_data_scad_ultima_rata,
	mutuo_annualita,
	mutuo_preammortamento,
	mutuo_data_inizio_piano_amm,
	mutuo_contotes_code,
	mutuo_contotes_desc,
	mutuo_attoamm_anno,
	mutuo_attoamm_numero,
	mutuo_attoamm_tipo_code,
	mutuo_attoamm_tipo_desc,
	mutuo_attoamm_sac_tipo_code,
	mutuo_attoamm_sac_tipo_desc,
	mutuo_attoamm_sac_code,
	mutuo_validita_inizio,
	mutuo_validita_fine
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
	mutuo.mutuo_oggetto,
	stato.mutuo_stato_code,
	stato.mutuo_stato_desc,
	tasso_tipo.mutuo_tipo_tasso_code mutuo_tipo_tasso_code,
	tasso_tipo.mutuo_tipo_tasso_desc mutuo_tipo_tasso_desc,
	mutuo.mutuo_data_atto,
	sog.soggetto_id mutuo_soggetto_id,
	sog.soggetto_code mutuo_soggetto_code,
	sog.soggetto_desc mutuo_soggetto_desc,
	sog.codice_fiscale mutuo_soggetto_codice_fiscale,
	sog.partita_iva mutuo_soggetto_partiva,
	mutuo.mutuo_somma_iniziale,
	mutuo.mutuo_somma_effettiva,
	mutuo.mutuo_tasso,	
	mutuo.mutuo_tasso_euribor,	
	mutuo.mutuo_tasso_spread,	
	mutuo.mutuo_durata_anni,	
	mutuo.mutuo_anno_inizio,	
	mutuo.mutuo_anno_fine,	
	per_rimborso.mutuo_periodo_rimborso_code  mutuo_periodo_rimborso_code,
	per_rimborso.mutuo_periodo_rimborso_desc   mutuo_periodo_rimborso_desc,
	per_rimborso.mutuo_periodo_numero_mesi    mutuo_periodo_rimborso_mesi,
	mutuo.mutuo_data_scadenza_prima_rata,
	mutuo.mutuo_data_scadenza_ultima_rata mutuo_data_scad_ultima_rata,
	mutuo.mutuo_annualita,
	mutuo.mutuo_preammortamento,
	mutuo.mutuo_data_inizio_piano_ammortamento mutuo_data_inizio_piano_amm,
	conto.contotes_code  mutuo_contotes_code,
	conto.contotes_desc   mutuo_contotes_desc,
	atto.attoamm_anno mutuo_attoamm_anno,
	atto.attoamm_numero mutuo_attoamm_numero,
	tipo_atto.attoamm_tipo_code mutuo_attoamm_tipo_code,
	tipo_atto.attoamm_tipo_desc mutuo_attoamm_tipo_desc,
	(case when rc.classif_id is not null then tipo_class.classif_tipo_code else ''  end )::varchar(200) mutuo_attoamm_sac_tipo_code,
    (case when rc.classif_id is not null then tipo_class.classif_tipo_desc  else ''  end )::varchar(500) mutuo_attoamm_sac_tipo_desc,
    (case when rc.classif_id is not null then c.classif_code  else ''  end )::varchar(500) mutuo_attoamm_sac_code,
    mutuo.validita_inizio  mutuo_validita_inizio,
    mutuo.validita_fine     mutuo_validita_fine
FROM siac_d_mutuo_Stato stato,
             siac_t_mutuo mutuo 
              left join siac_d_mutuo_tipo_tasso  tasso_tipo on ( mutuo.mutuo_tipo_tasso_id=tasso_tipo.mutuo_tipo_tasso_id)
              left join siac_t_atto_amm atto  
                     join siac_d_atto_amm_tipo tipo_atto on ( tipo_atto.attoamm_tipo_id=atto.attoamm_tipo_id)
                     left join siac_r_atto_amm_class rc 
                            join siac_t_class c join siac_d_class_tipo tipo_class on ( tipo_class.classif_tipo_id=c.classif_tipo_id and tipo_class.classif_tipo_code in ('CDC','CDR'))
                             on (c.classif_id=rc.classif_id)
                     on (rc.attoamm_id=atto.attoamm_id
                            and  rc.data_cancellazione is null 
                            and  rc.validita_fine is null ) 
                on ( mutuo.mutuo_attoamm_id=atto.attoamm_id)
              left join siac_t_soggetto sog on ( mutuo.mutuo_soggetto_id=sog.soggetto_id )
              left join siac_d_contotesoreria  conto on (mutuo.mutuo_contotes_id=conto.contotes_id)
              left join siac_d_mutuo_periodo_rimborso per_rimborso on (mutuo.mutuo_periodo_rimborso_id=per_rimborso.mutuo_periodo_rimborso_id) 
where stato.mutuo_stato_id =mutuo.mutuo_stato_id 
and     mutuo.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_mutuo owner to siac;


drop view if exists siac.siac_v_dwh_mutuo_movgest_ts;
create or replace view siac.siac_v_dwh_mutuo_movgest_ts
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_movgest_tipo,
    mutuo_movgest_anno,
    mutuo_movgest_numero,
    mutuo_movgest_subnumero ,
    mutuo_movgest_importo_iniziale,
    mutuo_movgest_importo_finale
 )
AS
(
SELECT 
    per.ente_proprietario_id,
    per.anno::integer anno_bilancio,
    mutuo.mutuo_numero,
    tipo.movgest_tipo_code mutuo_movgest_tipo,
    mov.movgest_anno mutuo_movgest_anno,
    mov.movgest_numero::integer movgest_numero,
    (case when tipo_ts.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)::integer mutuo_movgest_subnumero,
    rmov.mutuo_movgest_ts_importo_iniziale mutuo_movgest_importo_iniziale,
    rmov.mutuo_movgest_ts_importo_finale mutuo_movgest_importo_finale
FROM siac_t_bil bil,siac_t_periodo per,
             siac_t_movgest mov,siac_d_movgest_tipo tipo,
             siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipo_ts,
             siac_t_mutuo mutuo ,siac_r_mutuo_movgest_ts  rmov
where bil.periodo_id=per.periodo_id 
and     mov.bil_id=bil.bil_id 
and     tipo.movgest_tipo_id=mov.movgest_tipo_id 
and     ts.movgest_id=mov.movgest_id 
and     tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id 
and     rmov.movgest_ts_id =ts.movgest_ts_id 
and     mutuo.mutuo_id=rmov.mutuo_id 
and     rmov.data_cancellazione  is null 
and     mutuo.data_cancellazione  is null
and     mov.data_cancellazione  is null
and     ts.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_mutuo_movgest_ts owner to siac;


drop view if exists siac.siac_v_dwh_mutuo_programma;
create or replace view siac.siac_v_dwh_mutuo_programma
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_programma_tipo,
    mutuo_programma_code,
    mutuo_movgest_importo_iniziale,
    mutuo_movgest_importo_finale
 )
AS
(
SELECT 
    per.ente_proprietario_id,
    per.anno::integer anno_bilancio,
    mutuo.mutuo_numero,
    tipo.programma_tipo_code mutuo_programma_tipo,
    prog.programma_code  mutuo_programma_code,
    rp.mutuo_programma_importo_iniziale ,
    rp.mutuo_programma_importo_finale 
FROM siac_t_bil bil,siac_t_periodo per,
             siac_t_programma prog,siac_d_programma_tipo tipo,
             siac_t_mutuo mutuo ,siac_r_mutuo_programma  rp 
where bil.periodo_id=per.periodo_id 
and      prog.bil_id=bil.bil_id 
and      tipo.programma_tipo_id=prog.programma_tipo_id  
and      rp.programma_id=prog.programma_id  
and      mutuo.mutuo_id=rp.mutuo_id 
and      rp.data_cancellazione  is null 
and      mutuo.data_cancellazione  is null
and      prog.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_programma owner to siac;

drop view if exists siac.siac_v_dwh_mutuo_rata;
create or replace view siac.siac_v_dwh_mutuo_rata
(
    ente_proprietario_id,
    mutuo_numero,
    mutuo_rata_anno,
	mutuo_rata_num_rata_piano,
	mutuo_rata_num_rata_anno,
	mutuo_rata_data_scadenza,
	mutuo_rata_importo,
	mutuo_rata_importo_q_interessi,
	mutuo_rata_importo_q_capitale,
	mutuo_rata_importo_q_oneri,
	mutuo_rata_debito_residuo,
	mutuo_rata_debito_iniziale
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
    rata.mutuo_rata_anno,
	rata.mutuo_rata_num_rata_piano,
	rata.mutuo_rata_num_rata_anno,
	rata.mutuo_rata_data_scadenza,
	rata.mutuo_rata_importo,
	rata.mutuo_rata_importo_quota_interessi mutuo_rata_importo_q_interessi,
	rata.mutuo_rata_importo_quota_capitale  mutuo_rata_importo_q_capitale ,
	rata.mutuo_rata_importo_quota_oneri     mutuo_rata_importo_q_oneri,
	rata.mutuo_rata_debito_residuo,
	rata.mutuo_rata_debito_iniziale
FROM siac_t_mutuo mutuo ,siac_t_mutuo_rata rata 
where  mutuo.mutuo_id=rata.mutuo_id 
and      mutuo.data_cancellazione  is null
and      rata.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_rata owner to siac;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_variazione;
create or replace view siac.siac_v_dwh_mutuo_variazione
(
    ente_proprietario_id,
	mutuo_variazione_anno,
	mutuo_variazione_num_rata,
   	mutuo_variazione_tipo_code,
   	mutuo_variazione_tipo_desc,
    mutuo_numero,   	
	mutuo_var_anno_fine_piano_amm,
	mutuo_variazione_num_rata_fin,
	mutuo_variazione_importo_rata,
	mutuo_variazione_tasso_euribor
 )
AS
(
SELECT 
    var.ente_proprietario_id,
    var.mutuo_variazione_anno ,
    var.mutuo_variazione_num_rata ,
    tipo.mutuo_variazione_tipo_code ,
    tipo.mutuo_variazione_tipo_desc ,
    mutuo.mutuo_numero,
    var.mutuo_variazione_anno_fine_piano_ammortamento mutuo_var_anno_fine_piano_amm,
    var.mutuo_variazione_num_rata_finale mutuo_variazione_num_rata_fin,
	var.mutuo_variazione_importo_rata,
	var.mutuo_variazione_tasso_euribor
FROM  siac_t_mutuo mutuo ,siac_t_mutuo_variazione  var,siac_d_mutuo_variazione_tipo  tipo 
where tipo.mutuo_variazione_tipo_id =var.mutuo_variazione_id 
and      mutuo.mutuo_id=var.mutuo_id 
and      mutuo.data_cancellazione  is null
and      var.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_variazione owner to siac;


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_storico_mutuo;
create or replace view siac.siac_v_dwh_storico_mutuo
(
    ente_proprietario_id,
    mutuo_numero,
	mutuo_oggetto,
	mutuo_stato_code,
	mutuo_stato_desc,
	mutuo_tipo_tasso_code,
	mutuo_tipo_tasso_desc,
	mutuo_data_atto,
	mutuo_soggetto_id,
	mutuo_soggetto_code,
	mutuo_soggetto_desc,
	mutuo_soggetto_codice_fiscale,
	mutuo_soggetto_partiva,
	mutuo_somma_iniziale,
	mutuo_somma_effettiva,
	mutuo_tasso,	
	mutuo_tasso_euribor,	
	mutuo_tasso_spread,	
	mutuo_durata_anni,	
	mutuo_anno_inizio,	
	mutuo_anno_fine,	
	mutuo_periodo_rimborso_code,
	mutuo_periodo_rimborso_desc,
	mutuo_periodo_rimborso_mesi,
	mutuo_data_scadenza_prima_rata,
	mutuo_data_scad_ultima_rata,
	mutuo_annualita,
	mutuo_preammortamento,
	mutuo_data_inizio_piano_amm,
	mutuo_contotes_code,
	mutuo_contotes_desc,
	mutuo_attoamm_anno,
	mutuo_attoamm_numero,
	mutuo_attoamm_tipo_code,
	mutuo_attoamm_tipo_desc,
	mutuo_attoamm_sac_tipo_code,
	mutuo_attoamm_sac_tipo_desc,
	mutuo_attoamm_sac_code,
	mutuo_st_validita_inizio,
	mutuo_st_validita_fine,
	mutuo_st_data_creazione
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
	mutuo.mutuo_oggetto,
	stato.mutuo_stato_code,
	stato.mutuo_stato_desc,
	tasso_tipo.mutuo_tipo_tasso_code mutuo_tipo_tasso_code,
	tasso_tipo.mutuo_tipo_tasso_desc mutuo_tipo_tasso_desc,
	mutuo.mutuo_data_atto,
	sog.soggetto_id mutuo_soggetto_id,
	sog.soggetto_code mutuo_soggetto_code,
	sog.soggetto_desc mutuo_soggetto_desc,
	sog.codice_fiscale mutuo_soggetto_codice_fiscale,
	sog.partita_iva mutuo_soggetto_partiva,
	mutuo.mutuo_somma_iniziale,
	mutuo.mutuo_somma_effettiva,
	mutuo.mutuo_tasso,	
	mutuo.mutuo_tasso_euribor,	
	mutuo.mutuo_tasso_spread,	
	mutuo.mutuo_durata_anni,	
	mutuo.mutuo_anno_inizio,	
	mutuo.mutuo_anno_fine,	
	per_rimborso.mutuo_periodo_rimborso_code  mutuo_periodo_rimborso_code,
	per_rimborso.mutuo_periodo_rimborso_desc   mutuo_periodo_rimborso_desc,
	per_rimborso.mutuo_periodo_numero_mesi    mutuo_periodo_rimborso_mesi,
	mutuo.mutuo_data_scadenza_prima_rata,
	mutuo.mutuo_data_scadenza_ultima_rata mutuo_data_scad_ultima_rata,
	mutuo.mutuo_annualita,
	mutuo.mutuo_preammortamento,
	mutuo.mutuo_data_inizio_piano_ammortamento mutuo_data_inizio_piano_amm,
	conto.contotes_code  mutuo_contotes_code,
	conto.contotes_desc   mutuo_contotes_desc,
	atto.attoamm_anno mutuo_attoamm_anno,
	atto.attoamm_numero mutuo_attoamm_numero,
	tipo_atto.attoamm_tipo_code mutuo_attoamm_tipo_code,
	tipo_atto.attoamm_tipo_desc mutuo_attoamm_tipo_desc,
	(case when rc.classif_id is not null then tipo_class.classif_tipo_code else ''  end )::varchar(200) mutuo_attoamm_sac_tipo_code,
    (case when rc.classif_id is not null then tipo_class.classif_tipo_desc  else ''  end )::varchar(500) mutuo_attoamm_sac_tipo_desc,
    (case when rc.classif_id is not null then c.classif_code  else ''  end )::varchar(500) mutuo_attoamm_sac_code,
    mutuo.validita_inizio     mutuo_st_validita_inizio,
    mutuo.validita_fine        mutuo_st_validita_fine,
    mutuo.data_creazione    mutuo_st_data_creazione
    
FROM siac_d_mutuo_Stato stato,
             siac_s_mutuo_storico mutuo 
              left join siac_d_mutuo_tipo_tasso  tasso_tipo on ( mutuo.mutuo_tipo_tasso_id=tasso_tipo.mutuo_tipo_tasso_id)
              left join siac_t_atto_amm atto  
                     join siac_d_atto_amm_tipo tipo_atto on ( tipo_atto.attoamm_tipo_id=atto.attoamm_tipo_id)
                     left join siac_r_atto_amm_class rc 
                            join siac_t_class c join siac_d_class_tipo tipo_class on ( tipo_class.classif_tipo_id=c.classif_tipo_id and tipo_class.classif_tipo_code in ('CDC','CDR'))
                             on (c.classif_id=rc.classif_id)
                     on (rc.attoamm_id=atto.attoamm_id
                            and  rc.data_cancellazione is null 
                            and  rc.validita_fine is null ) 
                on ( mutuo.mutuo_attoamm_id=atto.attoamm_id)
              left join siac_t_soggetto sog on ( mutuo.mutuo_soggetto_id=sog.soggetto_id )
              left join siac_d_contotesoreria  conto on (mutuo.mutuo_contotes_id=conto.contotes_id)
              left join siac_d_mutuo_periodo_rimborso per_rimborso on (mutuo.mutuo_periodo_rimborso_id=per_rimborso.mutuo_periodo_rimborso_id) 
where stato.mutuo_stato_id =mutuo.mutuo_stato_id 
and     mutuo.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_storico_mutuo owner to siac;




-- SIAC-TASK-20  Sofia 16.05.2023 fine 




-- INIZIO fnc_siac_bko_mutui_caricamento_massivo.sql



\echo fnc_siac_bko_mutui_caricamento_massivo.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop function if exists siac.fnc_siac_bko_mutui_caricamento_massivo (offset_mutuo_numero integer,p_ente_code varchar);
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_mutui_caricamento_massivo (
  offset_mutuo_numero integer,
  p_ente_code varchar
)
RETURNS VOID
AS
$body$
DECLARE

BEGIN
	
	if offset_mutuo_numero is null then
		raise notice 'offset_mutuo_numero is null';
		return;
	end if;
	if p_ente_code is null then
		raise notice 'p_ente_code is null';
		return;
	end if;
	
	raise notice 'insert into siac_t_mutuo';
	
	INSERT INTO siac.siac_t_mutuo
	(mutuo_numero, mutuo_oggetto, mutuo_stato_id, mutuo_tipo_tasso_id, mutuo_data_atto, mutuo_somma_iniziale, mutuo_somma_effettiva, mutuo_tasso, mutuo_tasso_euribor,mutuo_tasso_spread,mutuo_durata_anni, mutuo_anno_inizio, mutuo_anno_fine, mutuo_periodo_rimborso_id
	, mutuo_data_scadenza_prima_rata, mutuo_annualita, mutuo_preammortamento, mutuo_contotes_id, mutuo_attoamm_id, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		offset_mutuo_numero+sbtm.bko_mutuo_numero,
		bko_mutuo_oggetto,
		sdms.mutuo_stato_id,
		sdmtt.mutuo_tipo_tasso_id,
		bko_mutuo_data_atto,
		bko_mutuo_somma_mutuata,
		bko_mutuo_somma_mutuata,
		bko_mutuo_tasso,
		bko_mutuo_tasso_euribor,
		bko_mutuo_tasso_spread,
		bko_mutuo_durata_anni,
		bko_mutuo_anno_inizio,
		bko_mutuo_anno_fine,
		sdmpr.mutuo_periodo_rimborso_id,
		to_date(bko_mutuo_scadenza_giorono||'/'||bko_mutuo_scadenza_mese||'/'||bko_mutuo_anno_inizio, 'dd/MM/yyyy'), -- data scadenza prima rata
		bko_t_mutuo_rata_group.importo_diviso_nrrate * (12/sdmpr.mutuo_periodo_numero_mesi), -- mutuo_annualita
		null, -- mutuo_preammortamento
		null, --mutuo_contotes_id
		null, --mutuo_attoamm_id
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo sbtm
	, siac_d_mutuo_stato sdms 
	, siac_d_mutuo_tipo_tasso sdmtt 
	, siac_d_mutuo_periodo_rimborso sdmpr 
	, siac_t_ente_proprietario step
	, (select
		sbtmr .bko_mutuo_numero,
		(sum(sbtmr .bko_mutuo_rata_importo_quota_capitale) + sum(sbtmr .bko_mutuo_rata_importo_quota_interessi) + sum(sbtmr .bko_mutuo_rata_importo_quota_oneri))
			/ count(*) as importo_diviso_nrrate  
		from siac_bko_t_mutuo_rata sbtmr
		group by sbtmr .bko_mutuo_numero) as  bko_t_mutuo_rata_group
	where sdms .mutuo_stato_code = 'D'
	and sdmtt.mutuo_tipo_tasso_code = sbtm.bko_mutuo_tipo_tasso
	and sdmpr.mutuo_periodo_numero_mesi = sbtm.bko_mutuo_periodo_rimborso
	and step.ente_code = p_ente_code
	and step.in_uso
	and not exists (
		select 1 from siac_t_mutuo, siac_t_ente_proprietario e
		where mutuo_numero = offset_mutuo_numero+sbtm.bko_mutuo_numero
		and e.ente_proprietario_id = step.ente_proprietario_id 
	)
	and bko_t_mutuo_rata_group.bko_mutuo_numero = sbtm.bko_mutuo_numero;

 	raise notice 'update siac_t_mutuo_num';
 	
	update siac_t_mutuo_num 
	set mutuo_numero = (select max(mutuo_numero) from siac_t_mutuo stm , siac_t_ente_proprietario step 
		where stm.ente_proprietario_id = step.ente_proprietario_id 
		and step.ente_code = p_ente_code
		and step.in_uso)
	, login_operazione = 'migrazione_mutui'
	, data_modifica = now()
	where ente_proprietario_id = (select ente_proprietario_id from siac_t_ente_proprietario step 
		where step.ente_code = p_ente_code
		and step.in_uso);
	
	raise notice 'bonifica soggetti siac_t_mutuo';
	
	update siac_t_mutuo stm
	set mutuo_soggetto_id = sts.soggetto_id
	from 
	siac_t_soggetto sts
	, (select distinct bko_mutuo_istituto_codice , bko_mutuo_istituto from siac_bko_t_mutuo sbtm ) as istituto_distinc
	, siac_bko_t_mutuo a
	where upper(sts.soggetto_desc ) like upper('%'||istituto_distinc.bko_mutuo_istituto||'%')
	and a.bko_mutuo_istituto_codice = istituto_distinc.bko_mutuo_istituto_codice
	and offset_mutuo_numero+a.bko_mutuo_numero = stm.mutuo_numero
	and stm.ente_proprietario_id=sts.ente_proprietario_id;	

	raise notice 'insert into siac.siac_t_mutuo_rata';
	
	INSERT INTO siac.siac_t_mutuo_rata
	(mutuo_id, mutuo_rata_anno, mutuo_rata_num_rata_piano, mutuo_rata_num_rata_anno, mutuo_rata_data_scadenza, mutuo_rata_importo, mutuo_rata_importo_quota_interessi, mutuo_rata_importo_quota_capitale, mutuo_rata_importo_quota_oneri
	, mutuo_rata_debito_residuo, mutuo_rata_debito_iniziale, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		stm.mutuo_id,
		stbmr.bko_mutuo_rata_anno,
		(stbmr.bko_mutuo_rata_anno - stm.mutuo_anno_inizio ) * (12/sdmpr.mutuo_periodo_numero_mesi) + stbmr.bko_mutuo_rata_num_rata as numero_rata_piano,
		stbmr.bko_mutuo_rata_num_rata
		,stm.mutuo_data_scadenza_prima_rata + ((stbmr.bko_mutuo_rata_anno - stm.mutuo_anno_inizio - 1) *  (12/sdmpr.mutuo_periodo_numero_mesi) + stbmr.bko_mutuo_rata_num_rata + floor((12 - date_part('month', stm.mutuo_data_scadenza_prima_rata)) / sdmpr.mutuo_periodo_numero_mesi + 1) - 1) * CAST(sdmpr.mutuo_periodo_numero_mesi||' month' AS Interval) as  mutuo_rata_data_scadenza,
		bko_mutuo_rata_importo_quota_interessi+bko_mutuo_rata_importo_quota_capitale+bko_mutuo_rata_importo_quota_oneri as mutuo_rata_importo,
		bko_mutuo_rata_importo_quota_interessi,
		bko_mutuo_rata_importo_quota_capitale,
		bko_mutuo_rata_importo_quota_oneri,
		bko_mutuo_rata_debito_residuo,
		bko_mutuo_rata_debito_iniziale,
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo_rata stbmr
	, siac_t_mutuo stm
	, siac_t_ente_proprietario step
	, siac_d_mutuo_periodo_rimborso sdmpr 
	where stm.mutuo_numero = offset_mutuo_numero + stbmr .bko_mutuo_numero
	and step.ente_code = p_ente_code
	and step.in_uso
	and sdmpr.mutuo_periodo_rimborso_id = stm.mutuo_periodo_rimborso_id
	and not exists (
		select 1 from siac_t_mutuo_rata, siac_t_ente_proprietario e
		where siac_t_mutuo_rata.mutuo_id = stm.mutuo_id 
		and siac_t_mutuo_rata.mutuo_rata_num_rata_anno = bko_mutuo_rata_num_rata
		and siac_t_mutuo_rata.mutuo_rata_anno = bko_mutuo_rata_anno
		and e.ente_proprietario_id  = step.ente_proprietario_id
	);
	
exception
/*    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;*/
    when others  THEN
     RAISE EXCEPTION '% Errore : %-%.',' altro errore',SQLSTATE,SQLERRM;
	
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;




-- INIZIO fnc_siac_cons_entita_impegno_from_capitolospesa.sql



\echo fnc_siac_cons_entita_impegno_from_capitolospesa.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop function if exists siac.fnc_siac_cons_entita_impegno_from_capitolospesa
(
 _uid_capitolospesa integer, 
 _anno varchar, 
 _filtro_crp varchar, 
 _limit integer, 
 _page integer
 );

CREATE OR REPLACE function  siac.fnc_siac_cons_entita_impegno_from_capitolospesa
(
 _uid_capitolospesa integer, 
 _anno varchar, 
 _filtro_crp varchar, 
 _limit integer, 
 _page integer
 )
 RETURNS table
 (
  uid                                              integer, 
  impegno_anno                          integer, 
  impegno_numero                     numeric, 
  impegno_desc                           varchar, 
  impegno_stato                          varchar, 
  impegno_importo                     numeric, 
  soggetto_code                            varchar, 
  soggetto_desc                             varchar, 
  attoamm_numero                     integer, 
  attoamm_anno                          varchar, 
  attoamm_oggetto                      varchar, 
  attoal_causale                            varchar, 
  attoamm_tipo_code                  varchar, 
  attoamm_tipo_desc                   varchar, 
  attoamm_stato_desc                 varchar, 
  attoamm_sac_code                   varchar, 
  attoamm_sac_desc                    varchar, 
  pdc_code                                     varchar, 
  pdc_desc                                      varchar, 
  impegno_anno_capitolo            integer, 
  impegno_nro_capitolo               integer, 
  impegno_nro_articolo                integer, 
  impegno_flag_prenotazione      varchar, 
  impegno_cup                              varchar, 
  impegno_cig                               varchar, 
  impegno_tipo_debito                 varchar, 
  impegno_motivo_assenza_cig varchar, 
  impegno_componente               varchar, 
  cap_sac_code                             varchar, 
  cap_sac_desc                             varchar, 
  imp_sac_code                            varchar, 
  imp_sac_desc                            varchar, 
  -- SIAC-8877 Paolo 17/05/2023
  programma                                varchar, 
  cronoprogramma                      varchar)
 AS
$body$


DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	raise notice 'STO LANCIANDO LA FNC GIUSTA ****';
	raise notice '_uid_capitolospesa=%',_uid_capitolospesa::varchar;
    raise notice '_anno=%',_anno;
    raise notice '_filtro_crp=%',_filtro_crp;
	RETURN QUERY 
		with imp_sogg_attoamm as 
		(
			with imp_sogg as (
				select distinct
					soggall.elem_id,
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc,
                    -- 29.06.2018 Sofia jira siac-6193
					soggall.impegno_nro_capitolo,
					soggall.impegno_nro_articolo,
					soggall.impegno_anno_capitolo,
                    soggall.impegno_flag_prenotazione,
                    soggall.impegno_cig,
  					soggall.impegno_cup,
                    soggall.impegno_motivo_assenza_cig,
            		soggall.impegno_tipo_debito,
                    -- 11.05.2020 SIAC-7349 SR210
                    soggall.impegno_componente,
                    -- SIAC-8877 Paolo 17/05/2023
                    soggall.programma_code,
                    soggall.cronop_code
				from (
					with za as (
						select
						    zzz.elem_id,
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.zzz_soggetto_code,
							zzz.zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc,
                            -- 29.06.2018 Sofia jira siac-6193
                            zzz.impegno_nro_capitolo,
                            zzz.impegno_nro_articolo,
                            zzz.impegno_anno_capitolo,
                            zzz.impegno_flag_prenotazione,
                            zzz.impegno_cig,
  							zzz.impegno_cup,
                            zzz.impegno_motivo_assenza_cig,
            				zzz.impegno_tipo_debito,
                            --11/05/2020 SIAC-7349 SR210
                            zzz.impegno_componente,
                            -- SIAC-8877 Paolo 17/05/2023
                            zzz.programma_code,
                            zzz.cronop_code
						from (
							with impegno as (


								select
									bilelem.elem_id, 
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc,
                                    -- 29.06.2018 Sofia jira siac-6193
                                    bilelem.elem_code::integer impegno_nro_capitolo,
                                    bilelem.elem_code2::integer impegno_nro_articolo,
                                    t.anno::integer impegno_anno_capitolo,
                                    c.siope_assenza_motivazione_id,
                                    c.siope_tipo_debito_id,
                                    --11.05.2020 Mr SIAC-7349 SR210 tiro fuori l'id per la join con la tabella del tipo componente
                                    b.elem_det_comp_tipo_id
                                    --
								from
									siac_t_bil_elem bilelem,
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t,
									siac_t_movgest_ts c
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and bilelem.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=bilelem.elem_id
								and bilelem.elem_id=_uid_capitolospesa
                                and t.anno = _anno
							),
							siope_assenza_motivazione as
                            (
								select
									d.siope_assenza_motivazione_id,
									d.siope_assenza_motivazione_code,
									d.siope_assenza_motivazione_desc
								from siac_d_siope_assenza_motivazione d
								where d.data_cancellazione is null
							),
							siope_tipo_debito as
                            (
								select
									d.siope_tipo_debito_id,
									d.siope_tipo_debito_code,
									d.siope_tipo_debito_desc
								from siac_d_siope_tipo_debito d
								where d.data_cancellazione is null
							),
							soggetto as
                            (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							),
							impegno_flag_prenotazione as
                            (
								select
									r.movgest_ts_id,
									r.boolean
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'flagPrenotazione'
							),
							impegno_cig as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cig'
							),
							impegno_cup as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cup'
							),
                            --11.05.2020 SIAC-7349 MR SR210 lista di tutte le componenti
                            componente_desc AS
                            (
                                select * from 
                                siac_d_bil_elem_det_comp_tipo tipo
                                --where tipo.data_cancellazione is NULL --da discuterne. in questo caso prende solo le componenti non cancellate
                            ),
                            -- SIAC-8877 Paolo 17/05/2023
							programma as
							(
								select stm.movgest_ts_id,
									       prog.programma_code
								from 	siac_t_movgest m,
											siac_t_movgest_ts stm, 
											siac_r_movgest_ts_programma r_prog,
											siac_t_programma prog,
											siac_t_bil stb,
											siac_t_periodo stp,
											siac_r_movgest_bil_elem re
								where  re.elem_id=_uid_capitolospesa
								and       m.movgest_id=re.movgest_id								
								and       stb.bil_id = m.bil_id 
								and       stb.periodo_id = stp.periodo_id 
							    and       stp.anno =_anno --anno bilancio
								and       stm.movgest_id = m.movgest_id 
								and       r_prog.movgest_ts_id = stm.movgest_ts_id
								and       prog.programma_id = r_prog.programma_id 
								and       r_prog.data_cancellazione  is null
								and       prog.data_cancellazione is null
								and       re.data_cancellazione is null 
								and       m.data_cancellazione is null
								and       stm.data_cancellazione is null
								and       now() between r_prog.validita_inizio and coalesce(r_prog.validita_fine, now())
								and       now() between prog.validita_inizio and coalesce(prog.validita_fine, now())
								and       now() between re.validita_inizio and coalesce(re.validita_fine, now())
								and       now() between m.validita_inizio and coalesce(m.validita_fine, now())
								and       now() between stm.validita_inizio and coalesce(stm.validita_fine, now())
								order by r_prog.data_creazione desc 
								--limit 1
							),
							-- SIAC-8877 Paolo 17/05/2023
							cronoprogramma as
							(
								select	stm.movgest_ts_id,
											prog.programma_code,
											cronop.cronop_code
								from 	siac_t_movgest m,
											siac_t_bil stb,
											siac_t_periodo stp,
											siac_t_movgest_ts stm, 
											siac_r_movgest_ts_cronop_elem srmtce,
											siac_t_cronop_elem crono,
											siac_t_programma prog,
											siac_r_movgest_bil_elem re,
											siac_t_cronop cronop 
								where re.elem_id=_uid_capitolospesa	
								and     m.movgest_id=re.movgest_id
								and     stb.bil_id = m.bil_id 
								and     stb.periodo_id = stp.periodo_id 
								and     stp.anno =_anno --anno bilancio
								and     m.movgest_id = stm.movgest_id 
								and     stm.movgest_ts_id = srmtce.movgest_ts_id
								and     srmtce.cronop_id = crono.cronop_id
								and     cronop.cronop_id= crono.cronop_id
								and     prog.programma_id = cronop.programma_id
								and     srmtce.data_cancellazione is null
								and     crono.data_cancellazione is null
								and     prog.data_cancellazione is null
								and     m.data_cancellazione is null
								and     re.data_cancellazione is null
								and     stm.data_cancellazione is null
								and     cronop.data_cancellazione is null
								and     now() between re.validita_inizio and coalesce(re.validita_fine, now())
								and     now() between srmtce.validita_inizio and coalesce(srmtce.validita_fine, now())
								and     now() between crono.validita_inizio and coalesce(crono.validita_fine, now())
								and     now() between prog.validita_inizio and coalesce(prog.validita_fine, now())
								and     now() between m.validita_inizio and coalesce(m.validita_fine, now())
								and     now() between stm.validita_inizio and coalesce(stm.validita_fine, now())
								and     now() between cronop.validita_inizio and coalesce(cronop.validita_fine, now())
							    order by srmtce.data_creazione desc 
							--	limit 1
							)
							select
							    impegno.elem_id,
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code zzz_soggetto_code,
								soggetto.soggetto_desc zzz_soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc,
                                -- 29.06.2018 Sofia jira siac-6193
                                impegno.impegno_nro_capitolo,
                                impegno.impegno_nro_articolo,
                                impegno.impegno_anno_capitolo,
                                siope_assenza_motivazione.siope_assenza_motivazione_desc impegno_motivo_assenza_cig,
                                siope_tipo_debito.siope_tipo_debito_desc impegno_tipo_debito,
                                coalesce(impegno_flag_prenotazione.boolean,'N') impegno_flag_prenotazione,
                                impegno_cig.testo  impegno_cig,
                                impegno_cup.testo  impegno_cup,
                                --11.05.2020 MR SIAC-7349 SR210
                                componente_desc.elem_det_comp_tipo_desc impegno_componente,
                                -- SIAC-8877 Paolo 17/05/2023
                                (case when cronoprogramma.movgest_ts_id is not null then cronoprogramma.programma_code else programma.programma_code end ) programma_code,
                                (case when cronoprogramma.movgest_ts_id is not null then cronoprogramma.cronop_code          else null end ) cronop_code
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
                              -- SIAC-8877 Paolo 17/05/2023
                              left outer join programma on (programma.movgest_ts_id=impegno.movgest_ts_id)
                              left outer join cronoprogramma on (cronoprogramma.movgest_ts_id=impegno.movgest_ts_id)
						) as zzz
					),
					zb as (
						select
							zzzz.elem_id,
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									b.elem_id, 
								    a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where
								    h.soggetto_classe_id=l.soggetto_classe_id
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null
							)
							select
								impegno.elem_id,
							    impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),

			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
                    --29.06.2018 Sofia jira siac-6193
                    n.attoamm_oggetto,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc,
					--SIAC-8188
					staa.attoal_causale
				from
					siac_r_movgest_ts_atto_amm m,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_t_atto_amm n
				--SIAC-8188 se ci sono corrisponsenze le ritorno
				left join siac_t_atto_allegato staa on n.attoamm_id = staa.attoamm_id 
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.elem_id,
			    imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
                -- 29.06.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				--SIAC-8188
				attoamm.attoal_causale,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc,
                -- 29.06.2018 Sofia jira siac-6193
                imp_sogg.impegno_nro_capitolo,
           		imp_sogg.impegno_nro_articolo,
           		imp_sogg.impegno_anno_capitolo,
                imp_sogg.impegno_flag_prenotazione,
                imp_sogg.impegno_cig,
                imp_sogg.impegno_cup,
                imp_sogg.impegno_motivo_assenza_cig,
                imp_sogg.impegno_tipo_debito,
                --11.05.2020 MR SIAC-7349 SR210
                imp_sogg.impegno_componente,
				-- SIAC-8877 Paolo 17/05/2023
				imp_sogg.programma_code,
				imp_sogg.cronop_code
			from imp_sogg

			 left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
            where (case when coalesce(_filtro_crp,'X')='R' then imp_sogg.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then imp_sogg.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then imp_sogg.movgest_anno>_anno::integer
		                else true end ) -- 29.06.2018 Sofia jira siac-6193
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
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		),
      --  	SIAC-8351 Haitham 05/11/2021
		sac_capitolo as (
			select
				class_cap.classif_code,
				class_cap.classif_desc,
				r_class_cap.elem_id
			from
				siac_r_bil_elem_class r_class_cap,
				siac_t_class class_cap,
				siac_d_class_tipo tipo_class_cap
			where r_class_cap.classif_id=class_cap.classif_id
			and tipo_class_cap.classif_tipo_id=class_cap.classif_tipo_id
			and now() BETWEEN r_class_cap.validita_inizio and coalesce (r_class_cap.validita_fine,now())
			and tipo_class_cap.classif_tipo_code  IN ('CDC', 'CDR')
			and r_class_cap.data_cancellazione is NULL
			and tipo_class_cap.data_cancellazione is NULL
			and class_cap.data_cancellazione is NULL
		),	
      --  	SIAC-8351 Haitham 05/11/2021
        sac_impegno as (
		
			select
				class_imp.classif_code,
				class_imp.classif_desc,
				mov.movgest_id 
			from
				siac_r_movgest_class  r_class_imp,
				siac_t_class class_imp,
				siac_d_class_tipo tipo_class_imp,
				siac_t_movgest mov,
				siac_t_movgest_ts ts
			where r_class_imp.classif_id=class_imp.classif_id
			and tipo_class_imp.classif_tipo_id=class_imp.classif_tipo_id
			and now() BETWEEN r_class_imp.validita_inizio and coalesce (r_class_imp.validita_fine,now())
			and tipo_class_imp.classif_tipo_code  IN ('CDC', 'CDR')
			and ts.movgest_ts_id  = r_class_imp.movgest_ts_id 
			and mov.movgest_id = ts.movgest_id 
			and r_class_imp.data_cancellazione is NULL
			and tipo_class_imp.data_cancellazione is NULL
			and class_imp.data_cancellazione is null
			-- 25.02.2022 Sofia Jira SIAC-8648
			and now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
			and ts.data_cancellazione is null
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.attoamm_oggetto attoamm_oggetto, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
            imp_sogg_attoamm.attoal_causale attoal_causale, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.impegno_anno_capitolo,
            imp_sogg_attoamm.impegno_nro_capitolo,
            imp_sogg_attoamm.impegno_nro_articolo,
            imp_sogg_attoamm.impegno_flag_prenotazione::varchar,
			imp_sogg_attoamm.impegno_cup,
            imp_sogg_attoamm.impegno_cig,
            imp_sogg_attoamm.impegno_tipo_debito,
            imp_sogg_attoamm.impegno_motivo_assenza_cig,
            --11.05.2020 SIAC-7349 MR SR210
            imp_sogg_attoamm.impegno_componente,
   			sac_capitolo.classif_code as cap_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_capitolo.classif_desc as cap_sac_desc,        --  	SIAC-8351 Haitham 05/11/2021
   			sac_impegno.classif_code as imp_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_impegno.classif_desc as imp_sac_desc,        --  	SIAC-8351 Haitham 05/11/2021
			imp_sogg_attoamm.programma_code as programma,			--		SIAC-8877 Paolo 17/05/2023
			imp_sogg_attoamm.cronop_code as cronoprogramma	--		SIAC-8877 Paolo 17/05/2023
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		left outer join sac_capitolo on imp_sogg_attoamm.elem_id=sac_capitolo.elem_id
		left outer join sac_impegno on imp_sogg_attoamm.uid=sac_impegno.movgest_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero


		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer)
    OWNER TO siac;





-- INIZIO 1.create_siac_s_azione_richiesta.sql



\echo 1.create_siac_s_azione_richiesta.sql



create table if not exists siac_s_azione_richiesta
as select azione_richiesta_id::int4,
attivita_id,
da_cruscotto,
data,
azione_id,
account_id,
ente_proprietario_id,
validita_inizio,
validita_fine,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione
from siac_t_azione_richiesta 
where data_creazione < '2023-01-01';


create table if not exists siac_s_parametro_azione_richiesta
as select parametro_id::int4,
azione_richiesta_id,
nome,
valore,
ente_proprietario_id,
validita_inizio,
validita_fine,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione
from siac_t_parametro_azione_richiesta 
where data_creazione < '2023-01-01';


delete from siac_t_parametro_azione_richiesta 
	where data_creazione < '2023-01-01';

delete from siac_t_azione_richiesta 
where data_creazione < '2023-01-01';




-- INIZIO 2.fnc_dba_azione_richiesta_clean.sql



\echo 2.fnc_dba_azione_richiesta_clean.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_dba_azione_richiesta_clean (VARCHAR);
--SIAC-8793
CREATE OR REPLACE FUNCTION siac.fnc_dba_azione_richiesta_clean (
  p_clean_interval VARCHAR = NULL
)
RETURNS TABLE (
  esito VARCHAR,
  deleted_params BIGINT,
  deleted_rows BIGINT
) AS
$body$
DECLARE

BEGIN
	esito := 'ko';
	deleted_params := 0;
	deleted_rows := 0;

	IF p_clean_interval IS NULL THEN
		RETURN;
	END IF;

	-- task-112 integriamo nella function il salvataggio nello 'storico'. Seguira' richiamo da job
	-- p_clean_interval da job: '3 months' ?
	insert into  siac_s_azione_richiesta
	select * from siac_t_azione_richiesta
	where data_creazione < now() - p_clean_interval::interval;

	insert into  siac_s_parametro_azione_richiesta
	select * from siac_t_parametro_azione_richiesta p
	where p.azione_richiesta_id in (select a.azione_richiesta_id from siac_t_azione_richiesta a
	where a.data_creazione < now() -p_clean_interval::interval);


	DELETE FROM siac_t_parametro_azione_richiesta WHERE data_creazione < now() - p_clean_interval::INTERVAL;
	GET DIAGNOSTICS deleted_params = ROW_COUNT;
	
	DELETE FROM siac_t_azione_richiesta WHERE data_creazione < now() - p_clean_interval::INTERVAL;
	GET DIAGNOSTICS deleted_rows = ROW_COUNT;

	esito := 'ok';
	RETURN NEXT;
	
	EXCEPTION
	WHEN no_data_found THEN
		RAISE NOTICE 'nessun dato trovato';
	WHEN others THEN
		RAISE NOTICE 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
	RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1;





