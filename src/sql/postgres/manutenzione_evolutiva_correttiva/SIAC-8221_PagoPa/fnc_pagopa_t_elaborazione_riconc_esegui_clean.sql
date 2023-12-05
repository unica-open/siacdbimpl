/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
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
             -- login_operazione=doc.login_operazione||'-'||loginOperazione -- 07.07.2021 Sofia Jira SIAC-8221 
			 login_operazione=loginOperazione||'@ELAB_ID='||filePagoPaElabId::varchar -- 07.07.2021 Sofia Jira SIAC-8221 
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
COST 100;

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  integer,integer,integer,varchar,timestamp,
  out BOOLEAN,out integer,out varchar
)  OWNER to siac;