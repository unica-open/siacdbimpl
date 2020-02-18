/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):='';
	strMessaggioBck VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';
	strMessaggioFinale VARCHAR(2500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(10):='';
	codResult integer:=null;


	PagoPaRecClean record;
    AggRec record;

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA


begin

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' Pulizia documenti creati per provvisori in errore-non completi.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale;
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
--	raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    codiceRisultato:=0;
    messaggioRisultato:='';
    pagopaBckSubdoc:=false;

    strMessaggio:='Inizio ciclo su pagopa_t_riconciliazione_doc.';
  --        raise notice 'strMessaggio=%',strMessaggio;

    for PagoPaRecClean in
    (
     select doc.pagopa_ric_doc_provc_id pagopa_provc_id,
            flusso.pagopa_elab_flusso_anno_esercizio pagopa_anno_esercizio,
            flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
            flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio
     from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_subdoc_id is not null
	 and   doc.pagopa_ric_doc_stato_elab='S'
	 and   exists
	 (
      select 1
	  from  pagopa_t_elaborazione_flusso flusso1, pagopa_t_riconciliazione_doc doc1,
            pagopa_t_riconciliazione ric1
	  where flusso1.pagopa_elab_id=flusso.pagopa_elab_id
	  and   flusso1.pagopa_elab_flusso_anno_esercizio=flusso.pagopa_elab_flusso_anno_esercizio
	  and   flusso1.pagopa_elab_flusso_anno_provvisorio=flusso.pagopa_elab_flusso_anno_provvisorio
	  and   flusso1.pagopa_elab_flusso_num_provvisorio=flusso.pagopa_elab_flusso_num_provvisorio
	  and   doc1.pagopa_elab_flusso_id=flusso1.pagopa_elab_flusso_id
      and   ric1.pagopa_ric_id=doc1.pagopa_ric_id
	  and   doc1.pagopa_ric_doc_subdoc_id is null
      -- 07.06.2019 SIAC-6720
	  and   ((doc1.pagopa_ric_doc_stato_elab!='S' and doc1.pagopa_ric_doc_flag_con_dett=false ) or
              ric1.pagopa_ric_flusso_stato_elab!='S'
            )
	  and   flusso1.data_cancellazione is null
	  and   flusso1.validita_fine is null
	  and   doc1.data_cancellazione is null
	  and   doc1.validita_fine is null
      and   ric1.data_cancellazione is null
      and   ric1.validita_fine is null

	 ) -- per provvisorio scarti,non elaborati o errori
     and flusso.data_cancellazione is null
	 and flusso.validita_fine is null
	 and doc.data_cancellazione is null
	 and doc.validita_fine is null
	 order by 2,3,4
	)
    loop

	  codResult:=null;
      -- tabelle backup
      -- pagopa_bck_t_subdoc
      --  raise notice '@@@@@@@@@@@@@@@@@@@@ strMessaggio=%',strMessaggio;
      strMessaggio:='In ciclo su pagopa_t_riconciliazione_doc. Per provvisorio di cassa Prov. '
                  ||PagoPaRecClean.pagopa_anno_provvisorio::varchar||'/'||PagoPaRecClean.pagopa_num_provvisorio::varchar
                  ||' provcId='||PagoPaRecClean.pagopa_provc_id::varchar||'.';
      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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

      strMessaggioBck:=strMessaggio;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc.';
      insert into pagopa_bck_t_subdoc
      (
        pagopa_provc_id,
        pagopa_elab_id,
        subdoc_id,
        subdoc_numero,
        subdoc_desc,
        subdoc_importo,
        subdoc_nreg_iva,
        subdoc_data_scadenza,
        subdoc_convalida_manuale,
        subdoc_importo_da_dedurre,
        subdoc_splitreverse_importo,
        subdoc_pagato_cec,
        subdoc_data_pagamento_cec,
        contotes_id,
        dist_id,
        comm_tipo_id,
        doc_id,
        subdoc_tipo_id,
        notetes_id,
        bck_validita_inizio,
        bck_validita_fine,
        bck_data_creazione,
        bck_data_modifica,
        bck_data_cancellazione,
        bck_login_operazione,
        bck_login_creazione,
        bck_login_modifica,
        bck_login_cancellazione,
        siope_tipo_debito_id,
        siope_assenza_motivazione_id,
        siope_scadenza_motivo_id,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
      )
      select
        PagoPaRecClean.pagopa_provc_id,
        filePagoPaElabId,
        sub.subdoc_id,
        sub.subdoc_numero,
        sub.subdoc_desc,
        sub.subdoc_importo,
        sub.subdoc_nreg_iva,
        sub.subdoc_data_scadenza,
        sub.subdoc_convalida_manuale,
        sub.subdoc_importo_da_dedurre,
        sub.subdoc_splitreverse_importo,
        sub.subdoc_pagato_cec,
        sub.subdoc_data_pagamento_cec,
        sub.contotes_id,
        sub.dist_id,
        sub.comm_tipo_id,
        sub.doc_id,
        sub.subdoc_tipo_id,
        sub.notetes_id,
        sub.validita_inizio,
        sub.validita_fine,
        sub.data_creazione,
        sub.data_modifica,
        sub.data_cancellazione,
        sub.login_operazione,
        sub.login_creazione,
        sub.login_modifica,
        sub.login_cancellazione,
        sub.siope_tipo_debito_id,
        sub.siope_assenza_motivazione_id,
        sub.siope_scadenza_motivo_id,
        clock_timestamp(),
        sub.ente_proprietario_id,
        loginOperazione
      from siac_t_subdoc sub,siac_r_doc_stato rs, siac_d_doc_stato stato,
	   	   pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc ric
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   ric.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_doc_stato_elab='S'
      and   sub.subdoc_id=ric.pagopa_ric_doc_subdoc_id
      and   rs.doc_id=sub.doc_id
      and   stato.doc_stato_id=rs.doc_stato_id
      and   stato.doc_stato_code not in ('A','ST','EM')
      and   not exists
      (
        select 1
        from siac_r_subdoc_ordinativo_ts rsub
        where rsub.subdoc_id=sub.subdoc_id
        and   rsub.data_cancellazione is null
        and   rsub.validita_fine is null
      )
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      and   rs.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())));
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if pagopaBckSubdoc=false and coalesce(codResult,0) !=0 then
      	pagopaBckSubdoc:=true;
      end if;

	  -- pagopa_bck_t_subdoc_attr
      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_attr.';
      insert into pagopa_bck_t_subdoc_attr
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_attr_id,
          subdoc_id,
          attr_id,
          tabella_id,
          boolean,
          percentuale,
          testo,
          numerico,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_attr_id,
          r.subdoc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          r.ente_proprietario_id,
          loginOperazione
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_attr r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_atto_amm
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_atto_amm.';
      insert into pagopa_bck_t_subdoc_atto_amm
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_atto_amm_id,
          subdoc_id,
          attoamm_id,
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
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_atto_amm_id,
          r.subdoc_id,
          r.attoamm_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_atto_amm r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_prov_cassa
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_prov_cassa.';

      insert into pagopa_bck_t_subdoc_prov_cassa
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_provc_id,
          subdoc_id,
          provc_id,
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
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_provc_id,
          r.subdoc_id,
          r.provc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_prov_cassa r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_movgest_ts
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_movgest_ts.';

      insert into pagopa_bck_t_subdoc_movgest_ts
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_movgest_ts_id,
          subdoc_id,
          movgest_ts_id,
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
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_movgest_ts_id,
          r.subdoc_id,
          r.movgest_ts_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_movgest_ts r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc.';
      insert into pagopa_bck_t_doc
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_id,
          doc_anno,
          doc_numero,
          doc_desc,
          doc_importo,
          doc_beneficiariomult,
          doc_data_emissione,
          doc_data_scadenza,
          doc_tipo_id,
          codbollo_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          bck_login_creazione,
          bck_login_modifica,
          bck_login_cancellazione,
          pcccod_id,
          pccuff_id,
          doc_collegato_cec,
          doc_contabilizza_genpcc,
          siope_documento_tipo_id,
          siope_documento_tipo_analogico_id,
          doc_sdi_lotto_siope,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select distinct
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.doc_id,
          r.doc_anno,
          r.doc_numero,
          r.doc_desc,
          r.doc_importo,
          r.doc_beneficiariomult,
          r.doc_data_emissione,
          r.doc_data_scadenza,
          r.doc_tipo_id,
          r.codbollo_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          r.login_creazione,
          r.login_modifica,
          r.login_cancellazione,
          r.pcccod_id,
          r.pccuff_id,
          r.doc_collegato_cec,
          r.doc_contabilizza_genpcc,
          r.siope_documento_tipo_id,
          r.siope_documento_tipo_analogico_id,
          r.doc_sdi_lotto_siope,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_t_doc r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=sub.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_doc_stato
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_stato.';
      insert into pagopa_bck_t_doc_stato
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_stato_r_id,
          doc_id,
          doc_stato_id,
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
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_stato_r_id,
          r.doc_id,
          r.doc_stato_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_stato r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_subdoc_num
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_num.';
      insert into pagopa_bck_t_subdoc_num
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_num_id,
          doc_id,
          subdoc_numero,
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
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.subdoc_num_id,
          r.doc_id,
          r.subdoc_numero,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_subdoc_num r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


      -- pagopa_bck_t_doc_sog
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_sog.';
      insert into pagopa_bck_t_doc_sog
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_sog_id,
         doc_id,
         soggetto_id,
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
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_sog_id,
          r.doc_id,
          r.soggetto_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_sog r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_attr
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_attr.';

      insert into pagopa_bck_t_doc_attr
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_attr_id,
         doc_id,
         attr_id,
         tabella_id,
         boolean,
         percentuale,
         testo,
         numerico,
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
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_attr_id,
          r.doc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_attr r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_class
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_class.';

      insert into pagopa_bck_t_doc_class
      (
      	 pagopa_provc_id,
         pagopa_elab_id,
         doc_classif_id,
         doc_id,
         classif_id,
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
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_classif_id,
          r.doc_id,
          r.classif_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_class r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_registrounico_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_registrounico_doc.';

      insert into pagopa_bck_t_registrounico_doc
      (
         pagopa_provc_id,
         pagopa_elab_id,
         rudoc_id,
         rudoc_registrazione_anno,
         rudoc_registrazione_numero,
         rudoc_registrazione_data,
         doc_id,
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
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.rudoc_id,
          r.rudoc_registrazione_anno,
          r.rudoc_registrazione_numero,
          r.rudoc_registrazione_data,
          r.doc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_registrounico_doc r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


   	  -- aggiornare importo documenti collegati
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento importo documenti.';

      update siac_t_doc doc
      set    doc_importo=doc.doc_importo-coalesce(query.subdoc_importo,0),
             data_modifica=clock_timestamp(),
             login_operazione=doc.login_operazione||'-'||loginOperazione
      from
      (
      select sub.doc_id,coalesce(sum(sub.subdoc_importo),0) subdoc_importo
      from siac_t_subdoc sub, pagopa_bck_t_doc pagodoc, pagopa_bck_t_subdoc pagosubdoc
      where pagodoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc.pagopa_elab_id=filePagoPaElabId
      and   pagosubdoc.pagopa_provc_id=pagodoc.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=pagodoc.pagopa_elab_id
      and   pagosubdoc.doc_id=pagodoc.doc_id
      and   sub.subdoc_id=pagosubdoc.subdoc_id
      and   pagodoc.data_cancellazione is null
      and   pagodoc.validita_fine is null
      and   pagosubdoc.data_cancellazione is null
      and   pagosubdoc.validita_fine is null
      and   sub.data_cancellazione is null
      and   sub.validita_fine is null
      group by sub.doc_id
      ) query
      where doc.ente_proprietario_id=enteProprietarioId
      and   doc.doc_id=query.doc_id
      and   exists
      (
      select 1
      from pagopa_bck_t_doc pagodoc1, pagopa_bck_t_subdoc pagosubdoc1
      where pagodoc1.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc1.pagopa_elab_id=filePagoPaElabId
      and   pagodoc1.doc_id=doc.doc_id
      and   pagosubdoc1.pagopa_provc_id=pagodoc1.pagopa_provc_id
      and   pagosubdoc1.pagopa_elab_id=pagodoc1.pagopa_elab_id
      and   pagosubdoc1.doc_id=pagodoc1.doc_id
      and   pagodoc1.data_cancellazione is null
      and   pagodoc1.validita_fine is null
      and   pagosubdoc1.data_cancellazione is null
      and   pagosubdoc1.validita_fine is null
      )
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;


      -- cancellare quote documenti collegati
  	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_attr].';

      -- siac_r_subdoc_attr
      delete from siac_r_subdoc_attr r
      using pagopa_bck_t_subdoc_attr pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_attr_id=pagosubdoc.subdoc_attr_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
 --     and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_atto_amm].';
      -- siac_r_subdoc_atto_amm
      delete from siac_r_subdoc_atto_amm r
      using pagopa_bck_t_subdoc_atto_amm pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_atto_amm_id=pagosubdoc.subdoc_atto_amm_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_prov_cassa].';

      -- siac_r_subdoc_prov_cassa
      delete from siac_r_subdoc_prov_cassa r
      using pagopa_bck_t_subdoc_prov_cassa pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_provc_id=pagosubdoc.subdoc_provc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_movgest_ts].';

      -- siac_r_subdoc_movgest_ts
      delete from siac_r_subdoc_movgest_ts r
      using pagopa_bck_t_subdoc_movgest_ts pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_movgest_ts_id=pagosubdoc.subdoc_movgest_ts_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione-pulizia [pagopa_t_modifica_elab].';
      update pagopa_t_modifica_elab r
      set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN CLEAN PER pagoPaCodeErr='||PAGOPA_ERR_36||' ',
             subdoc_id=null
      from 	pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_t_subdoc].';

      -- siac_t_subdoc
      delete from siac_t_subdoc r
      using pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  -- cancellazione su documenti senza quote
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_sog].';

      -- siac_r_doc_sog

      delete from siac_r_doc_sog r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_sog pagopaDel
      where r.doc_sog_id=pagopaDel.doc_sog_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_stato].';

      -- siac_r_doc_stato
      delete from siac_r_doc_stato r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_stato pagopaDel
      where r.doc_stato_r_id=pagopaDel.doc_stato_r_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
