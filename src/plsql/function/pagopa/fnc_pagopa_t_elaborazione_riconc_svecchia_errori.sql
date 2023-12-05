/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
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

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out svecchiaPagoPaElabId        integer,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
	codResult integer:=null;
    countDel  integer:=null;

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

    SVECCHIA_CODE_PUNTUALE CONSTANT  varchar :='PUNTUALE';

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

BEGIN
	strMessaggioFinale:='Elaborazione svecchiamento puntuale rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggioFinale;
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
    select tipo.pagopa_elab_svecchia_tipo_fl_attivo, tipo.pagopa_elab_svecchia_tipo_fl_back
    into   pagopaElabSvecchiaTipoflagAttivo,pagopaElabSvecchiaTipoflagBack
	from pagopa_d_elaborazione_svecchia_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pagopa_elab_svecchia_tipo_code=SVECCHIA_CODE_PUNTUALE;
    if pagopaElabSvecchiaTipoflagAttivo is null or pagopaElabSvecchiaTipoflagBack is null then
    	codiceRisultato:=-1;
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
    end if;

    if pagopaElabSvecchiaTipoflagAttivo=false then
    	messaggioRisultato:=strMessaggio||' Tipo svecchiamento non attivo.'||strMessaggioFinale;
        return;
    end if;


    strMessaggio:='Verifica esistenza dati da svecchiare.';
    -- elaborazione deve essere ELABORATO_KO, ELABORATO_ERRATO, ELABORATO_SCARTATO
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
    and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null;
    raise notice 'strMessaggio  %',strMessaggio;
    raise notice 'codResult %',codResult;
    if codResult is null then
    	messaggioRisultato:=strMessaggio||' Dati non presenti.'||strMessaggioFinale;
        return;
    end if;


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
       'INIZIO '||tipo.pagopa_elab_svecchia_tipo_desc||'. ELAB. ID='||filePagoPaElabId::varchar||'.',
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

    -- se elaborazione_KO  o ERRATO, SCARTATO
    -- ricercare pagopa_t_riconciliazione_doc in N,X
	-- quindi cercare per lo stesso pagopa_t_riconciliazione
	-- precedenti elaborazioni in errore ( stesse condizioni )
	-- se trovate procedere con la cancellazione dei dati di elaborazione
	-- sino  a cancellare tutti i dati coinvolti in elaborazione se non esiste altro sotto
    strMessaggio:='Apertura cursore dati di riconciliazione da cancellare.';

    strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio||' '||strMessaggioFinale;
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
    countDel:=0;
    for pagoPaRec in
    (
	 select flusso.pagopa_elab_id,doc.*
	 from  pagopa_t_elaborazione_flusso flusso,
           pagopa_t_riconciliazione_doc doc
	 where flusso.pagopa_elab_id<filePagoPaElabId
     --and   flusso.pagopa_elab_id>=235
	 and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_stato_elab !='S'
	 and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
     and   exists
     (
     	 select 1
		 from  pagopa_t_elaborazione_flusso flusso_cur,
               pagopa_t_riconciliazione_doc doc_cur
   	     where flusso_cur.pagopa_elab_id=filePagoPaElabId
	 	 and   doc_cur.pagopa_elab_flusso_id=flusso_cur.pagopa_elab_flusso_id
		 and   doc_cur.pagopa_ric_doc_stato_elab !='S'
         and   doc_cur.pagopa_ric_id=doc.pagopa_ric_id
		 and   ( doc_cur.pagopa_ric_doc_flag_con_dett=false  or doc_cur.pagopa_ric_doc_flag_dett=true)
		 and   doc_cur.data_cancellazione is null
		 and   flusso_cur.data_cancellazione is null
     )
     and   flusso.pagopa_elab_id>=
     (
      select distinct elab_prec.pagopa_elab_id
      from  pagopa_t_elaborazione elab_prec, pagopa_d_elaborazione_stato stato_prec,
      pagopa_t_elaborazione_flusso flusso_prec, pagopa_t_riconciliazione_doc doc_prec
      where doc_prec.pagopa_ric_id=doc.pagopa_ric_id
      and   (doc_prec.pagopa_ric_doc_flag_con_dett=false  or doc_prec.pagopa_ric_doc_flag_dett=true)
      and   doc_prec.pagopa_ric_doc_stato_elab !='S'
      and   flusso_prec.pagopa_elab_flusso_id=doc_prec.pagopa_elab_flusso_id
      and   elab_prec.pagopa_elab_id=flusso_prec.pagopa_elab_id
      and   stato_prec.pagopa_elab_stato_id=elab_prec.pagopa_elab_stato_id
      and   stato_prec.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
      and   stato_prec.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
      and   elab_prec.pagopa_elab_id<filePagoPaElabId
      and   doc_prec.data_cancellazione is null
      and   flusso_prec.data_cancellazione is null
      and   elab_prec.data_cancellazione is null
      order by elab_prec.pagopa_elab_id desc
      limit 1
     )
	 and   doc.data_cancellazione is null
	 and   flusso.data_cancellazione is null
	 order by flusso.pagopa_elab_id, doc.pagopa_ric_id
    )
    loop

      -- delete
      -- pagopa_t_riconciliazione_doc
      -- x pagopa_ric_doc_id
      raise notice '@@@@@@@@ pagoPaRec.pagopa_elab_id=%',pagoPaRec.pagopa_elab_id;
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
          clock_timestamp(),
          loginOperazione,
          del.ente_proprietario_id
        from pagopa_t_riconciliazione_doc del
        where del.pagopa_ric_doc_id=pagoPaRec.pagopa_ric_doc_id
        returning pagopa_bck_ric_doc_id into codResult;
        if codResult is null then codResult:=0; end if;
        raise notice 'inseriti=%',codResult;

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
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

	  strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc.';
      raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc - ';
      codResult:=0;
      delete from pagopa_t_riconciliazione_doc del
      where del.pagopa_ric_doc_id=pagoPaRec.pagopa_ric_doc_id;
      GET DIAGNOSTICS codResult = ROW_COUNT;
      if codResult is null then codResult:=0; end if;
      raise notice 'pagoPaRec.pagopa_ric_doc_id=%',pagoPaRec.pagopa_ric_doc_id;
      raise notice 'pagoPaRec.pagopa_ric_id=%',pagoPaRec.pagopa_ric_id;
      raise notice 'cancellati=%',codResult;
      countDel:=countDel+codResult;

      strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     ||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
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

      -- x pagopa_ric_id and pagopa_ric_doc_flag_con_dett=true
      strMessaggio:='Verifica esistenza pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true.';
      raise notice 'strMessaggio= verifica esistenza pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true - ';
      codResult:=0;
      select coalesce(count(*),0) into codResult
      from pagopa_t_riconciliazione_doc del
      where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
      and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
      and   del.pagopa_ric_doc_flag_con_dett=true;
      raise notice 'esistenti=%',codResult;
      if codResult!=0 then
        codResult:=0;
        select coalesce(count(*),0) into codResult
        from pagopa_t_riconciliazione_doc del
        where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
        and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
        and   del.pagopa_ric_doc_flag_dett=true
        and   del.pagopa_ric_doc_id!=pagoPaRec.pagopa_ric_doc_id;
        if codResult=0 then
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
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_t_riconciliazione_doc del
            where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
          	and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
	        and   del.pagopa_ric_doc_flag_con_dett=true
            returning pagopa_bck_ric_doc_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
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


          strMessaggio:='Cancellazione pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true.';
          raise notice 'strMessaggio= cancellazione pagopa_t_riconciliazione_doc - pagopa_ric_doc_flag_con_dett=true - ';
          delete from pagopa_t_riconciliazione_doc del
          where del.pagopa_ric_id=pagoPaRec.pagopa_ric_id
          and   del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
          and   del.pagopa_ric_doc_flag_con_dett=true;
          GET DIAGNOSTICS codResult = ROW_COUNT;
          if codResult is null then codResult:=0; end if;
          raise notice 'cancellati=%',codResult;
          countDel:=countDel+codResult;

          strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     ||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
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
      end if;





	  -- delete
      -- pagopa_t_elaborazione_flusso
      strMessaggio:='Verifica esistenza diversi dati di riconciliazione per lo stesso flusso-elaborazione-file [pagopa_t_elaborazione_flusso].';
      raise notice 'strMessaggio=%',strMessaggio;
      codResult:=0;
      select coalesce(count(*),0)  into codResult
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id;
--      and   doc.pagopa_ric_id!=pagoPaRec.pagopa_ric_id;
      raise notice 'pagoPaRec.pagopa_elab_flusso_id=%',pagoPaRec.pagopa_elab_flusso_id;
      raise notice 'esistenti=%',codResult;
      if codresult=0 then
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
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_t_elaborazione_flusso del
            where del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id
            returning pagopa_bck_elab_flusso_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
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

      	-- delete  pagopa_t_elaborazione_flusso
        strMessaggio:='Cancellazione pagopa_t_elaborazione_flusso.';
        raise notice 'strMessaggio= cancellazione pagopa_t_elaborazione_flusso - ';
        codResult:=0;
        delete from pagopa_t_elaborazione_flusso del where del.pagopa_elab_flusso_id=pagoPaRec.pagopa_elab_flusso_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if codResult is null then codResult:=0; end if;
      	raise notice 'cancellati=%',codResult;

      	strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                     	||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
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

        strMessaggio:='Verifica esistenza diversi flussi per elaborazione-file [pagopa_r_elaborazione_file].';
        raise notice 'strMessaggio=%',strMessaggio;
        -- delete
        -- pagopa_r_elaborazione_file
        codResult:=0;
        select coalesce(count(*),0)  into codResult
        from pagopa_t_elaborazione_flusso flusso,pagopa_r_elaborazione_file rfile,
             pagopa_t_riconciliazione_doc doc,pagopa_t_riconciliazione ric
        where flusso.pagopa_elab_id=pagoPaRec.pagopa_elab_id
        and   flusso.pagopa_elab_flusso_id!=pagoPaRec.pagopa_elab_flusso_id
        and   rfile.pagopa_elab_id=flusso.pagopa_elab_id
        and   rfile.file_pagopa_id=pagoPaRec.file_pagopa_id
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   ric.pagopa_ric_id=doc.pagopa_ric_id
        and   ric.file_pagopa_id=rfile.file_pagopa_id;
        raise notice 'esistenti=%',codResult;
        if codResult=0 then
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
              del.pagopa_r_elab_id,
              del.pagopa_elab_id,
              del.file_pagopa_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_r_elaborazione_file del
            where del.file_pagopa_id=pagoPaRec.file_pagopa_id
            and   del.pagopa_elab_id=pagoPaRec.pagopa_elab_id
            returning pagopa_bck_r_elab_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
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

          strMessaggio:='Cancellazione pagopa_r_elaborazione_file.';
          raise notice 'strMessaggio= cancellazione pagopa_r_elaborazione_file - ';
          -- delete pagopa_r_elaborazione_file
          delete from pagopa_r_elaborazione_file del
          where del.file_pagopa_id=pagoPaRec.file_pagopa_id
          and   del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
          GET DIAGNOSTICS codResult = ROW_COUNT;
          if codResult is null then codResult:=0; end if;
          raise notice 'cancellati=%',codResult;

          strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                         ||' Cancellati '||codResult::varchar||'. '||strMessaggioFinale;
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

      end if;

      -- delete
	  -- pagopa_t_elaborazione
      strMessaggio:='Verifica esistenza relazioni con altri file per elaborazione [pagopa_r_elaborazione_file].';
      raise notice 'strMessaggio=%',strMessaggio;
      codResult:=0;
      select coalesce(count(*),0) into codResult
      from pagopa_t_elaborazione  elab,pagopa_r_elaborazione_file r
      where elab.pagopa_elab_id=pagoPaRec.pagopa_elab_id
      and   r.pagopa_elab_id=elab.pagopa_elab_id;
      raise notice 'esistenti=%',codResult;
      if codResult = 0 then
        strMessaggio:='Verifica esistenza relazioni con altri flussi per elaborazione [pagopa_t_elaborazione_flusso].';
	    raise notice 'strMessaggio=%',strMessaggio;
        codResult:=0;
        select coalesce(count(*),0) into codResult
        from pagopa_t_elaborazione  elab,pagopa_t_elaborazione_flusso flusso
        where elab.pagopa_elab_id=pagoPaRec.pagopa_elab_id
        and   flusso.pagopa_elab_id=pagoPaRec.pagopa_elab_id
        and   flusso.pagopa_elab_flusso_id!=pagoPaRec.pagopa_elab_flusso_id;
        raise notice 'esistenti=%',codResult;

      end if;


      -- posso cancellare pagopa_t_elaborazione
      if codResult = 0 then

        strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
        ||strMessaggio
        ||' Inizio cancellazione pagopa_t_elaborazione. '
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
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;


		-- pagopa_bck_t_subdoc
    	strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_subdoc_attr
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_attr';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_attr del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_subdoc_atto_amm
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_atto_amm';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_atto_amm del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_subdoc_prov_cassa
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_prov_cassa';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_prov_cassa del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_subdoc_movgest_ts
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_movgest_ts';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_movgest_ts del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc_stato
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_stato';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_stato del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_subdoc_num
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_subdoc_num';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_subdoc_num del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc_sog
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_sog';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_sog del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

    	-- pagopa_bck_t_doc_attr
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_attr';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_attr del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

	    -- pagopa_bck_t_doc_class
        strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_doc_class';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_doc_class del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

        -- pagopa_bck_t_registrounico_doc
		strMessaggio:='Cancellazione dati elaborazione - pagopa_bck_t_registrounico_doc';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_bck_t_registrounico_doc del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

        -- delete pagopa_t_elaborazione_log
        strMessaggio:='Cancellazione dati elaborazione - pagopa_t_elaborazione_log';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_t_elaborazione_log del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

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
              del.pagopa_elab_id,
              del.pagopa_elab_data,
              del.pagopa_elab_stato_id,
              del.pagopa_elab_note,
              del.pagopa_elab_file_id,
              del.pagopa_elab_file_ora,
              del.pagopa_elab_file_ente,
              del.pagopa_elab_file_fruitore,
              del.file_pagopa_id,
              del.pagopa_elab_errore_id,
              del.validita_inizio,
              del.validita_fine,
              del.data_creazione,
              del.data_modifica,
              del.data_cancellazione,
              del.login_operazione,
              clock_timestamp(),
              loginOperazione,
              del.ente_proprietario_id
            from pagopa_t_elaborazione del
            where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id
            returning pagopa_bck_elab_id into codResult;
            if codResult is null then codResult:=0; end if;
            raise notice 'inseriti=%',codResult;

            strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
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

       	-- delete pagopa_t_elaborazione
        strMessaggio:='Cancellazione dati elaborazione - pagopa_t_elaborazione';
        raise notice '%',strMessaggio;
        codResult:=0;
        delete from pagopa_t_elaborazione del where del.pagopa_elab_id=pagoPaRec.pagopa_elab_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'cancellati=%',codResult;

 		strMessaggioLog:='Continua fnc_pagopa_t_elaborazione_riconc_svecchia_err - '||strMessaggio
                          ||' Fine cancellazione pagopa_t_elaborazione. '||strMessaggioFinale;
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

    end loop;



    codResult:=null;
    strMessaggio:='Fine fnc_pagopa_t_elaborazione_riconc_svecchia_err - '
                  ||' cancellati complessivamente '||coalesce(countDel,0)::varchar
                  ||'  pagopa_t_riconciliazione_doc. Chiusura elaborazione [pagopa_t_elaborazione_svecchia].';
    raise notice 'strMessaggio=%',strMessaggio;
    update pagopa_t_elaborazione_svecchia elab
    set    data_modifica=clock_timestamp(),
           validita_fine=clock_timestamp(),
           pagopa_elab_svecchia_note=
           upper('FINE '||tipo.pagopa_elab_svecchia_tipo_desc||'. ELAB. ID='||filePagoPaElabId::varchar
           ||' Cancellati complessivamente '||coalesce(countDel,0)::varchar||' pagopa_t_riconciliazione_doc.')
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
        ||' CANCELLATI COMPLESSIVAMENTE '||countDel::varchar||' pagopa_t_riconciliazione_doc.'
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


alter function if exists siac.fnc_pagopa_t_elaborazione_riconc_svecchia_err
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