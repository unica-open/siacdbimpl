/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioBck VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




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

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

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
--    raise notice '2222%',strMessaggioLog;
--    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
--    raise notice '2222strMessaggio%',strMessaggio;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
--    raise notice '2222@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
--         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	   pagopa_ric_errore_id=err.pagopa_ric_errore_id,
               data_modifica=clock_timestamp(),
               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona già tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
--      raise notice 'strMessaggio=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=upper(strMessaggioFinale||' '||strMessaggio),
            login_operazione=file.login_operazione||'-'||loginOperazione
        from  pagopa_r_elaborazione_file r,
              siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
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
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id -- siac-6720
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id -- siac-6720
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti , soggetto_acc
   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id -- siac-6720
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;

		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

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

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;
--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id -- null ??
        )
        select annoBilancio,
               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

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

        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti , soggetto_acc
		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione,
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione,
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             login_operazione=det.login_operazione||'-'||loginOperazione
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then

          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;

	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
      --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
       --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          accertamenti as
          (
          select ts.movgest_ts_id, rsog.soggetto_id
          from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
               siac_r_movgest_ts_sog rsog
          where mov.bil_id=bilancioId
          and   mov.movgest_tipo_id=movgestTipoId
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_tipo_id=movgestTsTipoId
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   rs.movgest_stato_id=movgestStatoId
          and   rsog.movgest_ts_id=ts.movgest_ts_id
--          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
          and   mov.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
          and   ts.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
          and   rs.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
          and   rsog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else s2.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id)
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
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

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
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

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp(),
         login_operazione=num.login_operazione||'-'||loginOperazione
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=elab.pagopa_elab_note
            ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=file.file_pagopa_note
                    ||' AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.',
           login_operazione=file.login_operazione||'-'||loginOperazione
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';
  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';
       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio);
       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
              login_operazione=file.login_operazione||'-'||loginOperazione
       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
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
COST 100; s s ] ' 
 
                                                   | | ' .   V e r i f i c a   e s i s t e n z a   c o m e   C D R . ' ; 
 
 	                         s e l e c t   c . c l a s s i f _ i d   i n t o   c o d R e s u l t 
 
         	                 f r o m   s i a c _ t _ c l a s s   c 
 
                 	         w h e r e   c . c l a s s i f _ t i p o _ i d = c d r T i p o I d 
 
 	                       	 a n d       c . c l a s s i f _ c o d e = p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m 
 
         	                 a n d       c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	         a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , c . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( c . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) ; 
 
                         e n d   i f ; 
 
                         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                               c o d R e s u l t 1 : = c o d R e s u l t ; 
 
                               c o d R e s u l t : = n u l l ; 
 
 	                       s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   c o l l .   s t r u t t u r a   a m m i n i s t r a t i v a     [ s i a c _ r _ d o c _ c l a s s ] . ' ; 
 
 
 
                         	 i n s e r t   i n t o   s i a c _ r _ d o c _ c l a s s 
 
                                 ( 
 
                                 	 d o c _ i d , 
 
                                         c l a s s i f _ i d , 
 
                                         v a l i d i t a _ i n i z i o , 
 
                                         l o g i n _ o p e r a z i o n e , 
 
                                         e n t e _ p r o p r i e t a r i o _ i d 
 
                                 ) 
 
                                 v a l u e s 
 
                                 ( 
 
                                 	 d o c I d , 
 
                                         c o d R e s u l t 1 , 
 
                                         c l o c k _ t i m e s t a m p ( ) , 
 
                                         l o g i n O p e r a z i o n e , 
 
                                         e n t e P r o p r i e t a r i o I d 
 
                                 ) 
 
                                 r e t u r n i n g   d o c _ c l a s s i f _ i d   i n t o   c o d R e s u l t ; 
 
 
 
                                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                 	 b E r r o r e : = t r u e ; 
 
 	 	                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i m e n t o   n o n   r i u s c i t o . ' ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 	 	 i f   b E r r o r e   = f a l s e   t h e n 
 
 	 	   - -     s i a c _ t _ r e g i s t r o u n i c o _ d o c 
 
                   s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   r e g i s t r o   u n i c o   d o c u m e n t o   [ s i a c _ t _ r e g i s t r o u n i c o _ d o c ] . ' ; 
 
 
 
             	   c o d R e s u l t : = n u l l ; 
 
                   i n s e r t   i n t o   s i a c _ t _ r e g i s t r o u n i c o _ d o c 
 
                   ( 
 
                 	 r u d o c _ r e g i s t r a z i o n e _ a n n o , 
 
   	 	 	 r u d o c _ r e g i s t r a z i o n e _ n u m e r o , 
 
 	 	 	 r u d o c _ r e g i s t r a z i o n e _ d a t a , 
 
 	 	 	 d o c _ i d , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                   ) 
 
                   s e l e c t   n u m . r u d o c _ r e g i s t r a z i o n e _ a n n o , 
 
                                 n u m . r u d o c _ r e g i s t r a z i o n e _ n u m e r o + 1 , 
 
                                 c l o c k _ t i m e s t a m p ( ) , 
 
                                 d o c I d , 
 
                                 l o g i n O p e r a z i o n e , 
 
                                 c l o c k _ t i m e s t a m p ( ) , 
 
                                 n u m . e n t e _ p r o p r i e t a r i o _ i d 
 
                   f r o m   s i a c _ t _ r e g i s t r o u n i c o _ d o c _ n u m   n u m 
 
                   w h e r e   n u m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                   a n d       n u m . r u d o c _ r e g i s t r a z i o n e _ a n n o = a n n o B i l a n c i o 
 
                   a n d       n u m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , n u m . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( n u m . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                   r e t u r n i n g   r u d o c _ i d   i n t o   c o d R e s u l t ; 
 
                   i f   c o d R e s u l t   i s   n u l l   t h e n 
 
 	                 b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i m e n t o   n o n   r i u s c i t o . ' ; 
 
                   e n d   i f ; 
 
                   i f   b E r r o r e = f a l s e   t h e n 
 
                         c o d R e s u l t : = n u l l ; 
 
                   	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   A g g i o r n a m e n t o   r e g i s t r o   u n i c o   d o c u m e n t o   [ s i a c _ t _ r e g i s t r o u n i c o _ d o c _ n u m ] . ' ; 
 
                   	 u p d a t e   s i a c _ t _ r e g i s t r o u n i c o _ d o c _ n u m   n u m 
 
                         s e t         r u d o c _ r e g i s t r a z i o n e _ n u m e r o = n u m . r u d o c _ r e g i s t r a z i o n e _ n u m e r o + 1 , 
 
                                       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) 
 
                 	 w h e r e   n u m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	                 a n d       n u m . r u d o c _ r e g i s t r a z i o n e _ a n n o = a n n o B i l a n c i o 
 
                   	 a n d       n u m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	                 a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , n u m . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( n u m . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                         r e t u r n i n g   n u m . r u d o c _ n u m _ i d   i n t o   c o d R e s u l t ; 
 
                         i f   c o d R e s u l t   i s   n u l l     t h e n 
 
                               b E r r o r e : = t r u e ; 
 
                               s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A g g i o r n a m e n t o   n o n   r i u s c i t o . ' ; 
 
                         e n d   i f ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 	 	 i f   b E r r o r e   = f a l s e   t h e n 
 
                   c o d R e s u l t : = n u l l ; 
 
 	 	   - -     s i a c _ t _ d o c _ n u m 
 
                   s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   A g g i o r n a m e n t o   p r o g r e s s i v i   d o c u m e n t i   [ s i a c _ t _ d o c _ n u m ] . ' ; 
 
                   - - -   1 2 . 0 6 . 2 0 1 9   S i a c - 6 7 2 0 
 
 - -                   r a i s e   n o t i c e   ' p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ c o d e 2 = % ' , p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ c o d e ; 
 
                   i f   i s D o c I P A = t r u e   t h e n 
 
                       u p d a t e   s i a c _ t _ d o c _ n u m   n u m 
 
                       s e t         d o c _ n u m e r o = n u m . d o c _ n u m e r o + 1 , 
 
                                     d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) 
 
                       w h e r e     n u m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o i d 
 
                       a n d         n u m . d o c _ a n n o = a n n o B i l a n c i o 
 
                       a n d         n u m . d o c _ t i p o _ i d = d o c T i p o I d 
 
                       r e t u r n i n g   n u m . d o c _ n u m _ i d   i n t o   c o d R e s u l t ; 
 
                   e l s e 
 
                       u p d a t e   s i a c _ t _ d o c _ n u m   n u m 
 
                       s e t         d o c _ n u m e r o = n u m . d o c _ n u m e r o + 1 , 
 
                                     d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) 
 
                       w h e r e     n u m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o i d 
 
                       a n d         n u m . d o c _ a n n o = a n n o B i l a n c i o 
 
                       a n d         n u m . d o c _ t i p o _ i d   = p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ i d 
 
                       r e t u r n i n g   n u m . d o c _ n u m _ i d   i n t o   c o d R e s u l t ; 
 
                   e n d   i f ; 
 
                   i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                   	   b E r r o r e : = t r u e ; 
 
                           s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A g g i o r n a m e n t o   n o n   r i u s c i t o . ' ; 
 
                   e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
                 i f   b E r r o r e = t r u e   t h e n 
 
                         s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 e n d   i f ; 
 
 
 
 
 
 	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c ,   '   ' ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o . ' ; 
 
 - -                 r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 	 	 i f   b E r r o r e = f a l s e   t h e n 
 
 	 	 	 s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
 	         e n d   i f ; 
 
 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
                 f o r   p a g o P a F l u s s o Q u o t e R e c   i n 
 
     	 	 ( 
 
     	           w i t h 
 
                       p a g o p a _ s o g g   a s 
 
 	 	       ( 
 
                       w i t h 
 
 	 	       p a g o p a   a s 
 
 	 	       ( 
 
 	 	       s e l e c t   d o c . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f   p a g o p a _ c o d i c e _ b e n e f , 
 
 	 	 	             d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m   p a g o p a _ s t r _ a m m , 
 
                                     d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a   p a g o p a _ v o c e _ t e m a t i c a , 
 
                       	 	     d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e   p a g o p a _ v o c e _ c o d e ,     d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c   p a g o p a _ v o c e _ d e s c , 
 
                                     d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e   p a g o p a _ s o t t o v o c e _ c o d e ,   d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c   p a g o p a _ s o t t o v o c e _ d e s c , 
 
                                     f l u s s o . p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o   p a g o p a _ a n n o _ p r o v v i s o r i o , 
 
                                     f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o   p a g o p a _ n u m _ p r o v v i s o r i o , 
 
                                     f l u s s o . p a g o p a _ e l a b _ r i c _ f l u s s o _ i d   p a g o p a _ f l u s s o _ i d , 
 
                                     f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n o m e _ m i t t e n t e   p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e , 
 
                 	 	     d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o   p a g o p a _ a n n o _ a c c e r t a m e n t o , 
 
 	 	                     d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o     p a g o p a _ n u m _ a c c e r t a m e n t o , 
 
                                     d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ i m p o r t o   p a g o p a _ s o t t o v o c e _ i m p o r t o 
 
 	 	       f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o ,   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
 	 	       w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
 	 	       a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                       a n d       d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ i d   - -   3 0 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                       a n d       c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ t e m a t i c a , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) ) 
 
                       a n d       d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e = p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e 
 
                       a n d       c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) ) 
 
                       a n d       c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) ) 
 
 	 	       a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' N ' 
 
                       a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
 	 	       a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
 	 	       a n d       n o t   e x i s t s   - -   t u t t i   r e c o r d   d i   u n   f l u s s o   d a   e l a b o r a r e   e   s e n z a   s c a r t i   o   e r r o r i 
 
 	 	       ( 
 
 	 	           s e l e c t   1 
 
 	 	           f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
 	 	           w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 	 	           a n d       d o c 1 . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   n o t   i n   ( ' N ' , ' S ' ) 
 
 	 	           a n d       d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	       ) 
 
 	 	       a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	       a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	       a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	       a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	       ) , 
 
 	 	       s o g g   a s 
 
 	 	       ( 
 
 	 	 	       s e l e c t   s o g . s o g g e t t o _ i d ,   s o g . s o g g e t t o _ c o d e , s o g . s o g g e t t o _ d e s c 
 
 	 	 	       f r o m   s i a c _ t _ s o g g e t t o   s o g 
 
 	 	 	       w h e r e   s o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 	       a n d       s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	       a n d       s o g . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	       ) 
 
 	 	       s e l e c t   p a g o p a . * , 
 
 	 	                     s o g g . s o g g e t t o _ i d , 
 
                 	 	     s o g g . s o g g e t t o _ d e s c 
 
 	 	       f r o m   p a g o p a 
 
 	 	                 l e f t   j o i n   s o g g   o n   ( p a g o p a . p a g o p a _ c o d i c e _ b e n e f = s o g g . s o g g e t t o _ c o d e ) 
 
 	 	       ) , 
 
 	 	       a c c e r t a m e n t i _ s o g g   a s 
 
 	 	       ( 
 
                           w i t h 
 
 	 	 	   a c c e r t a m e n t i   a s 
 
 	 	 	   ( 
 
 	 	 	       	 s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r ,   m o v . m o v g e s t _ n u m e r o : : i n t e g e r , 
 
 	 	         	               m o v . m o v g e s t _ i d ,   t s . m o v g e s t _ t s _ i d 
 
 	 	 	         f r o m   s i a c _ t _ m o v g e s t   m o v   ,   s i a c _ d _ m o v g e s t _ t i p o   t i p o , 
 
 	 	 	                   s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
 	 	 	                   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o 
 
 	 	 	         w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 	         a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' A ' 
 
 	 	 	         a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o . m o v g e s t _ t i p o _ i d 
 
 	 	 	         a n d       m o v . b i l _ i d = b i l a n c i o I d 
 
 	 	 	         a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
 	 	 	         a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
 	 	 	         a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T ' 
 
 	 	 	         a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
 	 	 	         a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
 	 	 	         a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e = ' D ' 
 
 	 	 	         a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	         a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	 	         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	       ) , 
 
 	 	       s o g g e t t o _ a c c   a s 
 
 	 	       ( 
 
 	 	 	       s e l e c t   s o g . s o g g e t t o _ i d ,   s o g . s o g g e t t o _ c o d e ,   s o g . s o g g e t t o _ d e s c , r s o g . m o v g e s t _ t s _ i d 
 
 	 	 	       f r o m   s i a c _ r _ m o v g e s t _ t s _ s o g   r s o g ,   s i a c _ t _ s o g g e t t o   s o g 
 
 	 	 	       w h e r e   s o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 	 	 	       a n d       r s o g . s o g g e t t o _ i d = s o g . s o g g e t t o _ i d 
 
 	 	 	       a n d       r s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	 	       a n d       r s o g . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	       ) 
 
 	 	       s e l e c t   a c c e r t a m e n t i . * , s o g g e t t o _ a c c . s o g g e t t o _ i d ,   s o g g e t t o _ a c c . s o g g e t t o _ c o d e , s o g g e t t o _ a c c . s o g g e t t o _ d e s c 
 
 	 	       f r o m       a c c e r t a m e n t i   ,   s o g g e t t o _ a c c 
 
 	 	       w h e r e     a c c e r t a m e n t i . m o v g e s t _ t s _ i d = s o g g e t t o _ a c c . m o v g e s t _ t s _ i d 
 
 	     	   ) 
 
 	 	   s e l e c t     (   c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . p a g o p a _ c o d i c e _ b e n e f   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ c o d e   e n d   )     p a g o p a _ s o g g e t t o _ c o d e , 
 
       	 	 	 	   (   c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . s o g g e t t o _ d e s c   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ d e s c   e n d   )   p a g o p a _ s o g g e t t o _ d e s c 	 , 
 
                                   (   c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ i d   e n d   )   p a g o p a _ s o g g e t t o _ i d , 
 
                                   p a g o p a _ s o g g . p a g o p a _ s t r _ a m m , 
 
                                   p a g o p a _ s o g g . p a g o p a _ v o c e _ t e m a t i c a , 
 
                                   p a g o p a _ s o g g . p a g o p a _ v o c e _ c o d e ,     p a g o p a _ s o g g . p a g o p a _ v o c e _ d e s c , 
 
                                   p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ c o d e ,   p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ d e s c , 
 
                                   p a g o p a _ s o g g . p a g o p a _ f l u s s o _ i d , 
 
                                   p a g o p a _ s o g g . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e , 
 
                                   p a g o p a _ s o g g . p a g o p a _ a n n o _ p r o v v i s o r i o , 
 
                                   p a g o p a _ s o g g . p a g o p a _ n u m _ p r o v v i s o r i o , 
 
                                   p a g o p a _ s o g g . p a g o p a _ a n n o _ a c c e r t a m e n t o , 
 
 	 	                   p a g o p a _ s o g g . p a g o p a _ n u m _ a c c e r t a m e n t o , 
 
                                   s u m ( p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ i m p o r t o )   p a g o p a _ s o t t o v o c e _ i m p o r t o 
 
     	           f r o m     p a g o p a _ s o g g ,   a c c e r t a m e n t i _ s o g g 
 
   	           w h e r e   b E r r o r e = f a l s e 
 
                   a n d       p a g o p a _ s o g g . p a g o p a _ a n n o _ a c c e r t a m e n t o = a c c e r t a m e n t i _ s o g g . m o v g e s t _ a n n o 
 
 	       	   a n d       p a g o p a _ s o g g . p a g o p a _ n u m _ a c c e r t a m e n t o = a c c e r t a m e n t i _ s o g g . m o v g e s t _ n u m e r o 
 
                   a n d       ( c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ i d   e n d   ) = 
 
 	                       p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ i d 
 
 	           g r o u p   b y   (   c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . p a g o p a _ c o d i c e _ b e n e f   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ c o d e   e n d   ) , 
 
                 	             (   c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . s o g g e t t o _ d e s c   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ d e s c   e n d   ) , 
 
                                     (   c a s e   w h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   p a g o p a _ s o g g . s o g g e t t o _ i d   e l s e   a c c e r t a m e n t i _ s o g g . s o g g e t t o _ i d   e n d   ) , 
 
                                     p a g o p a _ s o g g . p a g o p a _ s t r _ a m m , 
 
                                     p a g o p a _ s o g g . p a g o p a _ v o c e _ t e m a t i c a , 
 
                                     p a g o p a _ s o g g . p a g o p a _ v o c e _ c o d e ,   p a g o p a _ s o g g . p a g o p a _ v o c e _ d e s c , 
 
                                     p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ c o d e ,   p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ d e s c , 
 
                                     p a g o p a _ s o g g . p a g o p a _ f l u s s o _ i d , p a g o p a _ s o g g . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e , 
 
                                     p a g o p a _ s o g g . p a g o p a _ a n n o _ p r o v v i s o r i o , 
 
                                     p a g o p a _ s o g g . p a g o p a _ n u m _ p r o v v i s o r i o , 
 
                                     p a g o p a _ s o g g . p a g o p a _ a n n o _ a c c e r t a m e n t o , 
 
 	 	                     p a g o p a _ s o g g . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
 	           o r d e r   b y     p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ c o d e ,   p a g o p a _ s o g g . p a g o p a _ s o t t o v o c e _ d e s c , 
 
                                       p a g o p a _ s o g g . p a g o p a _ a n n o _ p r o v v i s o r i o , 
 
                                       p a g o p a _ s o g g . p a g o p a _ n u m _ p r o v v i s o r i o , 
 
 	 	 	 	       p a g o p a _ s o g g . p a g o p a _ a n n o _ a c c e r t a m e n t o , 
 
 	 	                       p a g o p a _ s o g g . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
     	       ) 
 
               l o o p 
 
 
 
                 c o d R e s u l t : = n u l l ; 
 
                 c o d R e s u l t 1 : = n u l l ; 
 
                 s u b d o c I d : = n u l l ; 
 
                 s u b d o c M o v g e s t T s I d : = n u l l ; 
 
 	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ t _ s u b d o c ] . ' ; 
 
 - -                 r a i s e   n o t i c e   ' s t r M e s s a g i o = % ' , s t r M e s s a g g i o ; 
 
 	 	 s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
 	 	 - -   s i a c _ t _ s u b d o c 
 
                 i n s e r t   i n t o   s i a c _ t _ s u b d o c 
 
                 ( 
 
                 	 s u b d o c _ n u m e r o , 
 
 	 	 	 s u b d o c _ d e s c , 
 
 	 	 	 s u b d o c _ i m p o r t o , 
 
 - - 	 	         s u b d o c _ n r e g _ i v a , 
 
 	                 s u b d o c _ d a t a _ s c a d e n z a , 
 
 	                 s u b d o c _ c o n v a l i d a _ m a n u a l e , 
 
 	                 s u b d o c _ i m p o r t o _ d a _ d e d u r r e ,   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 8 9 3 
 
 - - 	                 s u b d o c _ s p l i t r e v e r s e _ i m p o r t o , 
 
 - - 	                 s u b d o c _ p a g a t o _ c e c , 
 
 - - 	                 s u b d o c _ d a t a _ p a g a m e n t o _ c e c , 
 
 - - 	                 c o n t o t e s _ i d   I N T E G E R , 
 
 - - 	                 d i s t _ i d   I N T E G E R , 
 
 - - 	                 c o m m _ t i p o _ i d   I N T E G E R , 
 
 	                 d o c _ i d , 
 
 	                 s u b d o c _ t i p o _ i d , 
 
 - - 	                 n o t e t e s _ i d   I N T E G E R , 
 
 	                 v a l i d i t a _ i n i z i o , 
 
 	 	 	 e n t e _ p r o p r i e t a r i o _ i d , 
 
 	 	         l o g i n _ o p e r a z i o n e , 
 
 	                 l o g i n _ c r e a z i o n e , 
 
                         l o g i n _ m o d i f i c a 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                 	 d n u m Q u o t e + 1 , 
 
                         u p p e r ( ' V o c e   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ v o c e _ c o d e | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ c o d e | | '   ' | | 
 
                         s u b s t r i n g ( c o a l e s c e ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ d e s c , '   '   ) , 1 , 3 0 ) | | 
 
                         p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ i d | | '   P S P   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e | | 
 
                         '   P r o v .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o : : v a r c h a r | | ' / ' | | 
 
                         p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o ) , 
 
                         p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o , 
 
                         d a t a E l a b o r a z i o n e , 
 
                         ' M ' ,   - - -   1 3 . 1 2 . 2 0 1 8   S o f i a   s i a c - 6 6 0 2 
 
                         0 ,       - - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 8 9 3 
 
     	 	 	 d o c I d , 
 
                         s u b D o c T i p o I d , 
 
                         c l o c k _ t i m e s t a m p ( ) , 
 
                         e n t e P r o p r i e t a r i o I d , 
 
                         l o g i n O p e r a z i o n e , 
 
                         l o g i n O p e r a z i o n e , 
 
                         l o g i n O p e r a z i o n e 
 
                 ) 
 
                 r e t u r n i n g   s u b d o c _ i d   i n t o   s u b D o c I d ; 
 
 - -                 r a i s e   n o t i c e   ' s u b d o c I d = % ' , s u b d o c I d ; 
 
                 i f   s u b D o c I d   i s   n u l l   t h e n 
 
                         b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; 
 
 
 
 	 	 - -   s i a c _ r _ s u b d o c _ a t t r 
 
 	 	 - -   f l a g A v v i s o 
 
 	 	 - -   f l a g E s p r o p r i o 
 
 	 	 - -   f l a g O r d i n a t i v o M a n u a l e 
 
 	 	 - -   f l a g O r d i n a t i v o S i n g o l o 
 
 	 	 - -   f l a g R i l e v a n t e I V A 
 
                 c o d R e s u l t : = n u l l ; 
 
       	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ a t t r   v a r i ] . ' ; 
 
 
 
 	 	 i n s e r t   i n t o   s i a c _ r _ s u b d o c _ a t t r 
 
                 ( 
 
                 	 s u b d o c _ i d , 
 
                         a t t r _ i d , 
 
                         b o o l e a n , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                 ) 
 
                 s e l e c t   s u b d o c I d , 
 
                               a . a t t r _ i d , 
 
                               ' N ' , 
 
                               c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n O p e r a z i o n e , 
 
                               a . e n t e _ p r o p r i e t a r i o _ i d 
 
                 f r o m   s i a c _ t _ a t t r   a 
 
                 w h e r e   a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       a . a t t r _ c o d e   i n 
 
                 ( 
 
                   F L _ A V V I S O _ A T T R , 
 
 	           F L _ E S P R O P R I O _ A T T R , 
 
 	           F L _ O R D _ M A N U A L E _ A T T R , 
 
 	 	   F L _ O R D _ S I N G O L O _ A T T R , 
 
 	           F L _ R I L _ I V A _ A T T R 
 
                 ) ; 
 
                 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
                 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0   t h e n 
 
                         b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                         c o n t i n u e ; 
 
 
 
                 e n d   i f ; 
 
 
 
 	 	 - -   c a u s a l e O r d i n a t i v o 
 
                 / * c o d R e s u l t : = n u l l ; 
 
       	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ a t t r = ' | | C A U S _ O R D I N _ A T T R | | ' ] . ' ; 
 
 
 
 	 	 i n s e r t   i n t o   s i a c _ r _ s u b d o c _ a t t r 
 
                 ( 
 
                 	 s u b d o c _ i d , 
 
                         a t t r _ i d , 
 
                         t e s t o , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                 ) 
 
                 s e l e c t   s u b d o c I d , 
 
                               a . a t t r _ i d , 
 
                               u p p e r ( ' R e g o l a r i z z a z i o n e   i n c a s s o   v o c e   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ v o c e _ c o d e | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ c o d e | | '   ' | | 
 
 	                         s u b s t r i n g ( c o a l e s c e ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ d e s c , '   ' ) , 1 , 3 0 ) | | 
 
         	                 '   P r o v .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o : : v a r c h a r | | ' / ' | | 
 
                 	         p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | '   ' ) , 
 
                               c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n O p e r a z i o n e , 
 
                               a . e n t e _ p r o p r i e t a r i o _ i d 
 
                 f r o m   s i a c _ t _ a t t r   a 
 
                 w h e r e   a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       a . a t t r _ c o d e = C A U S _ O R D I N _ A T T R 
 
                 r e t u r n i n g   s u b d o c _ a t t r _ i d   i n t o   c o d R e s u l t ; 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                 	 b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; * / 
 
 
 
 	 	 - -   d a t a E s e c u z i o n e P a g a m e n t o 
 
         	 / * c o d R e s u l t : = n u l l ; 
 
       	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   ' ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ a t t r = ' | | D A T A _ E S E C _ P A G _ A T T R | | ' ] . ' ; 
 
 
 
 	 	 i n s e r t   i n t o   s i a c _ r _ s u b d o c _ a t t r 
 
                 ( 
 
                 	 s u b d o c _ i d , 
 
                         a t t r _ i d , 
 
                         t e s t o , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                 ) 
 
                 s e l e c t   s u b d o c I d , 
 
                               a . a t t r _ i d , 
 
                               n u l l , 
 
                               c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n O p e r a z i o n e , 
 
                               a . e n t e _ p r o p r i e t a r i o _ i d 
 
                 f r o m   s i a c _ t _ a t t r   a 
 
                 w h e r e   a . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       a . a t t r _ c o d e = D A T A _ E S E C _ P A G _ A T T R 
 
                 r e t u r n i n g   s u b d o c _ a t t r _ i d   i n t o   c o d R e s u l t ; 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                 	 b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; * / 
 
 
 
     	         - -   c o n t r o l l o   s f o n d a m e n t o   e   a d e g u a m e n t o   a c c e r t a m e n t o 
 
       	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c ,   '   ' ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | ' .   V e r i f i c a   e s i s t e n z a   a c c e r t a m e n t o . ' ; 
 
 
 
 	 	 c o d R e s u l t : = n u l l ; 
 
                 d i s p A c c e r t a m e n t o : = n u l l ; 
 
                 m o v g e s t T s I d : = n u l l ; 
 
                 s e l e c t   t s . m o v g e s t _ t s _ i d   i n t o   m o v g e s t T s I d 
 
                 f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s , 
 
                           s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s 
 
                 w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
                 a n d       m o v . m o v g e s t _ t i p o _ i d = m o v g e s t T i p o I d 
 
                 a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
                 a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                 a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                 a n d       t s . m o v g e s t _ t s _ t i p o _ i d = m o v g e s t T s T i p o I d 
 
                 a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                 a n d       r s . m o v g e s t _ s t a t o _ i d = m o v g e s t S t a t o I d 
 
                 a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                 a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , t s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( t s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                 a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , m o v . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( m o v . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) ; 
 
 
 
                 i f   m o v g e s t T s I d   i s   n o t   n u l l   t h e n 
 
               	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | ' .   V e r i f i c a   d i s p o n .   a c c e r t a m e n t o . ' ; 
 
 
 
 	                 s e l e c t   *   i n t o   d i s p A c c e r t a m e n t o 
 
                         f r o m   f n c _ s i a c _ d i s p o n i b i l i t a i n c a s s a r e m o v g e s t   ( m o v g e s t T s I d )   d i s p o n i b i l i t a ; 
 
 - - 	 	         r a i s e   n o t i c e   ' d i s p A c c e r t a m e n t o = % ' , d i s p A c c e r t a m e n t o ; 
 
                         i f   d i s p A c c e r t a m e n t o   i s   n o t   n u l l   t h e n 
 
                         	 i f   d i s p A c c e r t a m e n t o - p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o < 0   t h e n 
 
                                           - -   1 1 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0   -   i n s e r i m e n t o   m o v i m e n t o   d i   m o d i f i c a   a c c   a u t o m a t i c o 
 
 	 	             	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r 
 
                                                   | | ' .   A d e g u a m e n t o   i m p o r t o   A c c .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o : : v a r c h a r 
 
             	 	 	 	 	   | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o : : v a r c h a r | | ' .   I n s e r i m e n t o   m o v .   m o d i f i c a .   C a l c o l o   n u m e r o . ' ; 
 
 
 
 
 
                                         n u m M o d i f i c a : = n u l l ; 
 
                                         c o d R e s u l t : = n u l l ; 
 
                                         s e l e c t   c o a l e s c e ( m a x ( q u e r y . m o d _ n u m ) , 0 )   i n t o   n u m M o d i f i c a 
 
                                         f r o m 
 
                                         ( 
 
 	 	 	 	 	 s e l e c t     m o d i f . m o d _ n u m 
 
 	 	 	 	 	 f r o m   s i a c _ t _ m o d i f i c a   m o d i f ,   s i a c _ r _ m o d i f i c a _ s t a t o   r s , s i a c _ t _ m o v g e s t _ t s _ d e t _ m o d     m o d 
 
                                         w h e r e   m o d . m o v g e s t _ t s _ i d = m o v g e s t T s I d 
 
                                         a n d       r s . m o d _ s t a t o _ r _ i d = m o d . m o d _ s t a t o _ r _ i d 
 
                                         a n d       m o d i f . m o d _ i d = r s . m o d _ i d 
 
                                         a n d       m o d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       m o d . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       m o d i f . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       m o d i f . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         u n i o n 
 
 	 	 	 	 	 s e l e c t   m o d i f . m o d _ n u m 
 
 	 	 	 	 	 f r o m   s i a c _ t _ m o d i f i c a   m o d i f ,   s i a c _ r _ m o d i f i c a _ s t a t o   r s , s i a c _ r _ m o v g e s t _ t s _ s o g _ m o d     m o d 
 
                                         w h e r e   m o d . m o v g e s t _ t s _ i d = m o v g e s t T s I d 
 
                                         a n d       r s . m o d _ s t a t o _ r _ i d = m o d . m o d _ s t a t o _ r _ i d 
 
                                         a n d       m o d i f . m o d _ i d = r s . m o d _ i d 
 
                                         a n d       m o d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       m o d . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       m o d i f . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       m o d i f . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         u n i o n 
 
 	 	 	 	 	 s e l e c t   m o d i f . m o d _ n u m 
 
 	 	 	 	 	 f r o m   s i a c _ t _ m o d i f i c a   m o d i f ,   s i a c _ r _ m o d i f i c a _ s t a t o   r s , s i a c _ r _ m o v g e s t _ t s _ s o g c l a s s e _ m o d     m o d 
 
                                         w h e r e   m o d . m o v g e s t _ t s _ i d = m o v g e s t T s I d 
 
                                         a n d       r s . m o d _ s t a t o _ r _ i d = m o d . m o d _ s t a t o _ r _ i d 
 
                                         a n d       m o d i f . m o d _ i d = r s . m o d _ i d 
 
                                         a n d       m o d . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       m o d . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       m o d i f . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       m o d i f . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         )   q u e r y ; 
 
 
 
                                         i f   n u m M o d i f i c a   i s   n u l l   t h e n 
 
                                           n u m M o d i f i c a : = 0 ; 
 
                                         e n d   i f ; 
 
 
 
                                         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r 
 
                                                   | | ' .   A d e g u a m e n t o   i m p o r t o   A c c .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o : : v a r c h a r 
 
             	 	 	 	 	   | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o : : v a r c h a r | | ' .   I n s e r i m e n t o   m o v .   m o d i f i c a . ' ; 
 
                                         a t t o A m m I d : = n u l l ; 
 
                                         s e l e c t   r a t t o . a t t o a m m _ i d   i n t o   a t t o A m m I d 
 
                                         f r o m   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   r a t t o 
 
                                         w h e r e   r a t t o . m o v g e s t _ t s _ i d = m o v g e s t T s I d 
 
                                         a n d       r a t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                         a n d       r a t t o . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 	 	 	 	 i f   a t t o A m m I d   i s   n u l l   t h e n 
 
                                         	 c o d R e s u l t : = - 1 ; 
 
                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   l e t t u r a   a t t o   a m m i n i s t r a t i v o . ' ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   c o d R e s u l t   i s   n u l l   a n d   m o d i f i c a T i p o I d   i s   n u l l   t h e n 
 
                                         	 s e l e c t   t i p o . m o d _ t i p o _ i d   i n t o   m o d i f i c a T i p o I d 
 
                                                 f r o m   s i a c _ d _ m o d i f i c a _ t i p o   t i p o 
 
                                                 w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                                 a n d       t i p o . m o d _ t i p o _ c o d e = ' A L T ' ; 
 
                                                 i f   m o d i f i c a T i p o I d   i s   n u l l   t h e n 
 
                                                 	 c o d R e s u l t : = - 1 ; 
 
 	                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   l e t t u r a   m o d i f i c a   t i p o . ' ; 
 
                                                 e n d   i f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             m o d i f I d : = n u l l ; 
 
                                             i n s e r t   i n t o   s i a c _ t _ m o d i f i c a 
 
                                             ( 
 
                                                     m o d _ n u m , 
 
                                                     m o d _ d e s c , 
 
                                                     m o d _ d a t a , 
 
                                                     m o d _ t i p o _ i d , 
 
                                                     a t t o a m m _ i d , 
 
                                                     l o g i n _ o p e r a z i o n e , 
 
                                                     v a l i d i t a _ i n i z i o , 
 
                                                     e n t e _ p r o p r i e t a r i o _ i d 
 
                                             ) 
 
                                             v a l u e s 
 
                                             ( 
 
                                                     n u m M o d i f i c a + 1 , 
 
                                                     ' M o d i f i c a   a u t o m a t i c a   p e r   p r e d i s p o s i z i o n e   d i   i n c a s s o ' , 
 
                                                     d a t a E l a b o r a z i o n e , 
 
                                                     m o d i f i c a T i p o I d , 
 
                                                     a t t o A m m I d , 
 
                                                     l o g i n O p e r a z i o n e , 
 
                                                     c l o c k _ t i m e s t a m p ( ) , 
 
                                                     e n t e P r o p r i e t a r i o I d 
 
                                             ) 
 
                                             r e t u r n i n g   m o d _ i d   i n t o   m o d i f I d ; 
 
                                             i f   m o d i f I d   i s   n u l l   t h e n 
 
                                             	 c o d R e s u l t : = - 1 ; 
 
                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o   s i a c _ t _ m o d i f i c a . ' ; 
 
                                             e n d   i f ; 
 
 	 	 	 	 	 e n d   i f ; 
 
 
 
                                         i f   c o d R e s u l t   i s   n u l l   a n d   m o d i f S t a t o I d   i s   n u l l   t h e n 
 
 	                                         s e l e c t   s t a t o . m o d _ s t a t o _ i d   i n t o   m o d i f S t a t o I d 
 
                                                 f r o m   s i a c _ d _ m o d i f i c a _ s t a t o   s t a t o 
 
                                                 w h e r e   s t a t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                                                 a n d       s t a t o . m o d _ s t a t o _ c o d e = ' V ' ; 
 
                                                 i f   m o d i f S t a t o I d   i s   n u l l   t h e n 
 
                                                 	 c o d R e s u l t : = - 1 ; 
 
 	                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   l e t t u r a   s t a t o   m o d i f i c a . ' ; 
 
                                                 e n d   i f ; 
 
                                         e n d   i f ; 
 
                                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             m o d S t a t o R I d : = n u l l ; 
 
                                             i n s e r t   i n t o   s i a c _ r _ m o d i f i c a _ s t a t o 
 
                                             ( 
 
                                                     m o d _ i d , 
 
                                                     m o d _ s t a t o _ i d , 
 
                                                     v a l i d i t a _ i n i z i o , 
 
                                                     l o g i n _ o p e r a z i o n e , 
 
                                                     e n t e _ p r o p r i e t a r i o _ i d 
 
                                             ) 
 
                                             v a l u e s 
 
                                             ( 
 
                                                     m o d i f I d , 
 
                                                     m o d i f S t a t o I d , 
 
                                                     c l o c k _ t i m e s t a m p ( ) , 
 
                                                     l o g i n O p e r a z i o n e , 
 
                                                     e n t e P r o p r i e t a r i o I d 
 
                                             ) 
 
                                             r e t u r n i n g   m o d _ s t a t o _ r _ i d   i n t o   m o d S t a t o R I d ; 
 
                                             i f   m o d S t a t o R I d   i s     n u l l   t h e n 
 
                                             	 c o d R e s u l t : = - 1 ; 
 
                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o   s i a c _ r _ m o d i f i c a _ s t a t o . ' ; 
 
                                             e n d   i f ; 
 
                                         e n d   i f ; 
 
                                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             i n s e r t   i n t o   s i a c _ t _ m o v g e s t _ t s _ d e t _ m o d 
 
                                             ( 
 
                                                     m o d _ s t a t o _ r _ i d , 
 
                                                     m o v g e s t _ t s _ d e t _ i d , 
 
                                                     m o v g e s t _ t s _ i d , 
 
                                                     m o v g e s t _ t s _ d e t _ t i p o _ i d , 
 
                                                     m o v g e s t _ t s _ d e t _ i m p o r t o , 
 
                                                     v a l i d i t a _ i n i z i o , 
 
                                                     l o g i n _ o p e r a z i o n e , 
 
                                                     e n t e _ p r o p r i e t a r i o _ i d 
 
                                             ) 
 
                                             s e l e c t   m o d S t a t o R I d , 
 
                                                           d e t . m o v g e s t _ t s _ d e t _ i d , 
 
                                                           d e t . m o v g e s t _ t s _ i d , 
 
                                                           d e t . m o v g e s t _ t s _ d e t _ t i p o _ i d , 
 
                                                           p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o - d i s p A c c e r t a m e n t o , 
 
                                                           c l o c k _ t i m e s t a m p ( ) , 
 
                                                           l o g i n O p e r a z i o n e , 
 
                                                           d e t . e n t e _ p r o p r i e t a r i o _ i d 
 
                                             f r o m   s i a c _ t _ m o v g e s t _ t s _ d e t   d e t 
 
                                             w h e r e   d e t . m o v g e s t _ t s _ i d = m o v g e s t T s I d 
 
                                             a n d       d e t . m o v g e s t _ t s _ d e t _ t i p o _ i d = m o v g e s t T s D e t T i p o I d 
 
                                             r e t u r n i n g   m o v g e s t _ t s _ d e t _ m o d _ i d   i n t o   c o d R e s u l t ; 
 
                                             i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             	 c o d R e s u l t : = - 1 ; 
 
                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o   s i a c _ t _ m o v g e s t _ t s _ d e t _ m o d . ' ; 
 
                                             e l s e 
 
                                                 c o d R e s u l t : = n u l l ; 
 
                                             e n d   i f ; 
 
                                 	 e n d   i f ; 
 
 
 
                                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                       | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                       | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                       | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r 
 
                                                       | | ' .   A d e g u a m e n t o   i m p o r t o   A c c .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o : : v a r c h a r 
 
                                                       | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o : : v a r c h a r | | ' . ' ; 
 
                                             u p d a t e   s i a c _ t _ m o v g e s t _ t s _ d e t   d e t 
 
                                             s e t         m o v g e s t _ t s _ d e t _ i m p o r t o = d e t . m o v g e s t _ t s _ d e t _ i m p o r t o + 
 
                                                                                                         ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o - d i s p A c c e r t a m e n t o ) , 
 
                                                           d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                                           l o g i n _ o p e r a z i o n e = d e t . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                                             w h e r e   d e t . m o v g e s t _ t s _ i d = m o v g e s t T s I d 
 
                                             a n d       d e t . m o v g e s t _ t s _ d e t _ t i p o _ i d = m o v g e s t T s D e t T i p o I d 
 
                                             a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                             a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , d e t . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( d e t . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                                             r e t u r n i n g   d e t . m o v g e s t _ t s _ d e t _ i d   i n t o   c o d R e s u l t ; 
 
                                             i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             	 c o d R e s u l t : = - 1 ; 
 
                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   a g g i o r n a m e n t o   s i a c _ t _ m o v g e s t _ t s _ d e t . ' ; 
 
                                             e l s e   c o d R e s u l t : = n u l l ; 
 
                                             e n d   i f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                       | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                       | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                       | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r 
 
                                                       | | ' .   A d e g u a m e n t o   i m p o r t o   A c c .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o : : v a r c h a r 
 
                                                       | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o : : v a r c h a r | | ' .   I n s e r i m e n t o   p a g o p a _ t _ m o d i f i c a _ e l a b . ' ; 
 
                                             i n s e r t   i n t o   p a g o p a _ t _ m o d i f i c a _ e l a b 
 
                                             ( 
 
                                                     p a g o p a _ m o d i f i c a _ e l a b _ i m p o r t o , 
 
                                                     p a g o p a _ e l a b _ i d , 
 
                                                     s u b d o c _ i d , 
 
                                                     m o d _ i d , 
 
                                                     m o v g e s t _ t s _ i d , 
 
                                                     v a l i d i t a _ i n i z i o , 
 
                                                     l o g i n _ o p e r a z i o n e , 
 
                                                     e n t e _ p r o p r i e t a r i o _ i d 
 
                                             ) 
 
                                             v a l u e s 
 
                                             ( 
 
                                                     p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o - d i s p A c c e r t a m e n t o , 
 
                                                     f i l e P a g o P a E l a b I d , 
 
                                                     s u b D o c I d , 
 
                                                     m o d i f I d , 
 
                                                     m o v g e s t T s I d , 
 
                                                     c l o c k _ t i m e s t a m p ( ) , 
 
                                                     l o g i n O p e r a z i o n e , 
 
                                                     e n t e P r o p r i e t a r i o I d 
 
                                             ) 
 
                                             r e t u r n i n g   p a g o p a _ m o d i f i c a _ e l a b _ i d   i n t o   c o d R e s u l t ; 
 
                                             i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                             	 c o d R e s u l t : = - 1 ; 
 
                                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o   p a g o p a _ t _ m o d i f i c a _ e l a b . ' ; 
 
                                             e l s e   c o d R e s u l t : = n u l l ; 
 
                                             e n d   i f ; 
 
                                         e n d   i f ; 
 
 
 
                                         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                                                 - - b E r r o r e : = t r u e ; 
 
                                                 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 1 ; 
 
                                         	 s t r M e s s a g g i o B c k : = s t r M e s s a g g i o | | '   P A G O P A _ E R R _ 3 1 = ' | | P A G O P A _ E R R _ 3 1 | | '   . ' ; 
 
 - -                                                 r a i s e   n o t i c e   ' % ' ,   s t r M e s s a g g i o B c k ; 
 
                                                 s t r M e s s a g g i o : = '   ' ; 
 
                                                 r a i s e   e x c e p t i o n   ' % ' ,   s t r M e s s a g g i o B c k ; 
 
                                         e n d   i f ; 
 
                                           - -   1 1 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0   -   i n s e r i m e n t o   m o v i m e n t o   d i   m o d i f i c a   a c c   a u t o m a t i c o 
 
                                 e n d   i f ; 
 
                         e l s e 
 
                         	 b E r r o r e : = t r u e ; 
 
                       	 	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 1 ; 
 
                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A c c .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o : : v a r c h a r 
 
                         	 	 	 	 	 	     | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o : : v a r c h a r | | '   e r r o r e . ' ; 
 
 	                         c o n t i n u e ; 
 
                         e n d   i f ; 
 
                 e l s e 
 
                         b E r r o r e : = t r u e ; 
 
                         p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 1 ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A c c .   ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o : : v a r c h a r 
 
                         	 	 	 	 	 	     | | ' / ' | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o : : v a r c h a r | | '   n o n   e s i s t e n t e . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; 
 
 
 
 
 
 	 	 c o d R e s u l t : = n u l l ; 
 
       	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   m o v g e s t _ t s _ i d = ' | | m o v g e s t T s I d : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' ; 
 
 	 	 - -   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
                 i n s e r t   i n t o   s i a c _ r _ s u b d o c _ m o v g e s t _ t s 
 
                 ( 
 
                 	 s u b d o c _ i d , 
 
                         m o v g e s t _ t s _ i d , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ O p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                               s u b d o c I d , 
 
                               m o v g e s t T s I d , 
 
                               c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n O p e r a z i o n e , 
 
                               e n t e P r o p r i e t a r i o I d 
 
                 ) 
 
 	 	 r e t u r n i n g   s u b d o c _ m o v g e s t _ t s _ i d   i n t o   c o d R e s u l t ; 
 
 	 	 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; 
 
 	 	 s u b d o c M o v g e s t T s I d : =     c o d R e s u l t ; 
 
 - -                 r a i s e   n o t i c e   ' s u b d o c M o v g e s t T s I d = % ' , s u b d o c M o v g e s t T s I d ; 
 
 
 
                 - -   s i a c - 6 7 2 0   3 0 . 0 5 . 2 0 1 9   -   p e r   i   c o r r i s p e t t i v i   n o n   c o l l e g a r e   a t t o _ a m m 
 
                 i f   p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ c o d e ! = D O C _ T I P O _ C O R     t h e n 
 
 
 
                     - -   s i a c _ r _ s u b d o c _ a t t o _ a m m 
 
                     c o d R e s u l t : = n u l l ; 
 
                     s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                       | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                       | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                       | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ a t t o _ a m m ] . ' ; 
 
                     i n s e r t   i n t o   s i a c _ r _ s u b d o c _ a t t o _ a m m 
 
                     ( 
 
                             s u b d o c _ i d , 
 
                             a t t o a m m _ i d , 
 
                             v a l i d i t a _ i n i z i o , 
 
                             l o g i n _ o p e r a z i o n e , 
 
                             e n t e _ p r o p r i e t a r i o _ i d 
 
                     ) 
 
                     s e l e c t   s u b d o c I d , 
 
                                   a t t o . a t t o a m m _ i d , 
 
                                   c l o c k _ t i m e s t a m p ( ) , 
 
                                   l o g i n O p e r a z i o n e , 
 
                                   a t t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                     f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r t s ,   s i a c _ r _ m o v g e s t _ t s _ a t t o _ a m m   a t t o 
 
                     w h e r e   r t s . s u b d o c _ m o v g e s t _ t s _ i d = s u b d o c M o v g e s t T s I d 
 
                     a n d       a t t o . m o v g e s t _ t s _ i d = r t s . m o v g e s t _ t s _ i d 
 
                     a n d       a t t o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , a t t o . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( a t t o . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     r e t u r n i n g   s u b d o c _ a t t o _ a m m _ i d   i n t o   c o d R e s u l t ; 
 
                     i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                             b E r r o r e : = t r u e ; 
 
                             s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                             c o n t i n u e ; 
 
                     e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 	 	 - -   c o n t r o l l o   e s i s t e n z a   e   s f o n d a m e n t o   d i s p .   p r o v v i s o r i o 
 
                 c o d R e s u l t : = n u l l ; 
 
                 p r o v v i s o r i o I d : = n u l l ; 
 
                 d i s p P r o v v i s o r i o C a s s a : = n u l l ; 
 
                 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ p r o v _ c a s s a ] . ' ; 
 
                 s e l e c t   p r o v . p r o v c _ i d   i n t o   p r o v v i s o r i o I d 
 
                 f r o m   s i a c _ t _ p r o v _ c a s s a   p r o v 
 
                 w h e r e   p r o v . p r o v c _ t i p o _ i d = p r o v v i s o r i o T i p o I d 
 
                 a n d       p r o v . p r o v c _ a n n o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                 a n d       p r o v . p r o v c _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                 a n d       p r o v . p r o v c _ d a t a _ a n n u l l a m e n t o   i s   n u l l 
 
                 a n d       p r o v . p r o v c _ d a t a _ r e g o l a r i z z a z i o n e   i s   n u l l 
 
                 a n d       p r o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , p r o v . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( p r o v . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) ; 
 
 - -                 r a i s e   n o t i c e   ' p r o v v i s o r i o I d = % ' , p r o v v i s o r i o I d ; 
 
 
 
                 i f   p r o v v i s o r i o I d   i s   n o t   n u l l   t h e n 
 
                 	 s e l e c t   1   i n t o   c o d R e s u l t 
 
                         f r o m   s i a c _ r _ o r d i n a t i v o _ p r o v _ c a s s a   r 
 
                         w h e r e   r . p r o v c _ i d = p r o v v i s o r i o I d 
 
                         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         	 s e l e c t   1   i n t o   c o d R e s u l t 
 
 	                         f r o m   s i a c _ r _ s u b d o c _ p r o v _ c a s s a   r 
 
         	                 w h e r e   r . p r o v c _ i d = p r o v v i s o r i o I d 
 
                                 a n d       r . l o g i n _ o p e r a z i o n e   n o t   l i k e   ' % @ P A G O P A - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r | | ' % ' 
 
                 	         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         	 a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                         e n d   i f ; 
 
                         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                         	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 9 ; 
 
 	                         b E r r o r e : = t r u e ; 
 
                                 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   P r o v .   ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | '   r e g o l a r i z z a t o . ' ; 
 
               	 	         c o n t i n u e ; 
 
                         e n d   i f ; 
 
                 e n d   i f ; 
 
                 i f   p r o v v i s o r i o I d   i s   n o t   n u l l   t h e n 
 
                       s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ p r o v _ c a s s a ]   p r o v c _ i d = ' 
 
                                                   | | p r o v v i s o r i o I d : : V A R C H A R | | ' .   V e r i f i c a   d i s p o n i b i l i t a ' ' . ' ; 
 
 	 	 	 s e l e c t   *   i n t o   d i s p P r o v v i s o r i o C a s s a 
 
                         f r o m   f n c _ s i a c _ d a r e g o l a r i z z a r e p r o v v i s o r i o ( p r o v v i s o r i o I d )   d i s p o n i b i l i t a ; 
 
 - -                         r a i s e   n o t i c e   ' d i s p P r o v v i s o r i o C a s s a = % ' , d i s p P r o v v i s o r i o C a s s a ; 
 
 - -                         r a i s e   n o t i c e   ' p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o = % ' , p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o ; 
 
 
 
                         i f   d i s p P r o v v i s o r i o C a s s a   i s   n o t   n u l l   t h e n 
 
                         	 i f   d i s p P r o v v i s o r i o C a s s a - p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o < 0   t h e n 
 
                                 	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 3 ; 
 
 	 	                         b E r r o r e : = t r u e ; 
 
                                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   P r o v .   ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | '   d i s p .   i n s u f f i c i e n t e . ' ; 
 
                 	 	         c o n t i n u e ; 
 
                                 e n d   i f ; 
 
                         e l s e 
 
                         	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 2 ; 
 
 	                         b E r r o r e : = t r u e ; 
 
                               s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   P r o v .   ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | '   E r r o r e . ' ; 
 
 
 
         	                 c o n t i n u e ; 
 
                         e n d   i f ; 
 
                 e l s e 
 
                 	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 2 ; 
 
                         b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   P r o v .   ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' 
 
                                                     | | p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | '   n o n   e s i s t e n t e . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; 
 
 
 
 
 
 	 	 c o d R e s u l t : = n u l l ; 
 
       	 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   d o c u m e n t o   n u m e r o = ' | | ( d n u m Q u o t e + 1 ) : : v a r c h a r | | '   [ s i a c _ r _ s u b d o c _ p r o v _ c a s s a ]   p r o v c _ i d = ' 
 
                                                   | | p r o v v i s o r i o I d : : v a r c h a r | | ' . ' ; 
 
 	 	 - -   s i a c _ r _ s u b d o c _ p r o v _ c a s s a 
 
                 i n s e r t   i n t o   s i a c _ r _ s u b d o c _ p r o v _ c a s s a 
 
                 ( 
 
                 	 s u b d o c _ i d , 
 
                         p r o v c _ i d , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                 ) 
 
                 V A L U E S 
 
                 ( 
 
                               s u b d o c I d , 
 
                               p r o v v i s o r i o I d , 
 
                               c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n O p e r a z i o n e | | ' @ P A G O P A - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r , 
 
                               e n t e P r o p r i e t a r i o I d 
 
                 ) 
 
                 r e t u r n i n g   s u b d o c _ p r o v c _ i d   i n t o   c o d R e s u l t ; 
 
 - - -                 r a i s e   n o t i c e   ' s u b d o c _ p r o v c _ i d = % ' , c o d R e s u l t ; 
 
 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                 	 b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   i n s e r i m e n t o . ' ; 
 
                         c o n t i n u e ; 
 
                 e n d     i f ; 
 
 
 
 	 	 c o d R e s u l t : = n u l l ; 
 
                 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   p e r   s u b d o c _ i d . ' ; 
 
                 - -   a g g i o r n a r e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                 u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c U P D 
 
                 s e t         p a g o p a _ r i c _ d o c _ s u b d o c _ i d = s u b d o c I d , 
 
 	 	               p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' S ' , 
 
                               p a g o p a _ r i c _ e r r o r e _ i d = n u l l , 
 
                               p a g o p a _ r i c _ d o c _ m o v g e s t _ t s _ i d = m o v g e s t T s I d , 
 
                               p a g o p a _ r i c _ d o c _ p r o v c _ i d = p r o v v i s o r i o I d , 
 
                               d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n _ o p e r a z i o n e = d o c U P D . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
                 f r o m 
 
                 ( 
 
                   w i t h 
 
                     p a g o p a   a s 
 
                     ( 
 
                         s e l e c t     d o c . p a g o p a _ r i c _ d o c _ i d , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f 
 
                     	 f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         w h e r e     f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
       	                 a n d         d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 	 	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ i d   - -   3 0 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) ) 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ t e m a t i c a , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) ) 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e = p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) ) 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ c o d e 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) ) 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ r i c _ f l u s s o _ i d = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ i d 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n o m e _ m i t t e n t e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
         	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' N ' 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
           	         a n d         d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
           	 	 a n d       n o t   e x i s t s   - -   t u t t i   r e c o r d   d i   u n   f l u s s o   d a   e l a b o r a r e   e   s e n z a   s c a r t i   o   e r r o r i 
 
       	 	         ( 
 
 	 	           s e l e c t   1 
 
 	 	           f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
 	 	           w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 	 	           a n d       d o c 1 . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   n o t   i n   ( ' N ' , ' S ' ) 
 
 	 	           a n d       d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         ) 
 
 	 	         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	           	 a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) , 
 
                     a c c e r t a m e n t i   a s 
 
                     ( 
 
                     s e l e c t   t s . m o v g e s t _ t s _ i d ,   r s o g . s o g g e t t o _ i d 
 
                     f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , 
 
                               s i a c _ r _ m o v g e s t _ t s _ s o g   r s o g 
 
                     w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
                     a n d       m o v . m o v g e s t _ t i p o _ i d = m o v g e s t T i p o I d 
 
                     a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                     a n d       t s . m o v g e s t _ t s _ t i p o _ i d = m o v g e s t T s T i p o I d 
 
                     a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       r s . m o v g e s t _ s t a t o _ i d = m o v g e s t S t a t o I d 
 
                     a n d       r s o g . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
                     a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                     a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , m o v . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( m o v . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , t s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( t s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) , 
 
                     s o g   a s 
 
                     ( 
 
                     s e l e c t   s o g . s o g g e t t o _ i d ,   s o g . s o g g e t t o _ c o d e ,   s o g . s o g g e t t o _ d e s c 
 
                     f r o m   s i a c _ t _ s o g g e t t o   s o g 
 
                     w h e r e   s o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) 
 
                     s e l e c t   p a g o p a . p a g o p a _ r i c _ d o c _ i d , 
 
                                   ( c a s e   w h e n   s 1 . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   s 1 . s o g g e t t o _ i d   e l s e   s 2 . s o g g e t t o _ i d   e n d   )   p a g o p a _ s o g g e t t o _ i d 
 
                     f r o m   p a g o p a   l e f t   j o i n   s o g   s 1   o n   ( p a g o p a . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f = s 1 . s o g g e t t o _ c o d e ) , 
 
                               a c c e r t a m e n t i   j o i n   s o g   s 2   o n   ( a c c e r t a m e n t i . s o g g e t t o _ i d = s 2 . s o g g e t t o _ i d ) 
 
                 )   Q U E R Y 
 
                 w h e r e   d o c U P D . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                 a n d       d o c U P D . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' N ' 
 
                 a n d       d o c U P D . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
                 a n d       d o c U P D . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
                 a n d       d o c U P D . p a g o p a _ r i c _ d o c _ i d = Q U E R Y . p a g o p a _ r i c _ d o c _ i d 
 
                 a n d       Q U E R Y . p a g o p a _ s o g g e t t o _ i d = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o g g e t t o _ i d 
 
                 a n d       d o c U P D . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 a n d       d o c U P D . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 - - 	 	 r a i s e   n o t i c e   ' A g g i o r n a t i   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c = % ' , c o d R e s u l t ; 
 
 	 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0   t h e n 
 
                         r a i s e   e x c e p t i o n   '   E r r o r e   i n   a g g i o r n a m e n t o . ' ; 
 
                 e n d   i f ; 
 
 
 
 	 	 s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
 
 
                 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e   p e r   s u b d o c _ i d . ' ; 
 
 	 	 c o d R e s u l t : = n u l l ; 
 
                 - -   a g g i o r n a r e   p a g o p a _ t _ r i c o n c i l i a z i o n e 
 
                 u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                 s e t         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' S ' , 
 
 	 	 	       p a g o p a _ r i c _ e r r o r e _ i d = n u l l , 
 
                               d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
 	 	 f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                 w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                 a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                 a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d = s u b d o c I d 
 
                 a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
                 a n d       s p l i t _ p a r t ( d o c . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' ,   2 ) : : i n t e g e r = f i l e P a g o P a E l a b I d 
 
                 a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d ; 
 
                 G E T   D I A G N O S T I C S   c o d R e s u l t   =   R O W _ C O U N T ; 
 
 - -       	 	 r a i s e   n o t i c e   ' A g g i o r n a t i   p a g o p a _ t _ r i c o n c i l i a z i o n e = % ' , c o d R e s u l t ; 
 
 
 
 - -                 r e t u r n i n g   r i c . p a g o p a _ r i c _ i d   i n t o   c o d R e s u l t ; 
 
 	 	 i f   c o a l e s c e ( c o d R e s u l t , 0 ) = 0   t h e n 
 
 	                 b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   E r r o r e   i n   a g g i o r n a m e n t o . ' ; 
 
                         s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                         i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                         ( 
 
                         p a g o p a _ e l a b _ i d , 
 
                         p a g o p a _ e l a b _ f i l e _ i d , 
 
                         p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         d a t a _ c r e a z i o n e 
 
                         ) 
 
                         v a l u e s 
 
                         ( 
 
                         f i l e P a g o P a E l a b I d , 
 
                         n u l l , 
 
                         s t r M e s s a g g i o L o g , 
 
                         e n t e P r o p r i e t a r i o I d , 
 
                         l o g i n O p e r a z i o n e , 
 
                         c l o c k _ t i m e s t a m p ( ) 
 
                         ) ; 
 
 
 
 
 
                         c o n t i n u e ; 
 
                 e n d   i f ; 
 
 
 
 	 	 d n u m Q u o t e : = d n u m Q u o t e + 1 ; 
 
                 d D o c I m p o r t o : = d D o c I m p o r t o + p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ i m p o r t o ; 
 
 
 
               e n d   l o o p ; 
 
 
 
 	       i f   d n u m Q u o t e > 0   a n d   b E r r o r e = f a l s e   t h e n 
 
                 - -   s i a c _ t _ s u b d o c _ n u m 
 
                 c o d R e s u l t : = n u l l ; 
 
                 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   n u m e r o   q u o t e   [ s i a c _ t _ s u b d o c _ n u m ] . ' ; 
 
   	         i n s e r t   i n t o   s i a c _ t _ s u b d o c _ n u m 
 
                 ( 
 
                   d o c _ i d , 
 
                   s u b d o c _ n u m e r o , 
 
                   v a l i d i t a _ i n i z i o , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                   d o c I d , 
 
                   d n u m Q u o t e , 
 
                   c l o c k _ t i m e s t a m p ( ) , 
 
                   l o g i n O p e r a z i o n e , 
 
                   e n t e P r o p r i e t a r i o I d 
 
                 ) 
 
                 r e t u r n i n g   s u b d o c _ n u m _ i d   i n t o   c o d R e s u l t ; 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                 	 b E r r o r e : = t r u e ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i m e n t o   n o n   r i u s c i t o . ' ; 
 
                 e n d   i f ; 
 
 
 
 	 	 i f   b E r r o r e   = f a l s e   t h e n 
 
                 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   A g g i o r n a m e n t o   i m p o r t o   d o c u m e n t o . ' ; 
 
                 	 u p d a t e   s i a c _ t _ d o c   d o c 
 
                         s e t         d o c _ i m p o r t o = d D o c I m p o r t o 
 
                         w h e r e   d o c . d o c _ i d = d o c I d 
 
                         r e t u r n i n g   d o c . d o c _ i d   i n t o   c o d R e s u l t ; 
 
                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         	 b E r r o r e : = t r u e ; 
 
                         	 s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   A g g i o r n a m e n t o   n o n   r i u s c i t o . ' ; 
 
                         e n d   i f ; 
 
                 e n d   i f ; 
 
               e l s e 
 
                 - -   n o n   h a   i n s e r i t o   q u o t e 
 
                 i f   b E r r o r e = f a l s e     t h e n 
 
                 	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d o c u m e n t o   p e r   s o g g e t t o = ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ c o d e - - | | ' - ' | | p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ d e s c 
 
                                                   | | ' .   V o c e   ' | | p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e - - | | ' - ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , '   '   ) 
 
                                                   | | ' .   S t r u t t u r a   a m m i n i s t r a t i v a   ' | | c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , '   ' ) 
 
                                                   | | ' .   I n s e r i m e n t o   q u o t e   n o n   e f f e t t u a t o . ' ; 
 
                         b E r r o r e : = t r u e ; 
 
                 e n d   i f ; 
 
               e n d   i f ; 
 
 
 
 
 
 
 
 	       i f   b E r r o r e = t r u e   t h e n 
 
 
 
         	   s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
                   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 - -                                     r a i s e   n o t i c e   ' p a g o P a C o d e E r r = % ' , p a g o P a C o d e E r r ; 
 
 
 
 	 	   i f   p a g o P a C o d e E r r   i s   n u l l   t h e n 
 
                   	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 0 ; 
 
                   e n d   i f ; 
 
 
 
                   - -   p u l i z i a   d e l l e   t a b e l l a   p a g o p a _ t _ r i c o n c i l i a z i o n e 
 
 
 
                   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ p a g o p a _ t _ r i c o n c i l i a z i o n e   S ] . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
     	 	   u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                   s e t         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
     	 	 	         p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                 d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                 l o g i n _ o p e r a z i o n e = s p l i t _ p a r t ( r i c . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r ,   1 ) | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
       	           f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c , 
 
                             p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e ,   s i a c _ t _ s u b d o c   s u b 
 
                   w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                   a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                   a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d = s u b . s u b d o c _ i d 
 
                   a n d       s u b . d o c _ i d = d o c I d 
 
                   a n d       d o c . l o g i n _ o p e r a z i o n e   l i k e   ' % @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r | | ' % ' 
 
                   a n d       s p l i t _ p a r t ( d o c . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' ,   2 ) : : i n t e g e r = f i l e P a g o P a E l a b I d 
 
                   a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
                   a n d       e x i s t s 
 
                   ( 
 
                   s e l e c t   1 
 
                   f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
                   w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                   a n d       d o c 1 . p a g o p a _ r i c _ d o c _ s u b d o c _ i d = s u b . s u b d o c _ i d 
 
                   a n d       d o c 1 . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
                   a n d       d o c 1 . l o g i n _ o p e r a z i o n e   l i k e   ' % @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r | | ' % ' 
 
                   a n d       d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
                   a n d       d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   ) 
 
                   a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = f l u s s o . e n t e _ p r o p r i e t a r i o _ i d 
 
                   a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e =   p a g o P a C o d e E r r 
 
                   a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
                   a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l 
 
                   a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 	   s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                   i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                   ( 
 
                       p a g o p a _ e l a b _ i d , 
 
                       p a g o p a _ e l a b _ f i l e _ i d , 
 
                       p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                       e n t e _ p r o p r i e t a r i o _ i d , 
 
                       l o g i n _ o p e r a z i o n e , 
 
                       d a t a _ c r e a z i o n e 
 
                   ) 
 
                   v a l u e s 
 
                   ( 
 
                       f i l e P a g o P a E l a b I d , 
 
                       n u l l , 
 
                       s t r M e s s a g g i o L o g , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c l o c k _ t i m e s t a m p ( ) 
 
                   ) ; 
 
 
 
                   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ p a g o p a _ t _ r i c o n c i l i a z i o n e   N ] . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 	 	   u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e     d o c U P D 
 
                   s e t         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
     	 	 	         p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                 d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                 l o g i n _ o p e r a z i o n e = s p l i t _ p a r t ( d o c U P D . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r ,   1 ) | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
                   f r o m 
 
                   ( 
 
 	 	     w i t h 
 
                     p a g o p a   a s 
 
                     ( 
 
                         s e l e c t     d o c . p a g o p a _ r i c _ d o c _ i d , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f , 
 
                                         d o c . p a g o p a _ r i c _ i d 
 
                     	 f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         w h e r e     f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
       	                 a n d         d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ i d   - -   3 0 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) ) 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ t e m a t i c a , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) ) 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e = p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) ) 
 
                 - -         a n d         d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ c o d e 
 
                 - -         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) = 
 
                 - -                       c o a l e s c e ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) ) 
 
                 - -         a n d         f l u s s o . p a g o p a _ e l a b _ r i c _ f l u s s o _ i d = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ i d 
 
                 - -         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n o m e _ m i t t e n t e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e 
 
                 - -         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                 - -         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                 - -       a n d         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
                 - - 	   a n d         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   =   ' N ' 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
 	 	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
           	 / * 	 a n d       n o t   e x i s t s   - -   t u t t i   r e c o r d   d i   u n   f l u s s o   d a   e l a b o r a r e   e   s e n z a   s c a r t i   o   e r r o r i 
 
       	 	         ( 
 
 	 	           s e l e c t   1 
 
 	 	           f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
 	 	           w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 	 	           a n d       d o c 1 . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   n o t   i n   ( ' N ' , ' S ' ) 
 
 	 	           a n d       d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         ) * / 
 
 	 	         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	           	 a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) , 
 
                     a c c e r t a m e n t i   a s 
 
                     ( 
 
                     s e l e c t   t s . m o v g e s t _ t s _ i d ,   r s o g . s o g g e t t o _ i d 
 
                     f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , 
 
                               s i a c _ r _ m o v g e s t _ t s _ s o g   r s o g 
 
                     w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
                     a n d       m o v . m o v g e s t _ t i p o _ i d = m o v g e s t T i p o I d 
 
                     a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                     a n d       t s . m o v g e s t _ t s _ t i p o _ i d = m o v g e s t T s T i p o I d 
 
                     a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       r s . m o v g e s t _ s t a t o _ i d = m o v g e s t S t a t o I d 
 
                     a n d       r s o g . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
             - -         a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
               - -       a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                     a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , m o v . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( m o v . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , t s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( t s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) , 
 
                     s o g   a s 
 
                     ( 
 
                     s e l e c t   s o g . s o g g e t t o _ i d ,   s o g . s o g g e t t o _ c o d e ,   s o g . s o g g e t t o _ d e s c 
 
                     f r o m   s i a c _ t _ s o g g e t t o   s o g 
 
                     w h e r e   s o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) 
 
                     s e l e c t   p a g o p a . p a g o p a _ r i c _ d o c _ i d , 
 
                                   ( c a s e   w h e n   s 1 . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   s 1 . s o g g e t t o _ i d   e l s e   s 2 . s o g g e t t o _ i d   e n d   )   p a g o p a _ s o g g e t t o _ i d , 
 
                                   p a g o p a . p a g o p a _ r i c _ i d 
 
                     f r o m   p a g o p a   l e f t   j o i n   s o g   s 1   o n   ( p a g o p a . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f = s 1 . s o g g e t t o _ c o d e ) , 
 
                               a c c e r t a m e n t i   j o i n   s o g   s 2   o n   ( a c c e r t a m e n t i . s o g g e t t o _ i d = s 2 . s o g g e t t o _ i d ) 
 
                   )   q u e r y , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e 
 
                   w h e r e   d o c U P D . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 - -                   a n d       d o c U P D . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' N ' 
 
                   a n d       d o c U P D . p a g o p a _ r i c _ i d = Q U E R Y . p a g o p a _ r i c _ i d 
 
                   a n d       Q U E R Y . p a g o p a _ s o g g e t t o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ i d 
 
                   a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = d o c U P D . e n t e _ p r o p r i e t a r i o _ i d 
 
                   a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e =   p a g o P a C o d e E r r 
 
                   a n d       d o c U P D . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       d o c U P D . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                   s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                   i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                   ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                   ) 
 
                   v a l u e s 
 
                   ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                   ) ; 
 
 
 
 
 
 
 
 
 
                   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   S ] . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
                   u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                   s e t         p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
 	 	 	         p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                 p a g o p a _ r i c _ d o c _ s u b d o c _ i d = n u l l , 
 
                                 p a g o p a _ r i c _ d o c _ m o v g e s t _ t s _ i d = n u l l , 
 
                                 p a g o p a _ r i c _ d o c _ p r o v c _ i d = n u l l , 
 
                                 d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                 l o g i n _ o p e r a z i o n e = s p l i t _ p a r t ( d o c . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r ,   1 ) | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
                   f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , 
 
                             p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e ,   s i a c _ t _ s u b d o c   s u b 
 
                   w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                   a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                   a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
                   a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d = s u b . s u b d o c _ i d 
 
                   a n d       s u b . d o c _ i d = d o c I d 
 
                   a n d       d o c . l o g i n _ o p e r a z i o n e   l i k e   ' % @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r | | ' % ' 
 
                   a n d       s p l i t _ p a r t ( d o c . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' ,   2 ) : : i n t e g e r = f i l e P a g o P a E l a b I d 
 
                   a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = f l u s s o . e n t e _ p r o p r i e t a r i o _ i d 
 
                   a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e =   p a g o P a C o d e E r r 
 
                   a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
                   a n d       s u b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       s u b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 	   s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                   i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                   ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                   ) 
 
                   v a l u e s 
 
                   ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                   ) ; 
 
 
 
 	           s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   N ] . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 	 	   u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c     d o c U P D 
 
                   s e t         p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
 	 	 	         p a g o p a _ r i c _ e r r o r e _ i d = e r r o r e . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                 p a g o p a _ r i c _ d o c _ s u b d o c _ i d = n u l l , 
 
                                 p a g o p a _ r i c _ d o c _ m o v g e s t _ t s _ i d = n u l l , 
 
                                 p a g o p a _ r i c _ d o c _ p r o v c _ i d = n u l l , 
 
                                 d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                 l o g i n _ o p e r a z i o n e = s p l i t _ p a r t ( d o c U P D . l o g i n _ o p e r a z i o n e , ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r ,   1 ) | | ' @ E L A B - ' | | f i l e P a g o P a E l a b I d : : v a r c h a r 
 
                   f r o m 
 
                   ( 
 
 	 	     w i t h 
 
                     p a g o p a   a s 
 
                     ( 
 
                         s e l e c t     d o c . p a g o p a _ r i c _ d o c _ i d , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
                                         d o c . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f , 
 
                                         d o c . p a g o p a _ r i c _ i d 
 
                     	 f r o m   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         w h e r e     f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
       	                 a n d         d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ d o c _ t i p o _ i d   - -   3 0 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ s t r _ a m m , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , ' ' ) ) 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) = 
 
                                       c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ t e m a t i c a , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , ' ' ) ) 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e = p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ c o d e 
 
                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) = c o a l e s c e ( p a g o P a F l u s s o R e c . p a g o p a _ v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , ' ' ) ) 
 
 - -                         a n d         d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ c o d e 
 
 - -                         a n d         c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) = 
 
 - -                                       c o a l e s c e ( p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ s o t t o v o c e _ d e s c , c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , ' ' ) ) 
 
 - -                         a n d         f l u s s o . p a g o p a _ e l a b _ r i c _ f l u s s o _ i d = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ i d 
 
 - -                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n o m e _ m i t t e n t e = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ f l u s s o _ n o m e _ m i t t e n t e 
 
 - -                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
 - -                         a n d         f l u s s o . p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
 - -                         a n d         d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
 - -         	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                         a n d         d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   =   ' N ' 
 
 	 	 	 a n d         d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
                         a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
     / *       	 	 a n d       n o t   e x i s t s   - -   t u t t i   r e c o r d   d i   u n   f l u s s o   d a   e l a b o r a r e   e   s e n z a   s c a r t i   o   e r r o r i 
 
       	 	         ( 
 
 	 	           s e l e c t   1 
 
 	 	           f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
 	 	           w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
 	 	           a n d       d o c 1 . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   n o t   i n   ( ' N ' , ' S ' ) 
 
 	 	           a n d       d o c 1 . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	           a n d       d o c 1 . v a l i d i t a _ f i n e   i s   n u l l 
 
 	 	         ) * / 
 
 	 	         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	           	 a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	 	         a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) , 
 
                     a c c e r t a m e n t i   a s 
 
                     ( 
 
                     s e l e c t   t s . m o v g e s t _ t s _ i d ,   r s o g . s o g g e t t o _ i d 
 
                     f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , 
 
                               s i a c _ r _ m o v g e s t _ t s _ s o g   r s o g 
 
                     w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
                     a n d       m o v . m o v g e s t _ t i p o _ i d = m o v g e s t T i p o I d 
 
                     a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                     a n d       t s . m o v g e s t _ t s _ t i p o _ i d = m o v g e s t T s T i p o I d 
 
                     a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       r s . m o v g e s t _ s t a t o _ i d = m o v g e s t S t a t o I d 
 
                     a n d       r s o g . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
 - -                     a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ a n n o _ a c c e r t a m e n t o 
 
 - -                     a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o Q u o t e R e c . p a g o p a _ n u m _ a c c e r t a m e n t o 
 
                     a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , m o v . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( m o v . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , t s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( t s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     a n d       r s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , r s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( r s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) , 
 
                     s o g   a s 
 
                     ( 
 
                     s e l e c t   s o g . s o g g e t t o _ i d ,   s o g . s o g g e t t o _ c o d e ,   s o g . s o g g e t t o _ d e s c 
 
                     f r o m   s i a c _ t _ s o g g e t t o   s o g 
 
                     w h e r e   s o g . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       s o g . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , s o g . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( s o g . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
                     ) 
 
                     s e l e c t   p a g o p a . p a g o p a _ r i c _ d o c _ i d , 
 
                                   ( c a s e   w h e n   s 1 . s o g g e t t o _ i d   i s   n o t   n u l l   t h e n   s 1 . s o g g e t t o _ i d   e l s e   s 2 . s o g g e t t o _ i d   e n d   )   p a g o p a _ s o g g e t t o _ i d , 
 
                                   p a g o p a . p a g o p a _ r i c _ i d 
 
                     f r o m   p a g o p a   l e f t   j o i n   s o g   s 1   o n   ( p a g o p a . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f = s 1 . s o g g e t t o _ c o d e ) , 
 
                               a c c e r t a m e n t i   j o i n   s o g   s 2   o n   ( a c c e r t a m e n t i . s o g g e t t o _ i d = s 2 . s o g g e t t o _ i d ) 
 
                   )   q u e r y , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r o r e 
 
                   w h e r e   d o c U P D . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
 - -                   a n d       d o c U P D . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' N ' 
 
                   a n d       d o c U P D . p a g o p a _ r i c _ d o c _ i d = Q U E R Y . p a g o p a _ r i c _ d o c _ i d 
 
                   a n d       Q U E R Y . p a g o p a _ s o g g e t t o _ i d = p a g o P a F l u s s o R e c . p a g o p a _ s o g g e t t o _ i d 
 
                   a n d       e r r o r e . e n t e _ p r o p r i e t a r i o _ i d = d o c U P D . e n t e _ p r o p r i e t a r i o _ i d 
 
                   a n d       e r r o r e . p a g o p a _ r i c _ e r r o r e _ c o d e =   p a g o P a C o d e E r r 
 
                   a n d       d o c U P D . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                   a n d       d o c U P D . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
     	 	   s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                   i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                   ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                   ) 
 
                   v a l u e s 
 
                   ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                   ) ; 
 
 
 
                   - -   1 1 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
                   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ p a g o p a _ t _ m o d i f i c a _ e l a b ] . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 	 	   u p d a t e   p a g o p a _ t _ m o d i f i c a _ e l a b   r 
 
                   s e t         p a g o p a _ m o d i f i c a _ e l a b _ n o t e = ' D O C U M E N T O   C A N C E L L A T O   I N   E S E G U I   P E R   p a g o P a C o d e E r r = ' | | p a g o P a C o d e E r r | | '   ' , 
 
                                 s u b d o c _ i d = n u l l 
 
                   f r o m   	 s i a c _ t _ s u b d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d   a n d   r . s u b d o c _ i d = d o c . s u b d o c _ i d ; 
 
 
 
                   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ s u b d o c _ m o v g e s t _ t s ] . ' | | s t r M e s s a g g i o B c k ; 
 
 - -                   r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
                   d e l e t e   f r o m   s i a c _ r _ s u b d o c _ m o v g e s t _ t s   r 
 
                   u s i n g   s i a c _ t _ s u b d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d   a n d   r . s u b d o c _ i d = d o c . s u b d o c _ i d ; 
 
 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ s u b d o c _ a t t r ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ s u b d o c _ a t t r   r 
 
                   u s i n g   s i a c _ t _ s u b d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d   a n d   r . s u b d o c _ i d = d o c . s u b d o c _ i d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ s u b d o c _ a t t o _ a m m ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ s u b d o c _ a t t o _ a m m   r 
 
                   u s i n g   s i a c _ t _ s u b d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d   a n d   r . s u b d o c _ i d = d o c . s u b d o c _ i d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ s u b d o c _ p r o v _ c a s s a ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ s u b d o c _ p r o v _ c a s s a   r 
 
                   u s i n g   s i a c _ t _ s u b d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d   a n d   r . s u b d o c _ i d = d o c . s u b d o c _ i d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ t _ s u b d o c ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ t _ s u b d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ d o c _ s o g ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ d o c _ s o g   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ d o c _ s t a t o ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ d o c _ s t a t o   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ d o c _ a t t r ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ d o c _ a t t r   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ r _ d o c _ c l a s s ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ r _ d o c _ c l a s s   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ t _ r e g i s t r o u n i c o _ d o c ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ t _ r e g i s t r o u n i c o _ d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ t _ s u b d o c _ n u m ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ t _ s u b d o c _ n u m   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 	 	   s t r M e s s a g g i o : = ' C a n c e l l a z i o n e   d a t i   d o c u m e n t o   i n s e r i t i   [ s i a c _ t _ d o c ] . ' | | s t r M e s s a g g i o B c k ; 
 
                   d e l e t e   f r o m   s i a c _ t _ d o c   d o c   w h e r e   d o c . d o c _ i d = d o c I d ; 
 
 
 
 	 	   s t r M e s s a g g i o L o g : = s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o | | '   -   C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i . ' ; 
 
                   i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                   ( 
 
                   p a g o p a _ e l a b _ i d , 
 
                   p a g o p a _ e l a b _ f i l e _ i d , 
 
                   p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   d a t a _ c r e a z i o n e 
 
                   ) 
 
                   v a l u e s 
 
                   ( 
 
                   f i l e P a g o P a E l a b I d , 
 
                   n u l l , 
 
                   s t r M e s s a g g i o L o g , 
 
                   e n t e P r o p r i e t a r i o I d , 
 
                   l o g i n O p e r a z i o n e , 
 
                   c l o c k _ t i m e s t a m p ( ) 
 
                   ) ; 
 
 
 
               e n d   i f ; 
 
 
 
 
 
     e n d   l o o p ; 
 
 
 
 
 
     s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i   -   F i n e   c i c l o   c a r i c a m e n t o   d o c u m e n t i   -   ' | | s t r M e s s a g g i o F i n a l e ; 
 
 - -     r a i s e   n o t i c e   ' s t r M e s s a g g i o L o g = % ' , s t r M e s s a g g i o L o g ; 
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
     - -   r i c h i a m a r e   f u n c t i o n   p e r   g e s t i r e   a n o m a l i e   e   e r r o r i   s u   p r o v v i s o r i   e   f l u s s i   i n   g e n e r a l e 
 
     - -   s u   e l a b o r a z i o n e 
 
     - -   c o n t r o l l a r e   o g n i   f l u s s o / p r o v v i s o r i o 
 
     s t r M e s s a g g i o : = ' C h i a m a t a   f n c . ' ; 
 
     s e l e c t   *   i n t o     f n c R e c 
 
     f r o m   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ e s e g u i _ c l e a n 
 
     ( 
 
         f i l e P a g o P a E l a b I d , 
 
         a n n o B i l a n c i o E l a b , 
 
         e n t e P r o p r i e t a r i o I d , 
 
         l o g i n O p e r a z i o n e , 
 
         d a t a E l a b o r a z i o n e 
 
     ) ; 
 
     i f   f n c R e c . c o d i c e R i s u l t a t o = 0   t h e n 
 
         i f   f n c R e c . p a g o p a B c k S u b d o c = t r u e   t h e n 
 
         	 p a g o P a C o d e E r r : = P A G O P A _ E R R _ 3 6 ; 
 
         e n d   i f ; 
 
     e l s e 
 
     	 r a i s e   e x c e p t i o n   ' % ' , f n c R e c . m e s s a g g i o r i s u l t a t o ; 
 
     e n d   i f ; 
 
 
 
     - -   a g g i o r n a r e   s i a c _ t _ r e g i s t r o u n i c o _ d o c _ n u m 
 
     c o d R e s u l t : = n u l l ; 
 
     s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   n u m e r a z i o n e   s u   s i a c _ t _ r e g i s t r o u n i c o _ d o c _ n u m . ' ; 
 
     u p d a t e   s i a c _ t _ r e g i s t r o u n i c o _ d o c _ n u m   n u m 
 
     s e t         r u d o c _ r e g i s t r a z i o n e _ n u m e r o =   c o a l e s c e ( Q U E R Y . r u d o c _ r e g i s t r a z i o n e _ n u m e r o , 0 ) , 
 
                   d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                   l o g i n _ o p e r a z i o n e = n u m . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
     f r o m 
 
     ( 
 
       s e l e c t   m a x ( d o c . r u d o c _ r e g i s t r a z i o n e _ n u m e r o : : i n t e g e r )   r u d o c _ r e g i s t r a z i o n e _ n u m e r o 
 
       f r o m     s i a c _ t _ r e g i s t r o u n i c o _ d o c   d o c 
 
       w h e r e   d o c . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
       a n d       d o c . r u d o c _ r e g i s t r a z i o n e _ a n n o : : i n t e g e r = a n n o B i l a n c i o 
 
       a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
       a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , d o c . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( d o c . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) 
 
     )   Q U E R Y 
 
     w h e r e   n u m . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
     a n d       n u m . r u d o c _ r e g i s t r a z i o n e _ a n n o = a n n o B i l a n c i o 
 
     a n d       n u m . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) > = d a t e _ t r u n c ( ' D A Y ' , n u m . v a l i d i t a _ i n i z i o )   a n d   d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) < = d a t e _ t r u n c ( ' D A Y ' , c o a l e s c e ( n u m . v a l i d i t a _ f i n e , d a t e _ t r u n c ( ' D A Y ' , n o w ( ) ) ) ) ; 
 
   - -   r e t u r n i n g   n u m . r u d o c _ n u m _ i d   i n t o   c o d R e s u l t ; 
 
     - - i f   c o d R e s u l t   i s   n u l l   t h e n 
 
     - - 	 r a i s e   e x c e p t i o n   ' E r r o r e   i n   f a s e   d i   a g g i o r n a m e n t o . ' ; 
 
     - - e n d   i f ; 
 
 
 
 
 
 
 
     - -   c h i u s u r a   d e l l a   e l a b o r a z i o n e ,   s i a c _ t _ f i l e   p e r   e r r o r e   i n   g e n e r a z i o n e   p e r   a g g i o r n a r e   p a g o p a _ r i c _ e r r o r e _ i d 
 
     i f   c o a l e s c e ( p a g o P a C o d e E r r , '   ' )   i n   ( P A G O P A _ E R R _ 3 0 , P A G O P A _ E R R _ 3 1 , P A G O P A _ E R R _ 3 2 , P A G O P A _ E R R _ 3 3 , P A G O P A _ E R R _ 3 6 , P A G O P A _ E R R _ 3 9 )   t h e n 
 
           s t r M e s s a g g i o : = '   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
 	   u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
           s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                         p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                         p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                         p a g o p a _ e l a b _ n o t e = e l a b . p a g o p a _ e l a b _ n o t e 
 
                         | | '   A G G I O R N A M E N T O   P E R   E R R . = ' | | ( c a s e   w h e n   p a g o P a C o d e E r r = P A G O P A _ E R R _ 3 6   t h e n   P A G O P A _ E R R _ 3 6   e l s e   P A G O P A _ E R R _ 3 0   e n d   ) : : v a r c h a r | | ' . ' 
 
           f r o m     p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
           w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
           a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = e l a b . e n t e _ p r o p r i e t a r i o _ i d 
 
           a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ E R _ S T 
 
           a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d 
 
           a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = ( c a s e   w h e n   p a g o P a C o d e E r r = P A G O P A _ E R R _ 3 6   t h e n   P A G O P A _ E R R _ 3 6   e l s e   P A G O P A _ E R R _ 3 0   e n d   ) 
 
           a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
           a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
 
 
         s t r M e s s a g g i o : = '   A g g i o r n a m e n t o   s i a c _ t _ f i l e _ p a g o p a . ' ; 
 
         u p d a t e   s i a c _ t _ f i l e _ p a g o p a   f i l e 
 
         s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                       f i l e _ p a g o p a _ s t a t o _ i d = s t a t o . f i l e _ p a g o p a _ s t a t o _ i d , 
 
                       f i l e _ p a g o p a _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                       f i l e _ p a g o p a _ n o t e = f i l e . f i l e _ p a g o p a _ n o t e 
 
                                         | | '   A G G I O R N A M E N T O   P E R   E R R . = ' | | ( c a s e   w h e n   p a g o P a C o d e E r r = P A G O P A _ E R R _ 3 6   t h e n   P A G O P A _ E R R _ 3 6   e l s e   P A G O P A _ E R R _ 3 0   e n d   ) : : v a r c h a r | | ' . ' , 
 
                       l o g i n _ o p e r a z i o n e = f i l e . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
         f r o m     p a g o p a _ r _ e l a b o r a z i o n e _ f i l e   r , 
 
                     s i a c _ d _ f i l e _ p a g o p a _ s t a t o   s t a t o , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
         w h e r e   r . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
         a n d       f i l e . f i l e _ p a g o p a _ i d = r . f i l e _ p a g o p a _ i d 
 
         a n d       s t a t o . e n t e _ p r o p r i e t a r i o _ i d = f i l e . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = ( c a s e   w h e n   p a g o P a C o d e E r r = P A G O P A _ E R R _ 3 6   t h e n   P A G O P A _ E R R _ 3 6   e l s e   P A G O P A _ E R R _ 3 0   e n d   ) 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
     e n d   i f ; 
 
 
 
     s t r M e s s a g g i o : = ' V e r i f i c a   d e t t a g l i o   e l a b o r a t i   p e r   c h i u s u r a   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
 - -     r a i s e   n o t i c e   ' s t r M e s s a g g i o = % ' , s t r M e s s a g g i o ; 
 
 
 
     c o d R e s u l t : = n u l l ; 
 
     s e l e c t   1   i n t o   c o d R e s u l t 
 
     f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c ,   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o 
 
     w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
     a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
     a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
     a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' S ' 
 
     a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
     a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
     - -   E L A B O R A T O _ K O _ S T   E L A B O R A T O _ O K _ S E 
 
     i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
     	     c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c ,   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o 
 
             w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   i n   ( ' X ' , ' E ' , ' N ' ) 
 
             a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
             - -   s e   c i   s o n o   S   e   X , E , N   K O 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                         p a g o P a C o d e E r r : = E L A B O R A T O _ K O _ S T ; 
 
             - -   s e   s i   s o n o   s o l o   S   O K 
 
             e l s e     p a g o P a C o d e E r r : = E L A B O R A T O _ O K _ S T ; 
 
             e n d   i f ; 
 
     e l s e   - -   s e   n o n   e s i s t e   n e a n c h e   u n   S   a l l o r a   e l a b o r a z i o n e   e r r a t a   o   s c a r t a t a 
 
 	     c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c ,   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o   f l u s s o 
 
             w h e r e   f l u s s o . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
             a n d       d o c . p a g o p a _ e l a b _ f l u s s o _ i d = f l u s s o . p a g o p a _ e l a b _ f l u s s o _ i d 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = f a l s e   - -   0 5 . 0 6 . 2 0 1 9   S I A C - 6 7 2 0 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' 
 
             a n d       f l u s s o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       f l u s s o . v a l i d i t a _ f i n e   i s   n u l l 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                         p a g o P a C o d e E r r : = E L A B O R A T O _ S C A R T A T O _ S T ; 
 
             e l s e     p a g o P a C o d e E r r : = E L A B O R A T O _ E R R A T O _ S T ; 
 
             e n d   i f ; 
 
     e n d   i f ; 
 
 
 
     s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e   i n   s t a t o = ' | | p a g o P a C o d e E r r | | ' . ' ; 
 
     s t r M e s s a g g i o F i n a l e : = ' C H I U S U R A   -   ' | | u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r M e s s a g g i o ) ; 
 
     u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
     s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
     	 	   v a l i d i t a _ f i n e = c l o c k _ t i m e s t a m p ( ) , 
 
                   p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                   p a g o p a _ e l a b _ n o t e = s t r M e s s a g g i o F i n a l e 
 
     f r o m     p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w 
 
     w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
     a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = e l a b . e n t e _ p r o p r i e t a r i o _ i d 
 
     a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = p a g o P a C o d e E r r 
 
     a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
     s t r M e s s a g g i o : = ' V e r i f i c a   d e t t a g l i o   e l a b o r a t i   p e r   c h i u s u r a   s i a c _ t _ f i l e _ p a g o p a . ' ; 
 
     f o r   e l a b R e c   i n 
 
     ( 
 
     s e l e c t   r . f i l e _ p a g o p a _ i d 
 
     f r o m   p a g o p a _ r _ e l a b o r a z i o n e _ f i l e   r 
 
     w h e r e   r . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
     a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
     a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
     o r d e r   b y   r . f i l e _ p a g o p a _ i d 
 
     ) 
 
     l o o p 
 
 
 
         - -   c h i u s u r a   p e r   s i a c _ t _ f i l e _ p a g o p a 
 
         - -   c a p i r e   s e   h o   c h i u s o   p e r   b e n e   p a g o p a _ t _ r i c o n c i l i a z i o n e 
 
         - -   s e   e s i s t o n o   S   O k   o   i n   c o r s o 
 
         - -         s e   e s i s t o n o   N   n o n   e l a b o r a t i     I N _ C O R S O   n o   c h i u s u r a 
 
         - -         s e   e s i s t o n o   X   s c a r t a t i   I N _ C O R S O _ S C   n o   c h i u s u r a 
 
         - -         s e   e s i s t o n o   E   e r r a t i       I N _ C O R S O _ E R   n o   c h i u s u r a 
 
         - -         s e   n o n   e s i s t o n o ! = S   F I N E   E L A B O R A T O _ O k   c o n   c h i u s u r a 
 
         - -   s e   n o n   e s i s t o n o   S ,   i n   c o r s o 
 
         - -         s e   e s i s t o n o   N   I N _ C O R S O   n o   c h i u s u r a 
 
         - -         s e   e s i s t o n o   X   s c a r t a t i   I N _ C O R S O _ S C   n o n   c h i u s u r a 
 
         - -         s e   e s i s t o n o   E   e r r a t i   I N _ C O R S O _ E R   n o n   c h i u s u r a 
 
         s t r M e s s a g g i o : = ' V e r i f i c a   d e t t a g l i o   e l a b o r a t i   p e r   c h i u s u r a   s i a c _ t _ f i l e _ p a g o p a   f i l e _ p a g o p a _ i d = ' | | e l a b R e c . f i l e _ p a g o p a _ i d : : v a r c h a r | | ' . ' ; 
 
         c o d R e s u l t : = n u l l ; 
 
         p a g o P a C o d e E r r : = n u l l ; 
 
         s e l e c t   1   i n t o   c o d R e s u l t 
 
         f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
         w h e r e     r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
         a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' S ' 
 
         a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
         i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' N ' 
 
     - -         a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ I N _ C O R S O _ S T ; 
 
             e n d   i f ; 
 
 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ I N _ C O R S O _ S C _ S T ; 
 
             e n d   i f ; 
 
 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' E ' 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ I N _ C O R S O _ E R _ S T ; 
 
             e n d   i f ; 
 
 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b ! = ' S ' 
 
         - -     a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ O K _ S T ; 
 
             e n d   i f ; 
 
 
 
         e l s e 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' N ' 
 
       - -       a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ I N _ C O R S O _ S T ; 
 
             e n d   i f ; 
 
 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ I N _ C O R S O _ S C _ S T ; 
 
             e n d   i f ; 
 
 
 
             c o d R e s u l t : = n u l l ; 
 
             s e l e c t   1   i n t o   c o d R e s u l t 
 
             f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
             w h e r e   r i c . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
             a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' E ' 
 
             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
             i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     p a g o P a C o d e E r r : = E L A B O R A T O _ I N _ C O R S O _ E R _ S T ; 
 
             e n d   i f ; 
 
 
 
         e n d   i f ; 
 
 
 
         i f   p a g o P a C o d e E r r   i s   n o t   n u l l   t h e n 
 
               s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   s i a c _ t _ f i l e _ p a g o p a   i n   s t a t o = ' | | p a g o P a C o d e E r r | | ' . ' ; 
 
               s t r M e s s a g g i o F i n a l e : = ' C H I U S U R A   -   ' | | u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r M e s s a g g i o ) ; 
 
               u p d a t e   s i a c _ t _ f i l e _ p a g o p a   f i l e 
 
               s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                             v a l i d i t a _ f i n e = ( c a s e   w h e n   p a g o P a C o d e E r r = E L A B O R A T O _ O K _ S T   t h e n   c l o c k _ t i m e s t a m p ( )   e l s e   n u l l   e n d ) , 
 
                             f i l e _ p a g o p a _ s t a t o _ i d = s t a t o . f i l e _ p a g o p a _ s t a t o _ i d , 
 
                             f i l e _ p a g o p a _ n o t e = f i l e . f i l e _ p a g o p a _ n o t e | | u p p e r ( s t r M e s s a g g i o F i n a l e ) , 
 
                             l o g i n _ o p e r a z i o n e = f i l e . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
               f r o m     s i a c _ d _ f i l e _ p a g o p a _ s t a t o   s t a t o , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
               w h e r e   f i l e . f i l e _ p a g o p a _ i d = e l a b R e c . f i l e _ p a g o p a _ i d 
 
               a n d       s t a t o . e n t e _ p r o p r i e t a r i o _ i d = f i l e . e n t e _ p r o p r i e t a r i o _ i d 
 
               a n d       s t a t o . f i l e _ p a g o p a _ s t a t o _ c o d e = p a g o P a C o d e E r r ; 
 
 
 
         e n d   i f ; 
 
 
 
     e n d   l o o p ; 
 
 
 
     m e s s a g g i o R i s u l t a t o : = ' O K   V E R I F I C A R E   S T A T O   E L A B .   -   ' | | u p p e r ( s t r M e s s a g g i o F i n a l e ) ; 
 
 - -   r a i s e   n o t i c e   ' m e s s a g g i o R i s u l t a t o = % ' , m e s s a g g i o R i s u l t a t o ; 
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