--      and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_attr].';

      -- siac_r_doc_attr
      delete from siac_r_doc_attr r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_attr pagopaDel
      where r.doc_attr_id=pagopaDel.doc_attr_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_class].';

      -- siac_r_doc_class
      delete from siac_r_doc_class r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_class pagopaDel
      where r.doc_classif_id=pagopaDel.doc_classif_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_registrounico_doc].';

      -- siac_t_registrounico_doc
      delete from siac_t_registrounico_doc r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_registrounico_doc pagopaDel
      where r.rudoc_id=pagopaDel.rudoc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
   --   and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_subdoc_num].';

      -- siac_t_subdoc_num
      delete from siac_t_subdoc_num r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_subdoc_num pagopaDel
      where r.subdoc_num_id=pagopaDel.subdoc_num_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_doc].';

      -- siac_t_doc
      delete from siac_t_doc r
      using pagopa_bck_t_doc pagopaDel
      where r.doc_id=pagopaDel.doc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopaDel.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );


      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento stato documenti rimanenti in vita.';
      -- aggiornamento stato documenti per rimanenti in vita con quote
      -- esecuzione fnc per
      select
       fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
	   (
		pagopadoc.doc_id,
        filePagoPaElabId,
		enteProprietarioId,
		loginOperazione
		) into AggRec
	  from pagopa_bck_t_doc pagopadoc, pagopa_bck_t_subdoc pagopasub
      where pagopadoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopadoc.pagopa_elab_id=filePagoPaElabId
      and   pagopasub.pagopa_provc_id=pagopadoc.pagopa_provc_id
      and   pagopasub.pagopa_elab_id=pagopadoc.pagopa_elab_id
      and   pagopasub.doc_id=pagopadoc.doc_id
      and   pagopadoc.data_cancellazione is null
      and   pagopadoc.validita_fine is null
      and   pagopasub.data_cancellazione is null
      and   pagopasub.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - Fine cancellazione doc. - '||strMessaggioFinale;
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

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione.';

      -- aggiornare pagopa_t_riconciliazione
      update pagopa_t_riconciliazione ric
      set    pagopa_ric_flusso_stato_elab='X',
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_id=doc.pagopa_ric_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione_doc.';
      -- aggiornare pagopa_t_riconciliazione_doc
      update pagopa_t_riconciliazione_doc doc
      set    pagopa_ric_doc_stato_elab='X',
             pagopa_ric_doc_subdoc_id=null,
             pagopa_ric_doc_provc_id=null,
             pagopa_ric_doc_movgest_ts_id=null,
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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

  end loop;

  /* sostituito con diagnostic dopo insert tabella
  strMessaggio:=' Verifica esistenza in pagopa_bck_t_subdoc a termine aggiornamento.';
  select (case when count(*)!=0 then true else false end ) into pagopaBckSubdoc
  from pagopa_bck_t_subdoc bck
  where bck.pagopa_elab_id=filePagoPaElabId
  and   bck.data_cancellazione is null
  and   bck.validita_fine is null;*/



  messaggioRisultato:='OK - '||upper(strMessaggioFinale);

  strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||messaggioRisultato;
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

  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100; l l a z i o n e , 
 
                     r . l o g i n _ o p e r a z i o n e , 
 
                     c l o c k _ t i m e s t a m p ( ) , 
 
                     l o g i n O p e r a z i o n e , 
 
                     r . e n t e _ p r o p r i e t a r i o _ i d 
 
             f r o m   p a g o p a _ b c k _ t _ d o c   d o c ,   s i a c _ r _ d o c _ a t t r   r 
 
             w h e r e   d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       r . d o c _ i d = d o c . d o c _ i d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       n o w ( ) > = d a t e _ t r u n c ( ' D A Y ' , r . v a l i d i t a _ i n i z i o )   a n d   n o w < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r . v a l i d i t a _ f i n e , n o w ( ) ) ) ; 
 
 
 
 	     - -   p a g o p a _ b c k _ t _ d o c _ c l a s s 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i m e n t o   p a g o p a _ b c k _ t _ d o c _ c l a s s . ' ; 
 
 
 
             i n s e r t   i n t o   p a g o p a _ b c k _ t _ d o c _ c l a s s 
 
             ( 
 
             	   p a g o p a _ p r o v c _ i d , 
 
                   p a g o p a _ e l a b _ i d , 
 
                   d o c _ c l a s s i f _ i d , 
 
                   d o c _ i d , 
 
                   c l a s s i f _ i d , 
 
                   b c k _ v a l i d i t a _ i n i z i o , 
 
                   b c k _ v a l i d i t a _ f i n e , 
 
                   b c k _ d a t a _ c r e a z i o n e , 
 
                   b c k _ d a t a _ m o d i f i c a , 
 
                   b c k _ d a t a _ c a n c e l l a z i o n e , 
 
                   b c k _ l o g i n _ o p e r a z i o n e , 
 
                   v a l i d i t a _ i n i z i o , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d 
 
             ) 
 
             s e l e c t 
 
                     d o c . p a g o p a _ p r o v c _ i d , 
 
                     d o c . p a g o p a _ e l a b _ i d , 
 
                     r . d o c _ c l a s s i f _ i d , 
 
                     r . d o c _ i d , 
 
                     r . c l a s s i f _ i d , 
 
                     r . v a l i d i t a _ i n i z i o , 
 
                     r . v a l i d i t a _ f i n e , 
 
                     r . d a t a _ c r e a z i o n e , 
 
                     r . d a t a _ m o d i f i c a , 
 
                     r . d a t a _ c a n c e l l a z i o n e , 
 
                     r . l o g i n _ o p e r a z i o n e , 
 
                     c l o c k _ t i m e s t a m p ( ) , 
 
                     l o g i n O p e r a z i o n e , 
 
                     r . e n t e _ p r o p r i e t a r i o _ i d 
 
             f r o m   p a g o p a _ b c k _ t _ d o c   d o c ,   s i a c _ r _ d o c _ c l a s s   r 
 
             w h e r e   d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d 	 d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       r . d o c _ i d = d o c . d o c _ i d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       n o w ( ) > = d a t e _ t r u n c ( ' D A Y ' , r . v a l i d i t a _ i n i z i o )   a n d   n o w < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r . v a l i d i t a _ f i n e , n o w ( ) ) ) ; 
 
 
 
 	     - -   p a g o p a _ b c k _ t _ r e g i s t r o u n i c o _ d o c 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i m e n t o   p a g o p a _ b c k _ t _ r e g i s t r o u n i c o _ d o c . ' ; 
 
 
 
             i n s e r t   i n t o   p a g o p a _ b c k _ t _ r e g i s t r o u n i c o _ d o c 
 
             ( 
 
                   p a g o p a _ p r o v c _ i d , 
 
                   p a g o p a _ e l a b _ i d , 
 
                   r u d o c _ i d , 
 
                   r u d o c _ r e g i s t r a z i o n e _ a n n o , 
 
                   r u d o c _ r e g i s t r a z i o n e _ n u m e r o , 
 
                   r u d o c _ r e g i s t r a z i o n e _ d a t a , 
 
                   d o c _ i d , 
 
                   b c k _ v a l i d i t a _ i n i z i o , 
 
                   b c k _ v a l i d i t a _ f i n e , 
 
                   b c k _ d a t a _ c r e a z i o n e , 
 
                   b c k _ d a t a _ m o d i f i c a , 
 
                   b c k _ d a t a _ c a n c e l l a z i o n e , 
 
                   b c k _ l o g i n _ o p e r a z i o n e , 
 
                   v a l i d i t a _ i n i z i o , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d 
 
             ) 
 
             s e l e c t 
 
                     d o c . p a g o p a _ p r o v c _ i d , 
 
                     d o c . p a g o p a _ e l a b _ i d , 
 
                     r . r u d o c _ i d , 
 
                     r . r u d o c _ r e g i s t r a z i o n e _ a n n o , 
 
                     r . r u d o c _ r e g i s t r a z i o n e _ n u m e r o , 
 
                     r . r u d o c _ r e g i s t r a z i o n e _ d a t a , 
 
                     r . d o c _ i d , 
 
                     r . v a l i d i t a _ i n i z i o , 
 
                     r . v a l i d i t a _ f i n e , 
 
                     r . d a t a _ c r e a z i o n e , 
 
                     r . d a t a _ m o d i f i c a , 
 
                     r . d a t a _ c a n c e l l a z i o n e , 
 
                     r . l o g i n _ o p e r a z i o n e , 
 
                     c l o c k _ t i m e s t a m p ( ) , 
 
                     l o g i n O p e r a z i o n e , 
 
                     r . e n t e _ p r o p r i e t a r i o _ i d 
 
             f r o m   p a g o p a _ b c k _ t _ d o c   d o c ,   s i a c _ t _ r e g i s t r o u n i c o _ d o c   r 
 
             w h e r e   d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d 	 d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       r . d o c _ i d = d o c . d o c _ i d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       n o w ( ) > = d a t e _ t r u n c ( ' D A Y ' , r . v a l i d i t a _ i n i z i o )   a n d   n o w < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r . v a l i d i t a _ f i n e , n o w ( ) ) ) ; 
 
 
 
 
 
       	     - -   a g g i o r n a r e   i m p o r t o   d o c u m e n t i   c o l l e g a t i 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A g g i o r n a m e n t o   i m p o r t o   d o c u m e n t i . ' ; 
 
 
 
             u p d a t e   s i a c _ t _ d o c   d o c 
 
             s e t         d o c _ i m p o r t o = d o c . d o c _ i m p o r t o - c o a l e s c e ( q u e r y . s u b d o c _ i m p o r t o , 0 ) , 
 
                           d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                           l o g i n _ o p e r a z i o n e = d o c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
             f r o m 
 
             ( 
 
             s e l e c t   s u b . d o c _ i d , c o a l e s c e ( s u m ( s u b . s u b d o c _ i m p o r t o ) , 0 )   s u b d o c _ i m p o r t o 
 
             f r o m   s i a c _ t _ s u b d o c   s u b ,   p a g o p a _ b c k _ t _ d o c   p a g o d o c ,   p a g o p a _ b c k _ t _ s u b d o c   p a g o s u b d o c 
 
             w h e r e   p a g o d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = p a g o d o c . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = p a g o d o c . p a g o p a _ e l a b _ i d 
 
             a n d       p a g o s u b d o c . d o c _ i d = p a g o d o c . d o c _ i d 
 
             a n d       s u b . s u b d o c _ i d = p a g o s u b d o c . s u b d o c _ i d 
 
             a n d       p a g o d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p a g o d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       p a g o s u b d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p a g o s u b d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             g r o u p   b y   s u b . d o c _ i d 
 
             )   q u e r y 
 
             w h e r e   d o c . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       d o c . d o c _ i d = q u e r y . d o c _ i d 
 
             a n d       e x i s t s 
 
             ( 
 
             s e l e c t   1 
 
             f r o m   p a g o p a _ b c k _ t _ d o c   p a g o d o c 1 ,   p a g o p a _ b c k _ t _ s u b d o c   p a g o s u b d o c 1 
 
             w h e r e   p a g o d o c 1 . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o d o c 1 . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o d o c 1 . d o c _ i d = d o c . d o c _ i d 
 
             a n d       p a g o s u b d o c 1 . p a g o p a _ p r o v c _ i d = p a g o d o c 1 . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c 1 . p a g o p a _ e l a b _ i d = p a g o d o c 1 . p a g o p a _ e l a b _ i d 
 
             a n d       p a g o s u b d o c 1 . d o c _ i d = p a g o d o c 1 . d o c _ i d 
 
             a n d       p a g o d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p a g o d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       p a g o s u b d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p a g o s u b d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
             - -   c a n c e l l a r e   q u o t e   d o c u m e n t i   c o l l e g a t i 
 
     	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   [ s i a c _ r _ s u b d o c _ a t t r ] . ' ; 
 
 
 
             - -   s i a c _ r _ s u b d o c _ a t t r 
 
             d e l e t e   f r o m   s i a c _ r _ s u b d o c _ a t t r   r 
 
             u s i n g   p a g o p a _ b c k _ t _ s u b d o c _ a t t r   p a g o s u b d o c 
 
             w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r . s u b d o c _ a t t r _ i d = p a g o s u b d o c . s u b d o c _ a t t r _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d ; 
 
   - -           a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   [ s i a c _ r _ s u b d o c _ a t t o _ a m m ] . ' ; 
 
             - -   s i a c _ r _ s u b d o c _ a t t o _ a m m 
 
             d e l e t e   f r o m   s i a c _ r _ s u b d o c _ a t t o _ a m m   r 
 
             u s i n g   p a g o p a _ b c k _ t _ s u b d o c _ a t t o _ a m m   p a g o s u b d o c 
 
             w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r . s u b d o c _ a t t o _ a m m _ i d = p a g o s u b d o c . s u b d o c _ a t t o _ a m m _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   [ s i a c _ r _ s u b d o c _ p r o v _ c a s s a ] . ' ; 
 
 
 
             - -   s i a c _ r _ s u b d o c _ p r o v _ c a s s a 
 
             d e l e t e   f r o m   s i a c _ r _ s u b d o c _ p r o v _ c a s s a   r 
 
             u s i n g   p a g o p a _ b c k _ t _ s u b d o c _ p r o v _ c a s s a   p a g o s u b d o c 
 
             w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r . s u b d o c _ p r o v c _ i d = p a g o s u b d o c . s u b d o c _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' ; 
 
 
 
             - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
             d e l e t e   f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r 
 
             u s i n g   p a g o p a _ b c k _ t _ s u b d o c _ m o v g e s t _ t s   p a g o s u b d o c 
 
             w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r . s u b d o c _ m o v g e s t _ t s _ i d = p a g o s u b d o c . s u b d o c _ m o v g e s t _ t s _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e - p u l i z i a   [ p a g o p a _ t _ m o d i f i c a _ e l a b ] . ' ; 
 
             u p d a t e   p a g o p a _ t _ m o d i f i c a _ e l a b   r 
 
             s e t         p a g o p a _ m o d i f i c a _ e l a b _ n o t e = ' D O C U M E N T O   C A N C E L L A T O   I N   C L E A N   P E R   p a g o P a C o d e E r r = ' | | P A G O P A _ E R R _ 3 6 | | '   ' , 
 
                           s u b d o c _ i d = n u l l 
 
             f r o m   	 p a g o p a _ b c k _ t _ s u b d o c   p a g o s u b d o c 
 
             w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r . s u b d o c _ i d = p a g o s u b d o c . s u b d o c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d ; 
 
 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   [ s i a c _ t _ s u b d o c ] . ' ; 
 
 
 
             - -   s i a c _ t _ s u b d o c 
 
             d e l e t e   f r o m   s i a c _ t _ s u b d o c   r 
 
             u s i n g   p a g o p a _ b c k _ t _ s u b d o c   p a g o s u b d o c 
 
             w h e r e   r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r . s u b d o c _ i d = p a g o s u b d o c . s u b d o c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o s u b d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d ; 
 
 - -             a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
 	     - -   c a n c e l l a z i o n e   s u   d o c u m e n t i   s e n z a   q u o t e 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ r _ d o c _ s o g ] . ' ; 
 
 
 
             - -   s i a c _ r _ d o c _ s o g 
 
 
 
             d e l e t e   f r o m   s i a c _ r _ d o c _ s o g   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a ,   p a g o p a _ b c k _ t _ d o c _ s o g   p a g o p a D e l 
 
             w h e r e   r . d o c _ s o g _ i d = p a g o p a D e l . d o c _ s o g _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a . d o c _ i d 
 
           - -   a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           - -   a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ r _ d o c _ s t a t o ] . ' ; 
 
 
 
             - -   s i a c _ r _ d o c _ s t a t o 
 
             d e l e t e   f r o m   s i a c _ r _ d o c _ s t a t o   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a ,   p a g o p a _ b c k _ t _ d o c _ s t a t o   p a g o p a D e l 
 
             w h e r e   r . d o c _ s t a t o _ r _ i d = p a g o p a D e l . d o c _ s t a t o _ r _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a . d o c _ i d 
 
       - -       a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 - -             a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ r _ d o c _ a t t r ] . ' ; 
 
 
 
             - -   s i a c _ r _ d o c _ a t t r 
 
             d e l e t e   f r o m   s i a c _ r _ d o c _ a t t r   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a ,   p a g o p a _ b c k _ t _ d o c _ a t t r   p a g o p a D e l 
 
             w h e r e   r . d o c _ a t t r _ i d = p a g o p a D e l . d o c _ a t t r _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a . d o c _ i d 
 
         - -     a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         - -     a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ r _ d o c _ c l a s s ] . ' ; 
 
 
 
             - -   s i a c _ r _ d o c _ c l a s s 
 
             d e l e t e   f r o m   s i a c _ r _ d o c _ c l a s s   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a ,   p a g o p a _ b c k _ t _ d o c _ c l a s s   p a g o p a D e l 
 
             w h e r e   r . d o c _ c l a s s i f _ i d = p a g o p a D e l . d o c _ c l a s s i f _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a . d o c _ i d 
 
         - -     a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         - -     a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ t _ r e g i s t r o u n i c o _ d o c ] . ' ; 
 
 
 
             - -   s i a c _ t _ r e g i s t r o u n i c o _ d o c 
 
             d e l e t e   f r o m   s i a c _ t _ r e g i s t r o u n i c o _ d o c   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a ,   p a g o p a _ b c k _ t _ r e g i s t r o u n i c o _ d o c   p a g o p a D e l 
 
             w h e r e   r . r u d o c _ i d = p a g o p a D e l . r u d o c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a . d o c _ i d 
 
       - -       a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       - -       a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ t _ s u b d o c _ n u m ] . ' ; 
 
 
 
             - -   s i a c _ t _ s u b d o c _ n u m 
 
             d e l e t e   f r o m   s i a c _ t _ s u b d o c _ n u m   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a ,   p a g o p a _ b c k _ t _ s u b d o c _ n u m   p a g o p a D e l 
 
             w h e r e   r . s u b d o c _ n u m _ i d = p a g o p a D e l . s u b d o c _ n u m _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a . d o c _ i d 
 
     - -         a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     - -         a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   C a n c e l l a z i o n e   D o c u m e n t i   s e n z a   q u o t e   [ s i a c _ t _ d o c ] . ' ; 
 
 
 
             - -   s i a c _ t _ d o c 
 
             d e l e t e   f r o m   s i a c _ t _ d o c   r 
 
             u s i n g   p a g o p a _ b c k _ t _ d o c   p a g o p a D e l 
 
             w h e r e   r . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a D e l . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       n o t   e x i s t s 
 
             ( 
 
             s e l e c t   1   f r o m   s i a c _ t _ s u b d o c   s u b 
 
             w h e r e   s u b . d o c _ i d = p a g o p a D e l . d o c _ i d 
 
     - -         a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     - -         a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l 
 
             ) ; 
 
 
 
 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A g g i o r n a m e n t o   s t a t o   d o c u m e n t i   r i m a n e n t i   i n   v i t a . ' ; 
 
             - -   a g g i o r n a m e n t o   s t a t o   d o c u m e n t i   p e r   r i m a n e n t i   i n   v i t a   c o n   q u o t e 
 
             - -   e s e c u z i o n e   f n c   p e r 
 
             s e l e c t 
 
               f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i _ a g g i o r n a _ s t a t o _ d o c 
 
 	       ( 
 
 	 	 p a g o p a d o c . d o c _ i d , 
 
                 f i l e P a g o P a E l a b I d , 
 
 	 	 e n t e P r o p r i e t a r i o I d , 
 
 	 	 l o g i n O p e r a z i o n e 
 
 	 	 )   i n t o   A g g R e c 
 
 	     f r o m   p a g o p a _ b c k _ t _ d o c   p a g o p a d o c ,   p a g o p a _ b c k _ t _ s u b d o c   p a g o p a s u b 
 
             w h e r e   p a g o p a d o c . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a d o c . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a s u b . p a g o p a _ p r o v c _ i d = p a g o p a d o c . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a s u b . p a g o p a _ e l a b _ i d = p a g o p a d o c . p a g o p a _ e l a b _ i d 
 
             a n d       p a g o p a s u b . d o c _ i d = p a g o p a d o c . d o c _ i d 
 
             a n d       p a g o p a d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p a g o p a d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       p a g o p a s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       p a g o p a s u b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i _ c l e a n   -   F i n e   c a n c e l l a z i o n e   d o c .   -   ' | | s t r M e s s a g g i o F i n a l e ; 
 
 	     i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
             ( 
 
               p a g o p a _ e l a b _ i d , 
 
               p a g o p a _ e l a b _ f i l e _ i d , 
 
               p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
               e n t e _ p r o p r i e t a r i o _ i d , 
 
               l o g i n _ o p e r a z i o n e , 
 
               d a t a _ c r e a z i o n e 
 
             ) 
 
             v a l u e s 
 
             ( 
 
               f i l e P a g o P a E l a b I d , 
 
               n u l l , 
 
               s t r M e s s a g g i o L o g , 
 
               e n t e P r o p r i e t a r i o I d , 
 
               l o g i n O p e r a z i o n e , 
 
               c l o c k _ t i m e s t a m p ( ) 
 
             ) ; 
 
 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | ' A g g i o r n a m e n t o     p a g o p a _ t _ r i c o n c i l i a z i o n e . ' ; 
 
 
 
             - -   a g g i o r n a r e   p a g o p a _ t _ r i c o n c i l i a z i o n e 
 
             u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             s e t         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                           d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                           p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d 
 
             f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o ,   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c , 
 
                       p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e ,   p a g o p a _ b c k _ t _ s u b d o c   p a g o p a 
 
             w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' S ' 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . s u b d o c _ i d = d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
             a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = f l u s s o . e n t e _ p r o p r i e t a r i o _ i d 
 
             a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 3 6 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i _ c l e a n   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
 	     i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
             ( 
 
               p a g o p a _ e l a b _ i d , 
 
               p a g o p a _ e l a b _ f i l e _ i d , 
 
               p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
               e n t e _ p r o p r i e t a r i o _ i d , 
 
               l o g i n _ o p e r a z i o n e , 
 
               d a t a _ c r e a z i o n e 
 
             ) 
 
             v a l u e s 
 
             ( 
 
               f i l e P a g o P a E l a b I d , 
 
               n u l l , 
 
               s t r M e s s a g g i o L o g , 
 
               e n t e P r o p r i e t a r i o I d , 
 
               l o g i n O p e r a z i o n e , 
 
               c l o c k _ t i m e s t a m p ( ) 
 
             ) ; 
 
 	     s t r M e s s a g g i o : = s t r M e s s a g g i o B c k ; 
 
             s t r M e s s a g g i o : = s t r M e s s a g g i o | | ' A g g i o r n a m e n t o     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c . ' ; 
 
             - -   a g g i o r n a r e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
             u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
             s e t         p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
                           p a g o p a _ r i c _ d o c _ s u b d o c _ i d = n u l l , 
 
                           p a g o p a _ r i c _ d o c _ p r o v c _ i d = n u l l , 
 
                           p a g o p a _ r i c _ d o c _ m o v g e s t _ t s _ i d = n u l l , 
 
                           d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                           p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d 
 
             f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , 
 
                       p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e ,   p a g o p a _ b c k _ t _ s u b d o c   p a g o p a 
 
             w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' S ' 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       p a g o p a . s u b d o c _ i d = d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d 
 
             a n d       p a g o p a . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       p a g o p a . p a g o p a _ p r o v c _ i d = P a g o P a R e c C l e a n . p a g o p a _ p r o v c _ i d 
 
             a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = f l u s s o . e n t e _ p r o p r i e t a r i o _ i d 
 
             a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 3 6 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i _ c l e a n   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
 	     i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
             ( 
 
               p a g o p a _ e l a b _ i d , 
 
               p a g o p a _ e l a b _ f i l e _ i d , 
 
               p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
               e n t e _ p r o p r i e t a r i o _ i d , 
 
               l o g i n _ o p e r a z i o n e , 
 
               d a t a _ c r e a z i o n e 
 
             ) 
 
             v a l u e s 
 
             ( 
 
               f i l e P a g o P a E l a b I d , 
 
               n u l l , 
 
               s t r M e s s a g g i o L o g , 
 
               e n t e P r o p r i e t a r i o I d , 
 
               l o g i n O p e r a z i o n e , 
 
               c l o c k _ t i m e s t a m p ( ) 
 
             ) ; 
 
 
 
     e n d   l o o p ; 
 
 
 
     / *   s o s t i t u i t o   c o n   d i a g n o s t i c   d o p o   i n s e r t   t a b e l l a 
 
     s t r M e s s a g g i o : = '   V e r i f i c a   e s i s t e n z a   i n   p a g o p a _ b c k _ t _ s u b d o c   a   t e r m i n e   a g g i o r n a m e n t o . ' ; 
 
     s e l e c t   ( c a s e   w h e n   c o u n t ( * ) ! = 0   t h e n   t r u e   e l s e   f a l s e   e n d   )   i n t o   p a g o p a B c k S u b d o c 
 
     f r o m   p a g o p a _ b c k _ t _ s u b d o c   b c k 
 
     w h e r e   b c k . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
     a n d       b c k . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       b c k . v a l i d i t a _ f i n e   i s   n u l l ; * / 
 
 
 
 
 
 
 
     m e s s a g g i o R i s u l t a t o : = ' O K   -   ' | | u p p e r ( s t r M e s s a g g i o F i n a l e ) ; 
 
 
 
     s t r M e s s a g g i o L o g : = ' F i n e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i _ c l e a n   -   ' | | m e s s a g g i o R i s u l t a t o ; 
 
     i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
     ( 
 
       p a g o p a _ e l a b _ i d , 
 
       p a g o p a _ e l a b _ f i l e _ i d , 
 
       p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
       e n t e _ p r o p r i e t a r i o _ i d , 
 
       l o g i n _ o p e r a z i o n e , 
 
       d a t a _ c r e a z i o n e 
 
     ) 
 
     v a l u e s 
 
     ( 
 
       f i l e P a g o P a E l a b I d , 
 
       n u l l , 
 
       s t r M e s s a g g i o L o g , 
 
       e n t e P r o p r i e t a r i o I d , 
 
       l o g i n O p e r a z i o n e , 
 
       c l o c k _ t i m e s t a m p ( ) 
 
     ) ; 
 
 
 
     r e t u r n ; 
 
 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = 
 
                 	 c o a l e s c e ( s t r M e s s a g g i o F i n a l e , ' ' ) | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E :     ' | | '   ' | | c o a l e s c e ( s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , ' ' )   ; 
 
               	 c o d i c e R i s u l t a t o : = - 1 ; 
 
 
 
 	 	 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   N O _ D A T A _ F O U N D   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   N e s s u n   d a t o   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   T O O _ M A N Y _ R O W S   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   D i v e r s e   r i g h e   p r e s e n t i   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
 
 
                 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   D B : ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
                 r e t u r n ; 
 
 
 
 E N D ; 
 
 $ b o d y $ 
 
 L A N G U A G E   ' p l p g s q l ' 
 
 V O L A T I L E 
 
 C A L L E D   O N   N U L L   I N P U T 
 
 S E C U R I T Y   I N V O K E R 
 
 C O S T   1 0 0 ; 