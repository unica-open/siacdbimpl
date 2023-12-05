/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- SIAC-8371 Sofia 29.11.2021 Inizio 
drop function if exists 
siac.fnc_pagopa_t_elaborazione_riconc_esegui 
(
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui (
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
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
    -- 18.01.2021 Sofia Jira SIAC-7962
    ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

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

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE
    
	-- 07.07.2021 Sofia jira SIAC-8221
    PAGOPA_ERR_52	CONSTANT  varchar :='52';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA ANNULLATO O CON DATA DI REGOLARIZZAZIONE
	
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

    -- 12.10.2021 Sofia JIRA SIAC-8371
	movgestTsDetTipoUId integer:=null;

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

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
    -- 06.02.2020 Sofia jira siac-7375
    docDataOperazione timestamp:=null;
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
    raise notice '2222%',strMessaggioLog;
    raise notice '2222-codResult- %',codResult;
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
    raise notice '2222strMessaggio  %',strMessaggio;
    raise notice '2222strMessaggio CodResult %',codResult;

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
 
   
    -- 12.10.2021 Sofia JIRA SIAC-8371
   	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo UTILIZZABILE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoUId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='U';
        if movgestTsDetTipoUId is null then
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
    raise notice '22229998@@%',strMessaggio;

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
         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
         raise notice '22229997@@%',strMessaggio;

	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     -- 18.01.2021 Sofia Jira SIAC-7962
--     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
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
    raise notice '22229996@@%',strMessaggio;

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
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
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
     /*and   prov.provc_data_annullamento is null -- 07.07.2021 Sofia Jira SIAC-8221 
     and   prov.provc_data_regolarizzazione is null*/
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
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

    -- 07.07.2021 Sofia Jira SIAC-8221 -- inizio 
	-- provvisorio di cassa esistente ma con data_annullamento o data_regolarizzazione impostate 
	if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_52||'.';
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_52 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   ( prov.provc_data_annullamento is not null  or prov.provc_data_regolarizzazione is not null )
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_52
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_52;
        strErrore:=' Provvisori di cassa annullati o regolarizzati [data impostata].';
     end if;
	 codResult:=null;
    end if;
    -- 07.07.2021 Sofia Jira SIAC-8221 -- fine 
	
    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
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
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
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
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     and   ambito1.ambito_id=sog1.ambito_id
     and   ambito1.ambito_code='AMBITO_FIN'
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
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
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
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and    ambito.ambito_id=sog.ambito_id
     and    ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog1.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
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
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

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
--          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
          login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
     raise notice 'strMessaggioStrErrore=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
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
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
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
      -- 10.05.2021 Sofia Jira SIAC-8167
      if pagoPaCodeErr=PAGOPA_ERR_7 then
      	codiceRisultato:=0;
      else
        codiceRisultato:=-1;
      end if;

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
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id,           -- siac-6720
          doc.pagopa_ric_doc_iuv     pagopa_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
          doc.pagopa_ric_doc_data_operazione pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
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
            doc.pagopa_ric_doc_tipo_id, -- siac-6720
            doc.pagopa_ric_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
            doc.pagopa_ric_doc_data_operazione -- 06.02.2020 Sofia siac-7375
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
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720
           pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
            pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
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
		docIUV:=null;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
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

         /* select distinct query.pagopa_ric_doc_iuv into docIUV
          from
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
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione e poi scarto
            /* and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )*/
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
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
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
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;*/

        -- 06.02.2020 Sofia jira siac-7375
        docIUV:=pagoPaFlussoRec.pagopa_doc_iuv;
        raise notice 'IUUUUUUUUUV docIUV=%',docIUV;
       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=pagoPaFlussoRec.pagopa_doc_data_operazione;
        raise notice 'IUUUUUUUUUV docDataOperazione=%',docDataOperazione;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
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
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
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

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'
                          ||lpad(extract ( month from dataElaborazione)::varchar,2,'0')
                          ||'-'||extract ( year from dataElaborazione)
                          -- ||' ' 20.04.2020 Sofia jira	SIAC-7586
                          ||' '||nProgressivoTemp::varchar;
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
	        pccuff_id,
            IUV, -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
            doc_data_operazione -- 06.02.2020 Sofia jira siac-7375
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
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
               null,
               docIUV,   -- 12.08.2019 Sofia SIAC-6978 - fine
               docDataOperazione -- 06.02.2020 Sofia jira siac-7375
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
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
                --clock_timestamp(), 06.07.2021 Sofia Jira SIAC-8277
                now(), -- 06.07.2021 Sofia Jira SIAC-8277
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
raise notice 'prima di quote berrore=%',berrore;
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
           and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                 coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
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
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
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
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
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
                          loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
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
                             loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
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
                             --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                             login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
					  --- 29.11.2021 Sofia JIRA SIAC-8371
					  if codResult is not null then 
					   codResult:=null;
					   update siac_t_movgest_ts_det det
                       set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                              data_modifica=clock_timestamp(),
                              --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                              login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                       where det.movgest_ts_id=movgestTsId
--                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                        -- 12.10.2021 Sofia JIRA SIAC-8371
                       and   det.movgest_ts_det_tipo_id=movgestTsDetTipoUId
                       and   det.data_cancellazione is null
                       and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                       returning det.movgest_ts_det_id into codResult;
					  end if;
					   --- 29.11.2021 Sofia JIRA SIAC-8371
					  
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
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
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
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


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
--               clock_timestamp(), 06.07.2021 Sofia Jira SIAC-8277
               now(), --06.07.2021 Sofia Jira SIAC-8277
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
--               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
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
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
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
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from --pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog ,-- 22.07.2019 siac-6963
               pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code)
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
--               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
		raise notice 'dnumQuote %',dnumQuote;
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
--                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
                --login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar      -- 04.02.2020 Sofia SIAC-7375
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
            and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                  coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
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
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
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
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
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
--                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar             -- 04.02.2020 Sofia SIAC-7375
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
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar          -- 04.02.2020 Sofia SIAC-7375
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
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
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
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
--            and   rsog.movgest_ts_id=ts.movgest_ts_id -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
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
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

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
         data_modifica=clock_timestamp()--, 26.08.2020 Sofia Jira SIAC-7747
         -- login_operazione=num.login_operazione||'-'||loginOperazione 26.08.2020 Sofia Jira SIAC-7747
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
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
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
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
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

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

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

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
--              login_operazione=file.login_operazione||'-'||loginOperazione
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
COST 100;

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui
( integer, integer, integer , varchar , timestamp ,  
  out integer,
  out varchar) owner to siac;
-- SIAC-8371 Sofia 29.11.2021 Fine

-- SIAC-8493 03.12.2021 Sofia --- inizio 
DROP FUNCTION if exists siac.fnc_siac_dicuiimpegnatoup_comp_anno ( integer,character varying);
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
-- SIAC-8493 03.12.2021 Sofia --- fine 

--- SIAC-8470 03.12.2021 Sofia -- inizio 
drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean DEFAULT true, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
)
RETURNS record
AS $body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=null;

     -- 30.07.2019 Sofia siac-6934
    flagDaRiaccAttrId                integer:=null;
    annoRiaccAttrId                  integer:=null;
    numeroRiaccAttrId                integer:=null;

BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Elaborazione.';


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null;

    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
    select 1 into codResult
    from fase_bil_t_programmi fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      -- 10.09.2019 Sofia SIAC-7023
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;

   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio-1
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;



   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
   else
   	bilancioElabId:=bilancioId;
   end if;

   -- 30.07.2019 Sofia siac-6934
   strMessaggio:='Lettura identificativi attributi riaccertamento.';
   SELECT attr.attr_id
   INTO   flagDaRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='flagDaRiaccertamento'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   annoRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='annoRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   numeroRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='numeroRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   strMessaggio:='Inizio inserimento dati programmi da  fase_bil_t_programmi - inizio.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- siac_t_programma

   strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_t_programma].';
   insert into siac_t_programma
   (
   	 programma_code,
	 programma_desc,
     programma_tipo_id,
     bil_id,
     programma_data_gara_indizione,
	 programma_data_gara_aggiudicazione,
	 investimento_in_definizione,
     programma_responsabile_unico,
	 programma_spazi_finanziari,
     programma_affidamento_id,
     login_operazione,
     validita_inizio,
     ente_proprietario_id
   )
   select  progr.programma_code,
           progr.programma_desc,
           tipo.programma_tipo_id,
           bilancioId,
           progr.programma_data_gara_indizione,
		   progr.programma_data_gara_aggiudicazione,
	   	   progr.investimento_in_definizione,
	       progr.programma_responsabile_unico,
	   	   progr.programma_spazi_finanziari,
	       progr.programma_affidamento_id,
           loginOperazione||'@'||fase.fase_bil_programma_id::varchar,
           clock_timestamp(),
           progr.ente_proprietario_id
   from fase_bil_t_programmi fase,siac_t_programma progr,
        siac_d_programma_tipo tipo
   where fase.fase_bil_elab_id=faseBilElabId
   and   progr.programma_id=fase.programma_id
   and   fase.fl_elab='N'
   and   tipo.ente_proprietario_id=progr.ente_proprietario_id
   and   tipo.programma_tipo_code=tipoApertura
   and   fase.data_cancellazione is null;

   GET DIAGNOSTICS numeroProgr = ROW_COUNT;


   strMessaggio:='Numero di programmi inseriti='||coalesce(numeroProgr,0)::varchar||'.';
   raise notice '%', strMessaggio;
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- inserimento dati programmi
   if coalesce(numeroProgr,0)!=0 then
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - aggiornamento fase_bil_t_programmi.';
    codResult:=null;
    update fase_bil_t_programmi fase
    set    programma_new_id=progr.programma_id,
           fl_elab='S'
    from   siac_t_programma progr
    where  fase.fase_bil_elab_id=faseBilElabId
    and    fase.fl_elab='N'
    and    progr.ente_proprietario_id=enteProprietarioId
    and    progr.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-8470
    and    progr.login_operazione like loginOperazione||'@%'
    and    substring(progr.login_operazione from position ('@' in progr.login_operazione)+1)::integer=fase.fase_bil_programma_id
    and    fase.data_cancellazione is null
    and    progr.data_cancellazione is null
    and    progr.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=coalesce(numeroProgr,0) then
     raise exception ' Il numero di aggiornamenti non corrisponde al numero di programmi inseriti.';
    end if;


    -- siac_r_programma_stato
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_stato].';
    codResult:=null;
    insert into siac_r_programma_stato
    (
   	 programma_id,
     programma_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rs.programma_stato_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_stato rs
    where fase.fase_bil_elab_id=faseBilElabId
    and   rs.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   fase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=0 and coalesce(numeroProgr,0)=0 then
	   raise exception ' Il numero di stati inseriti non corrisponde al numero di programmi inseriti.';
    end if;
    raise notice '% numIns=%', strMessaggio,codResult;



    -- siac_r_programma_class
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_class].';
    codResult:=null;
    insert into siac_r_programma_class
    (
   	 programma_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rc.classif_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_class rc,siac_t_class c
    where fase.fase_bil_elab_id=faseBilElabId
    and   rc.programma_id=fase.programma_id
    and   c.classif_id=rc.classif_id
    and   fase.programma_new_id is not null
    and   c.data_cancellazione is null
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_attr].';
    -- siac_r_programma_attr
    codResult:=null;
    insert into siac_r_programma_attr
    (
   	 programma_id,
     attr_id,
     boolean,
     testo,
     percentuale,
     numerico,
     tabella_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
   	       rattr.attr_id,
 		   rattr.boolean,
		   rattr.testo,
		   rattr.percentuale,
	       rattr.numerico,
	       rattr.tabella_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_attr rattr
    where fase.fase_bil_elab_id=faseBilElabId
    and   rattr.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_atto_amm].';
    -- siac_r_programma_atto_amm
    codResult:=null;
    insert into siac_r_programma_atto_amm
    (
     programma_id,
     attoamm_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
	       ratto.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_atto_amm ratto
    where fase.fase_bil_elab_id=faseBilElabId
    and   ratto.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;
  end if;




  strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - fine .';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
  end if;
  -- fine inserimento dati programmi

  strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - verifica dati creare [fase_bil_t_cronop].';

  codResult:=null;
  select 1 into codResult
  from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec
  where fasep.fase_bil_elab_id=faseBilElabId
  and   fasep.programma_new_id is not null
  and   fasep.fl_elab='S'
  and   fasec.fase_bil_elab_id=faseBilElabId
  and   fasec.programma_id=fasep.programma_id
  and   fasec.fl_elab='N'
  and   fasep.data_cancellazione is null
  and   fasec.data_cancellazione is null;

  raise notice '% numdaIns=%', strMessaggio,codResult;


  if codResult is not null then

   	strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop da inserire numero='||codResult::varchar||'- inizio.';
	codResult:=null;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop].';
    -- siac_t_cronop
   	insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     fasep.programma_new_id,
	     bilancioId,
	     cronop.usato_per_fpv,
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec,siac_t_cronop cronop
    where fasep.fase_bil_elab_id=faseBilElabId
    and   fasep.programma_new_id is not null
    and   fasep.fl_elab='S'
    and   fasec.fase_bil_elab_id=faseBilElabId
    and   fasec.programma_id=fasep.programma_id
    and   fasec.fl_elab='N'
    and   cronop.cronop_id=fasec.cronop_id
    and   fasep.data_cancellazione is null
    and   fasec.data_cancellazione is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS numeroCronop = ROW_COUNT;

    if coalesce(numeroCronop,0)!=0 then

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop inseriti numero='||coalesce(numeroCronop,0)::varchar||'.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
	 (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
	 )
     values
     (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  - aggiornamento fase_bil_t_cronop.';
     codResult:=null;
     update fase_bil_t_cronop fase
     set    cronop_new_id=cronop.cronop_id,
           fl_elab='S'
     from   siac_t_cronop cronop
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='N'
     and    cronop.ente_proprietario_id=enteProprietarioId
     and    cronop.login_operazione like loginOperazione||'@%'
     and    substring(cronop.login_operazione from position ('@' in cronop.login_operazione)+1)::integer=fase.fase_bil_cronop_id
     and    fase.data_cancellazione is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
	      raise exception ' Il numero di aggiornamenti non corrisponde al numero di crono-programmi inseriti.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_stato].';
     -- siac_r_cronop_stato
     codResult:=null;
     insert into siac_r_cronop_stato
     (
    	cronop_id,
        cronop_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            rs.cronop_stato_id,
            clock_timestamp(),
            loginOperazione,
            rs.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_stato rs
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rs.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;


     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_atto_amm].';
     -- siac_r_cronop_atto_amm
     codResult:=null;
     insert into siac_r_cronop_atto_amm
     (
    	cronop_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            ratto.attoamm_id,
            clock_timestamp(),
            loginOperazione,
            ratto.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_atto_amm ratto
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    ratto.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    ratto.data_cancellazione is null
     and    ratto.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
/*     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;*/

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_attr].';

     -- siac_r_cronop_attr
     codResult:=null;
     insert into siac_r_cronop_attr
     (
    	cronop_id,
		attr_id,
	    boolean,
	    testo,
    	percentuale,
	    numerico,
    	tabella_id,
	    validita_inizio,
    	login_operazione,
	    ente_proprietario_id
     )
     select
        fase.cronop_new_id,
        rattr.attr_id,
	    rattr.boolean,
    	rattr.testo,
	    rattr.percentuale,
	    rattr.numerico,
    	rattr.tabella_id,
	    clock_timestamp(),
    	loginOperazione,
	    rattr.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_attr rattr
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rattr.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rattr.data_cancellazione is null
     and    rattr.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem].';
	 codResult:=null;
     -- siac_t_cronop_elem
     insert into siac_t_cronop_elem
     (
	    cronop_elem_code,
	    cronop_elem_code2,
	    cronop_elem_code3,
	    cronop_elem_desc,
	    cronop_elem_desc2,
	    cronop_id,
--	    cronop_elem_id_padre,
        cronop_elem_is_ava_amm,
	    elem_tipo_id,
	    ordine,
	    livello,
   	    login_operazione,
	    validita_inizio,
	    ente_proprietario_id
     )
     select
        celem.cronop_elem_code,
	    celem.cronop_elem_code2,
	    celem.cronop_elem_code3,
	    celem.cronop_elem_desc,
	    celem.cronop_elem_desc2,
        fase.cronop_new_id,
--        cronop_elem_id_padre,
	    celem.cronop_elem_is_ava_amm,
        tiponew.elem_tipo_id,
        celem.ordine,
	    celem.livello,
        loginOperazione||'@'||celem.cronop_elem_id::varchar,
        clock_timestamp(),
        celem.ente_proprietario_id
 	 from fase_bil_t_cronop fase,siac_t_cronop_elem celem,
          siac_d_bil_elem_tipo tipo, siac_d_bil_elem_tipo tiponew
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_id
     and    tipo.elem_tipo_id=celem.elem_tipo_id
     and    tiponew.ente_proprietario_id=tipo.ente_proprietario_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;






     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_class].';
	 codResult:=null;
	 -- siac_r_cronop_elem_class
     insert into siac_r_cronop_elem_class
     (
  	  	cronop_elem_id,
	    classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            c.classif_id,
            clock_timestamp(),
            loginOperazione,
            c.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_class r,siac_t_class c
	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    c.classif_id=r.classif_id
     and    c.data_cancellazione is null
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_bil_elem].';
	 codResult:=null;
     -- siac_r_cronop_elem_bil_elem
     insert into siac_r_cronop_elem_bil_elem
     (
	    cronop_elem_id,
	    elem_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            enew.elem_id,
            clock_timestamp(),
            loginOperazione,
            enew.ente_proprietario_id
     from  fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_bil_elem r,
           siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
           siac_t_bil_elem enew,siac_d_bil_elem_tipo tiponew,
           siac_r_bil_elem_stato rs,siac_d_bil_elem_Stato stato
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    e.elem_id=r.elem_id
     and    tipo.elem_tipo_id=e.elem_tipo_id
     and    enew.bil_id=bilancioId
     and    enew.elem_code=e.elem_code
     and    enew.elem_code2=e.elem_code2
     and    enew.elem_code3=e.elem_code3
     and    tiponew.elem_tipo_id=enew.elem_tipo_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    rs.elem_id=enew.elem_id
     and    stato.elem_stato_id=rs.elem_stato_id
     and    stato.elem_stato_code!='AN'
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    e.data_cancellazione is null
     and    enew.data_cancellazione is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem_det].';
     codResult:=null;
     -- siac_t_cronop_elem_det
     insert into siac_t_cronop_elem_det
     (
	    cronop_elem_det_desc,
	    cronop_elem_id,
	    cronop_elem_det_importo,
	    elem_det_tipo_id,
	    periodo_id,
	    anno_entrata,
        quadro_economico_id_padre,
	    quadro_economico_id_figlio,
	    quadro_economico_det_importo,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
     )
     select
         det.cronop_elem_det_desc,
	     celem.cronop_elem_id,
	     det.cronop_elem_det_importo,
	     det.elem_det_tipo_id,
	     det.periodo_id,
	     det.anno_entrata,
         det.quadro_economico_id_padre,
	     det.quadro_economico_id_figlio,
	     det.quadro_economico_det_importo,
         loginOperazione,
         clock_timestamp(),
         det.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem, siac_t_cronop_elem_det det
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    det.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    det.data_cancellazione is null
     and    det.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;
   end if;
   strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - fine.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
   end if;

 end if;

 --- inserimento collegamenti tra programma e siac_t_movgest_Ts [siac_r_movgest_ts_programma]
 --- inserimento collegamenti tra cronop    e siac_t_movgest_ts [siac_r_movgest_ts_cronop_elem]
 --  inserimento da effettuare solo per tipoApertura='G'
 --  quindi partendo da movimenti validi e programmi - cronop nuovi, riportare le relazioni da annoBilancioPrec
 --  convertendo gli id da annoPrec a annoBilancio
 -- 06.05.2019 Sofia siac-6255
-- if tipoApertura=G_FASE then -- tutto da rivedere
-- 06.02.2020 Sofia jira SIAC-7386 aggiunto par. non aggiornare tutti i collegamenti in caso di esecuzione da puntuale
 if tipoApertura=G_FASE and ribalta_coll_mov=true then

  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inizio.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;

  -- inserimento legami aperti esistenti su impegni/accertamenti residui
  -- siac_r_movgest_ts_programma
  -- residui
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma residui.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_res_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_res_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_res_anno,
         mov_res_anno_prec, progr progr_anno, progr progr_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   mov_res_anno.movgest_tipo_id=mov_res_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_res_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- pluriennali
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma pluriennali.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_pluri_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_pluri_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_pluri_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_pluri_anno,
         mov_pluri_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_pluri_anno.movgest_anno=mov_pluri_anno_prec.movgest_anno
    and   mov_pluri_anno.movgest_numero=mov_pluri_anno_prec.movgest_numero
    and   mov_pluri_anno.movgest_subnumero=mov_pluri_anno_prec.movgest_subnumero
    and   mov_pluri_anno.movgest_tipo_id=mov_pluri_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_pluri_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- 30.07.2019 Sofia siac-6934
  -- riaccertati
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma riaccertati.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,
           siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
    select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipo.movgest_ts_tipo_code='T' -- non il legame ad un sub sugli attributi quindi associo solo i programmi del padre
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_riacc_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_riacc_anno,
         mov_riacc_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   mov_riacc_anno.movgest_tipo_id=mov_riacc_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_riacc_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'
     and    pstato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno, cronop cronop_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'   -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'   -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  --- 30.07.2019 Sofia siac-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_anno_prec.cronop_id=mov_riacc_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
   where
   not exists
   (select 1
    from siac_r_movgest_ts_cronop_elem r1
    where r1.movgest_ts_id=query.movgest_ts_id
    and   r1.cronop_id=query.cronop_new_id
    and   r1.cronop_elem_id is null
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)      elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'')  cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  --- 31.07.2019 Sofia SIAC-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
     with
     mov_anno as
     (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     annoRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=annoRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     numeroRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=numeroRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     )
     select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
     from mov_anno, annoRiacc, numeroRiacc
     where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
     and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
---     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_riacc_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
   where not exists
   (
   select 1
   from siac_r_movgest_ts_cronop_elem r1
   where r1.movgest_ts_id=query.movgest_ts_id
   and   r1.cronop_id=query.cronop_new_id
   and   r1.cronop_elem_id=query.cronop_elem_new_id
   and   r1.data_cancellazione is null
   and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;



  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - fine.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;
 end if;
 -- 06.05.2019 Sofia siac-6255



 strMessaggio:='Inserimento LOG.';
 codResult:=null;
 insert into fase_bil_t_elaborazione_log
 (fase_bil_elab_id,fase_bil_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
 if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
 end if;


 if coalesce(codiceRisultato,0)=0 then
   	messaggioRisultato:=strMessaggioFinale||'- FINE.';
 else messaggioRisultato:=strMessaggioFinale||strMessaggio;
 end if;

 return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
integer, 
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer, 
OUT  varchar
) owner to siac;

--- SIAC-8470 03.12.2021 Sofia -- fine 


--SIAC-8238 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR258_rend_gest_costi_missione_all_h_cont_gen" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  code_missione varchar,
  desc_missione varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  codice_codifica_albero varchar,
  livello_codifica integer,
  importo_dare numeric,
  importo_avere numeric,
  elem_id integer,
  collegamento_tipo_code varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;
anno_bil_int integer;

BEGIN


/* 16/12/2021 - SIAC-8238.
	Funzione creata per il report BILR258 per la SIAC-8238.
    Questo report sistituisce a partire dal 2021 il report di rendiconto BILR166
    che rimane per gli anni precedenti.
    Rispetto al BILR166 i dati sono presi dalle scritture contabili (prime note)
    invece che dalla contabilita' finanziaria (capitoli).
    I dati estratti corrispondono esattamente a quelli del report BILR125 dove pero' 
    non sono raggruppati per missione.
    Per poter raggruppare per missione e' necessario passare dai capitoli che sono
    estratti partendo dalle prime note ed i relativi eventi differenti a seconda
    dell'entita' coinvolta (impegni, accertamenti, liquidazioni, modifiche...).

*/

code_missione:='';
desc_missione:='';
codice_codifica:='';
descrizione_codifica:='';
codice_codifica_albero:='';
livello_codifica:=0;
importo_dare:=0;
importo_avere:=0;
elem_id:=0;
collegamento_tipo_code:='';

anno_competenza_int=p_anno ::INTEGER;

anno_bil_int:=p_anno::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 

return query 
select COALESCE(missioni.code_missione,'')::varchar code_missione,
   COALESCE(missioni.desc_missione,'')::varchar desc_missione,
   COALESCE(query_totale.codice_codifica,'') codice_codifica,
   COALESCE(query_totale.descrizione_codifica,'') descrizione_codifica,
   COALESCE(query_totale.codice_codifica_albero,'') codice_codifica_albero,
   COALESCE(query_totale.livello_codifica,0) livello_codifica,
   COALESCE(query_totale.importo_dare,0) importo_dare,
   COALESCE(query_totale.importo_avere,0) importo_avere,
   COALESCE(query_totale.elem_id,0) elem_id,
   COALESCE(query_totale.collegamento_tipo_code,'') collegamento_tipo_code 
   	from (
    	--Estraggo i capitoli di spesa gestione e i relativi dati di struttura
        --per poter avere le missioni.
	with capitoli as(
  select distinct programma.classif_id programma_id,
          macroaggr.classif_id macroaggregato_id,          
          capitolo.elem_id
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
  where 	
      programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
      and	programma.classif_id=r_capitolo_programma.classif_id			    
      and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
      and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
      and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
      and	capitolo.elem_id=r_capitolo_programma.elem_id					
      and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
      and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
      and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
      and	capitolo.ente_proprietario_id=p_ente_prop_id 					
      and	capitolo.bil_id = idBilancio										 
      and	programma_tipo.classif_tipo_code='PROGRAMMA'							
      and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
      and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
      and	stato_capitolo.elem_stato_code	=	'VA'						     							
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
      and	r_cat_capitolo.data_cancellazione 			is null),
   strut_bilancio as(
        select *
        from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')) 
  select COALESCE(strut_bilancio.missione_code,'') code_missione,
    COALESCE(strut_bilancio.missione_desc,'') desc_missione,
    capitoli.elem_id
  from capitoli  
    full JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
  ) missioni 
  left join  (     
  	--Estraggo i dati dei classificatori.
    --Questa parte della query e' la stessa del report BILR125.
        with classificatori as (
  SELECT classif_tot.classif_code AS codice_codifica, 
         classif_tot.classif_desc AS descrizione_codifica,
         classif_tot.ordine AS codice_codifica_albero, 
         case when classif_tot.ordine='E.26' then 3 
         	else classif_tot.level end livello_codifica,
         classif_tot.classif_id
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
             AND   (cf.classif_fam_code = '00020')-- OR cf.classif_fam_code = v_classificatori1)
             AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
             AND anno_bil_int BETWEEN date_part('year',tt1.validita_inizio) AND 
             date_part('year',COALESCE(tt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',rt1.validita_inizio) AND 
             date_part('year',COALESCE(rt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',c.validita_inizio) AND 
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
          AND anno_bil_int BETWEEN date_part('year',tn.validita_inizio) AND 
             date_part('year',COALESCE(tn.validita_fine,now())) 
  AND anno_bil_int BETWEEN date_part('year',c2.validita_inizio) AND 
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
      AND anno_bil_int BETWEEN date_part('year',t1.validita_inizio) 
      AND date_part('year',COALESCE(t1.validita_fine,now()))
  ) classif_tot
  ORDER BY classif_tot.classif_tipo_code desc, classif_tot.ordine),
pdce as(  
	--Estraggo le prime note collegate ai classificatori ed anche i relativi ID
    --degli eventi coinvolti per poterli poi collegare ai capitoli.
SELECT r_pdce_conto_class.classif_id,
		d_pdce_fam.pdce_fam_code, t_mov_ep_det.movep_det_segno, 
        d_coll_tipo.collegamento_tipo_code,
        r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2,
        COALESCE(t_mov_ep_det.movep_det_importo,0) importo
    FROM  siac_r_pdce_conto_class r_pdce_conto_class
    INNER JOIN siac_t_pdce_conto pdce_conto 
    	ON r_pdce_conto_class.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree t_pdce_fam_tree 
    	ON pdce_conto.pdce_fam_tree_id = t_pdce_fam_tree.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d_pdce_fam 
    	ON t_pdce_fam_tree.pdce_fam_id = d_pdce_fam.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det t_mov_ep_det 
    	ON t_mov_ep_det.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_mov_ep t_mov_ep 
    	ON t_mov_ep_det.movep_id = t_mov_ep.movep_id
    INNER JOIN siac_t_prima_nota t_prima_nota 
    	ON t_mov_ep.regep_id = t_prima_nota.pnota_id    
    INNER JOIN siac_r_prima_nota_stato r_prima_nota_stato 
    	ON t_prima_nota.pnota_id = r_prima_nota_stato.pnota_id
    INNER JOIN siac_d_prima_nota_stato d_prima_nota_stato 
    	ON r_prima_nota_stato.pnota_stato_id = d_prima_nota_stato.pnota_stato_id
    INNER JOIN siac_r_evento_reg_movfin r_ev_reg_movfin 
    	ON r_ev_reg_movfin.regmovfin_id = t_mov_ep.regmovfin_id
    INNER JOIN siac_d_evento d_evento 
    	ON d_evento.evento_id = r_ev_reg_movfin.evento_id
    INNER JOIN siac_d_collegamento_tipo d_coll_tipo
    	ON d_coll_tipo.collegamento_tipo_id = d_evento.collegamento_tipo_id
    WHERE r_pdce_conto_class.ente_proprietario_id = p_ente_prop_id
    AND   t_prima_nota.bil_id = idBilancio 
    AND   d_prima_nota_stato.pnota_stato_code = 'D'
    AND   r_pdce_conto_class.data_cancellazione IS NULL
    AND   pdce_conto.data_cancellazione IS NULL
    AND   t_pdce_fam_tree.data_cancellazione IS NULL
    AND   d_pdce_fam.data_cancellazione IS NULL
    AND   t_mov_ep_det.data_cancellazione IS NULL
    AND   t_mov_ep.data_cancellazione IS NULL
    AND   t_prima_nota.data_cancellazione IS NULL
    AND   r_prima_nota_stato.data_cancellazione IS NULL
    AND   d_prima_nota_stato.data_cancellazione IS NULL
    AND   r_ev_reg_movfin.data_cancellazione IS NULL
    AND   d_evento.data_cancellazione IS NULL
    AND   d_coll_tipo.data_cancellazione IS NULL
    AND   anno_bil_int BETWEEN date_part('year',pdce_conto.validita_inizio) 
    		AND date_part('year',COALESCE(pdce_conto.validita_fine,now()))  
    AND  anno_bil_int BETWEEN date_part('year',r_pdce_conto_class.validita_inizio)::integer
    		AND coalesce (date_part('year',r_pdce_conto_class.validita_fine)::integer ,anno_bil_int) 
   ),
   --Di seguito tutti gli eventi da collegarsi alle prime note come quelli estratti
   --dal report BILR159.
collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND	rms.ente_proprietario_id = p_ente_prop_id
  AND 	t_bil_elem.bil_id = idBilancio
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND 	rms.ente_proprietario_id = p_ente_prop_id
  AND   dms.mod_stato_code = 'V'
  AND 	t_bil_elem.bil_id = idBilancio
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL),
  collegamento_I_A AS ( --Impegni e Accertamenti
    SELECT DISTINCT r_mov_bil_elem.elem_id, r_mov_bil_elem.movgest_id
      FROM   siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem 
      WHERE  t_bil_elem.elem_id=r_mov_bil_elem.elem_id
      AND	 r_mov_bil_elem.ente_proprietario_id = p_ente_prop_id
      AND 	 t_bil_elem.bil_id = idBilancio
      AND    r_mov_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_SI_SA AS ( --Subimpegni e Subaccertamenti
  SELECT DISTINCT r_mov_bil_elem.elem_id, mov_ts.movgest_ts_id
  FROM  siac_t_movgest_ts mov_ts, siac_r_movgest_bil_elem r_mov_bil_elem,
  		siac_t_bil_elem t_bil_elem 
  WHERE mov_ts.movgest_id = r_mov_bil_elem.movgest_id
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND   mov_ts.ente_proprietario_id = p_ente_prop_id
  AND 	t_bil_elem.bil_id = idBilancio
  AND   mov_ts.data_cancellazione IS NULL
  AND   r_mov_bil_elem.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_SS_SE AS ( --SUBDOC
  SELECT DISTINCT r_mov_bil_elem.elem_id, r_subdoc_mov_ts.subdoc_id
  FROM   siac_r_subdoc_movgest_ts r_subdoc_mov_ts, siac_t_movgest_ts mov_ts, 
  		 siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem
  WHERE  r_subdoc_mov_ts.movgest_ts_id = mov_ts.movgest_ts_id
  AND    mov_ts.movgest_id = r_mov_bil_elem.movgest_id 
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND 	 mov_ts.ente_proprietario_id = p_ente_prop_id
  AND	 t_bil_elem.bil_id = idBilancio
  AND    (r_subdoc_mov_ts.data_cancellazione IS NULL OR 
  				(r_subdoc_mov_ts.data_cancellazione IS NOT NULL
  				AND r_subdoc_mov_ts.validita_fine IS NOT NULL AND
                r_subdoc_mov_ts.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
  AND    mov_ts.data_cancellazione IS NULL
  AND    r_mov_bil_elem.data_cancellazione IS NULL
  AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_OP_OI AS ( --Ordinativi di pagamento e incasso.
    SELECT DISTINCT r_ord_bil_elem.elem_id, r_ord_bil_elem.ord_id
      FROM   siac_r_ordinativo_bil_elem r_ord_bil_elem, siac_t_bil_elem t_bil_elem
      WHERE  r_ord_bil_elem.elem_id=t_bil_elem.elem_id 
      AND	 r_ord_bil_elem.ente_proprietario_id = p_ente_prop_id
      AND	 t_bil_elem.bil_id = idBilancio  
      AND    r_ord_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_L AS ( --Liquidazioni
    SELECT DISTINCT c.elem_id, a.liq_id
      FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
             siac_r_movgest_bil_elem c
      WHERE  a.movgest_ts_id = b.movgest_ts_id
      AND    b.movgest_id = c.movgest_id
      AND	 b.ente_proprietario_id = p_ente_prop_id
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    c.data_cancellazione IS NULL),
  collegamento_RR AS ( --Giustificativi.
  	SELECT DISTINCT d.elem_id, a.gst_id
      FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
      WHERE a.ente_proprietario_id = p_ente_prop_id
      AND   a.ricecon_id = b.ricecon_id
      AND   b.movgest_ts_id = c.movgest_ts_id
      AND   c.movgest_id = d.movgest_id
      AND   a.data_cancellazione  IS NULL
      AND   b.data_cancellazione  IS NULL
      AND   c.data_cancellazione  IS NULL
      AND   d.data_cancellazione  IS NULL),
  collegamento_RE AS ( --Richieste economali.
  SELECT DISTINCT c.elem_id, a.ricecon_id
    FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    WHERE b.ente_proprietario_id = p_ente_prop_id
    AND   a.movgest_ts_id = b.movgest_ts_id
    AND   b.movgest_id = c.movgest_id
    AND   a.data_cancellazione  IS NULL
    AND   b.data_cancellazione  IS NULL
    AND   c.data_cancellazione  IS NULL),
  collegamento_SS_SE_NCD AS ( --Note di credito
    select c.elem_id, a.subdoc_id
    from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    where a.movgest_ts_id = b.movgest_ts_id
    AND    b.movgest_id = c.movgest_id
    AND b.ente_proprietario_id = p_ente_prop_id
    AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
                  AND a.validita_fine IS NOT NULL AND
                  a.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL)                                    
SELECT classificatori.codice_codifica::varchar codice_codifica,
    classificatori.descrizione_codifica::varchar descrizione_codifica,
    classificatori.codice_codifica_albero::varchar codice_codifica_albero,
    classificatori.livello_codifica::integer livello_codifica,       
    case when upper(pdce.movep_det_segno)='DARE' then pdce.importo
    	else 0::numeric end importo_dare,
    case when upper(pdce.movep_det_segno)='AVERE' then pdce.importo
    	else 0::numeric end importo_avere,
    COALESCE(collegamento_MMGS_MMGE_a.elem_id, 
    	COALESCE(collegamento_MMGS_MMGE_b.elem_id,
        	COALESCE(collegamento_I_A.elem_id,
        		COALESCE(collegamento_SI_SA.elem_id,
                	COALESCE(collegamento_SS_SE.elem_id,
                    	COALESCE(collegamento_OP_OI.elem_id,
                        	COALESCE(collegamento_L.elem_id,
                            	COALESCE(collegamento_RR.elem_id,
                                	COALESCE(collegamento_RE.elem_id,
                                    	COALESCE(collegamento_SS_SE_NCD.elem_id,
                                          	0),0),0),0),0),0),0),0),0),0) elem_id,
	pdce.collegamento_tipo_code--, pdce.campo_pk_id, pdce.campo_pk_id_2                                            
from classificatori
	inner join pdce
    	ON pdce.classif_id = classificatori.classif_id     
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RE'
  --collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = pdce.campo_pk_id_2
  										AND pdce.collegamento_tipo_code IN ('SS','SE')                
 ) query_totale
on missioni.elem_id =query_totale.elem_id  
--where (query_totale.codice_codifica_albero = '' OR
--		left(query_totale.codice_codifica_albero,1) <> 'A')
order by missioni.code_missione, query_totale.codice_codifica;

RTN_MESSAGGIO:='Fine estrazione dei dati''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR166_rend_gest_costi_missione_all_h" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  pdce_finanz_code varchar,
  pdce_finanz_descr varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  importo_impegno numeric,
  code_missione varchar,
  desc_missione varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;

BEGIN

/* 16/12/2021.
	Il report BILR166 a partire dall'anno di bilancio 2021 e' sostituito dal report BILR258 (SIAC-8238).
*/

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
pdce_finanz_code:='';
pdce_finanz_descr:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
importo_impegno:=0;
code_missione:='';
desc_missione:='';
anno_competenza_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 
-- 15/05/2018: nella query seguente tolti i riferimenti alle tabelle siac_t_bil e
--  siac_t_periodo sostituite direttamente dall'Id del bilancio letto in
--  precedenza x velocizzare l'esecuzione.
return query 
select query_totale.* from  (
with impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,                            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id      
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	                          
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_movgest.bil_id = idBilancio
                AND t_movgest.movgest_anno =anno_competenza_int
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                	-- Impegni DEFINITIVI o DEFINITIVI NON LIQUIDABILI
                AND d_movgest_stato.movgest_stato_code  in ('D','N') 
                AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' --solo impegni non sub-impegni
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND  d_movgest_tipo.data_cancellazione IS NULL                            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),
capitoli as(
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
        p_anno anno_bilancio,
        r_movgest_bil_elem.movgest_id,
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
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_r_movgest_bil_elem r_movgest_bil_elem 
where 	
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
    and	programma.classif_id=r_capitolo_programma.classif_id			    
    and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
    and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
   	and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
    and	capitolo.elem_id=r_capitolo_programma.elem_id					
    and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
    and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
	and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
    and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
	and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	    	
    and	r_movgest_bil_elem.elem_id = capitolo.elem_id	
    and	capitolo.ente_proprietario_id=p_ente_prop_id 					
    and	capitolo.bil_id = idBilancio										 
    and	programma_tipo.classif_tipo_code='PROGRAMMA'							
    and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
    and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
    and	stato_capitolo.elem_stato_code	=	'VA'						     							
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
    and r_movgest_bil_elem.data_cancellazione		is null),
elenco_pdce_finanz as (        
	SELECT  r_movgest_class.movgest_ts_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from siac_r_movgest_class r_movgest_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_movgest_class.classif_id
                 and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and d_class_tipo.classif_tipo_code like 'PDC_%'			
                   and r_movgest_class.ente_proprietario_id=p_ente_prop_id
                   AND r_movgest_class.validita_fine is NULL
                   AND r_movgest_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,    
     strut_bilancio as(
     		select *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,''))                                  
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
	COALESCE(elenco_pdce_finanz.pdce_code,'')::varchar pdce_finanz_code,
    COALESCE(elenco_pdce_finanz.pdce_desc,'')::varchar pdce_finanz_descr,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
	COALESCE(impegni.movgest_ts_det_importo,0)::numeric importo_impegno,
    COALESCE(strut_bilancio.missione_code,'') code_missione,
    COALESCE(strut_bilancio.missione_desc,'') desc_missione
/*FROM strut_bilancio 
	LEFT JOIN capitoli on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
    LEFT JOIN impegni on impegni.movgest_id = capitoli.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
   */
   FROM impegni 
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
    FULL JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
ORDER BY code_missione,anno_impegno, num_impegno, num_subimpegno) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

--configurazione XBRL.
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice, xbrl_mapfat_variabile,  xbrl_mapfat_fatto,
  xbrl_mapfat_tupla_nome ,  xbrl_mapfat_tupla_group_key,
  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  ente_proprietario_id,
  data_creazione ,  data_modifica,  login_operazione ,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select 'BILR258',  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,
  xbrl_mapfat_tupla_nome ,  xbrl_mapfat_tupla_group_key,
  xbrl_mapfat_periodo_code,  xbrl_mapfat_unit_code,
  xbrl_mapfat_decimali,  validita_inizio,  ente_proprietario_id,
  data_creazione ,  data_modifica,  'SIAC-8238' ,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita
from  siac_t_xbrl_mapping_fatti a
where a.xbrl_mapfat_rep_codice='BILR166'
and a.data_cancellazione IS NULL
and not exists (select 1
	from siac_t_xbrl_mapping_fatti b
    where b.xbrl_mapfat_variabile = a.xbrl_mapfat_variabile
    	and b.ente_proprietario_id=a.ente_proprietario_id
        and b.xbrl_mapfat_rep_codice='BILR258');
        
		
--SIAC-8238 - Maurizio - FINE
        
--SIAC-8362 INIZIO

CREATE TABLE IF NOT EXISTS siac.siac_d_config_tipo (
	config_tipo_code varchar(50) NULL,
	config_tipo_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	CONSTRAINT pk_siac_d_config_tipo PRIMARY KEY (config_tipo_code)
);

INSERT INTO siac_d_config_tipo(config_tipo_code, config_tipo_desc, validita_inizio, login_operazione)
select tmp.code, tmp.descr, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin'
from (values('FEL-DEST', 'codice amministrazione destinataria fel') ,('FEL-NUM','telefono trasmittente fel'), ('FEL-MAIL','email trasmittente fel')) as tmp(code, descr)
where not exists (
select 1
from siac_d_config_tipo da
where da.config_tipo_code = tmp.code
and da.data_cancellazione is null
);


CREATE TABLE IF NOT EXISTS siac.siac_t_config_ente (
	config_ente_id SERIAL,
	config_ente_valore varchar(500),
	config_tipo_code varchar(250),
	ente_proprietario_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NOT NULL,
	CONSTRAINT pk_siac_t_ente_config PRIMARY KEY (config_ente_id),
	CONSTRAINT siac_t_config_ente_siac_d_config_tipo FOREIGN KEY (config_tipo_code) REFERENCES siac.siac_d_config_tipo(config_tipo_code),
	CONSTRAINT siac_t_ente_proprietario_siac_t_ente_config FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

select fnc_dba_create_index(
'siac_t_config_ente'::text,
  'idx_siac_t_config_ente'::text,
  'config_tipo_code, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_t_config_ente'::text,
  'siac_t_config_ente_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

select fnc_dba_create_index(
'siac_t_config_ente'::text,
  'siac_t_config_ente_fk_config_tipo_code_idx'::text,
  'config_tipo_code'::text,
  '',
  false
);

INSERT INTO siac_t_config_ente(config_ente_valore, config_tipo_code, validita_inizio, login_operazione, ente_proprietario_id)
select 'hd_fatturaelettronica@csi.it',  b.config_tipo_code, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin', a.ente_proprietario_id
from siac_t_ente_proprietario a
cross join siac_d_config_tipo b
where b.config_tipo_code in ('FEL-MAIL')
and a.data_cancellazione is null
and a.validita_fine  is null
and not exists (
select 1
from siac_t_config_ente da
where da.config_tipo_code = b.config_tipo_code
and da.data_cancellazione is null
);

INSERT INTO siac_t_config_ente(config_ente_valore, config_tipo_code, validita_inizio, login_operazione, ente_proprietario_id)
select '0113168111',  b.config_tipo_code, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin', a.ente_proprietario_id
from siac_t_ente_proprietario a
cross join siac_d_config_tipo b
where b.config_tipo_code in ('FEL-NUM')
and a.data_cancellazione is null
and a.validita_fine  is null
and not exists (
select 1
from siac_t_config_ente da
where da.config_tipo_code = b.config_tipo_code
and da.data_cancellazione is null
);

INSERT INTO siac_t_config_ente(config_ente_valore, config_tipo_code, validita_inizio, login_operazione, ente_proprietario_id)
select '0000000',  b.config_tipo_code, to_timestamp('01/01/2019','dd/mm/yyyy'), 'admin', a.ente_proprietario_id
from siac_t_ente_proprietario a
cross join siac_d_config_tipo b
where b.config_tipo_code in ('FEL-DEST')
and a.data_cancellazione is null
and a.validita_fine  is null
and not exists (
select 1
from siac_t_config_ente da
where da.config_tipo_code = b.config_tipo_code
and da.data_cancellazione is null
);

--SIAC-8362 FINE

--SIAC-8134 - INIZIO A. TODESCO
DROP TABLE IF EXISTS siac.siac_r_prima_nota_class;

CREATE TABLE IF NOT EXISTS siac.siac_r_prima_nota_class (
    pnota_classif_id SERIAL NOT NULL,
    pnota_id INTEGER NOT NULL,
    classif_id INTEGER NOT NULL,
    validita_inizio TIMESTAMP NOT NULL,
    validita_fine TIMESTAMP NULL,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP NOT NULL DEFAULT NOW(),
    data_modifica TIMESTAMP NOT NULL DEFAULT NOW(),
    data_cancellazione TIMESTAMP NULL,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT pk_siac_r_prima_nota_class PRIMARY KEY (pnota_classif_id),
	CONSTRAINT siac_t_prima_nota_siac_r_prima_nota_class FOREIGN KEY (pnota_id) REFERENCES siac.siac_t_prima_nota(pnota_id),
	CONSTRAINT siac_t_class_siac_r_prima_nota_class FOREIGN KEY (classif_id) REFERENCES siac.siac_t_class(classif_id),
    CONSTRAINT siac_t_ente_proprietario_siac_r_prima_nota_class FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

CREATE UNIQUE INDEX idx_siac_r_prima_nota_class_1 ON siac.siac_r_prima_nota_class USING btree (pnota_id, classif_id, validita_inizio, ente_proprietario_id) WHERE (data_cancellazione IS NULL);
CREATE INDEX siac_r_prima_nota_class_fk_pnota_id_idx ON siac.siac_r_prima_nota_class USING btree (pnota_id);
CREATE INDEX siac_r_prima_nota_class_fk_classif_id_idx ON siac.siac_r_prima_nota_class USING btree (classif_id);
CREATE INDEX siac_r_prima_nota_class_fk_ente_proprietario_id_idx ON siac.siac_r_prima_nota_class USING btree (ente_proprietario_id);

-- se lanciato con siac_rw
GRANT ALL PRIVILEGES ON TABLE siac.siac_r_prima_nota_class TO siac;

--CREATE SEQUENCE siac_r_prima_nota_class_pnota_classif_id_seq START 1 INCREMENT 1 MINVALUE 1 OWNED BY siac_r_prima_nota_class.pnota_classif_id;

GRANT USAGE, SELECT ON SEQUENCE siac_r_prima_nota_class_pnota_classif_id_seq TO siac;
--SIAC-8134 - FINE A.TODESCO 

--SIAC-8522 - Maurizio - INIZIO

DROP FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend"(p_ente_prop_id integer, p_anno varchar);

--reinstallo la vecchia versione
CREATE OR REPLACE FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend" (
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
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric
) AS
$body$
DECLARE

classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;


select fnc_siac_random_user()
into	user_table;

-- 07/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 07/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 07/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 /* ANNA 31-05 inizio */
 and missione.missione_code::integer <= 19
 /* ANNA 31-05 fine */
 ;
 
var_fondo_plur_anno_prec_a:=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;  
spese_da_impeg_anni_succ_f=0;
        
        
return query           
with tbclass as (select 	
v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
        v1.programma_id					programma_id,
        v1.ente_proprietario_id,
        v1.utente
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
    where utente=user_table
            group by v1.missione_tipo_desc, v1.missione_code, v1.missione_desc, 
            	v1.programma_tipo_desc, v1.programma_code, v1.programma_desc,
                v1.programma_id,
                v1.ente_proprietario_id, utente 
            order by missione_code,programma_code
           ),
tbfpvprec as (
select  
  importi.repimp_desc programma_code,
 sum(coalesce(importi.repimp_importo,0)) spese_fpv_anni_prec     
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	'BILR147'   				and
      	report.ente_proprietario_id		=	p_ente_prop_id				and
		anno_eserc.anno					=	p_anno 						and
      	bilancio.periodo_id				=	anno_eserc.periodo_id 		and
      	importi.bil_id					=	bilancio.bil_id 			and
        r_report_importi.rep_id			=	report.rep_id				and
        r_report_importi.repimp_id		=	importi.repimp_id			and
        importi.periodo_id 				=	anno_comp.periodo_id		and
        importi.ente_proprietario_id	=	p_ente_prop_id				and
        bilancio.ente_proprietario_id	=	p_ente_prop_id				and
        anno_eserc.ente_proprietario_id	=	p_ente_prop_id				and
		anno_comp.ente_proprietario_id	=	p_ente_prop_id
        and report.data_cancellazione IS NULL
        and importi.data_cancellazione IS NULL
        and r_report_importi.data_cancellazione IS NULL
        and anno_eserc.data_cancellazione IS NULL
        and anno_comp.data_cancellazione IS NULL
        group by importi.repimp_desc
        
        /*
        select a.programma_code as programma_code, 
        sum(a.importo_competenza) as spese_fpv_anni_prec from siac_t_cap_u_importi_anno_prec a
        where a.anno::INTEGER=annoBilInt-1
        and a.ente_proprietario_id=p_ente_prop_id
        and a.elem_cat_code like 'FPV%'
        group by a.programma_code*/
        ),
/*
	22/02/2019: SIAC-6623.
    	E' stato richiesto di estrarre gli importi FPV dell'anno precedente dai capitoli.
        Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
        eventualmente caricato sulle variabili (tbfpvprec). 
*/        
 fpv_anno_prec_da_capitoli as (               
select 	 t_class.classif_code programma_code,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = 'CAP-UG' -- prendere i capitoli di GESTIONE
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY t_class.classif_code ),
tbimpaprec as (
select 
--sum(coalesce(f.movgest_ts_det_importo,0)) spese_impe_anni_prec
--Spese impegnate negli esercizi precedenti e imputate all'esercizio N e coperte dal fondo pluriennale vincolato
-- si prendono le quote di impegni di competenza   
-- gli impegni considerati devono inoltre essere vincolati a fondo
-- l'importo considerato e' quello attuale
sum(coalesce( aa.movgest_ts_importo ,0)) spese_impe_anni_prec
, o.classif_code programma_code
          from siac_t_movgest a,  
          siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
          siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
          siac_r_movgest_ts_stato l, siac_d_movgest_stato m
          , siac_r_bil_elem_class n,
          siac_t_class o, siac_d_class_tipo p, 
          siac_r_movgest_ts_atto_amm q,
          siac_t_atto_amm r,
          --- 
           siac_d_movgest_tipo d_mov_tipo,
           siac_r_movgest_ts aa, 
           siac_t_avanzovincolo v, 
           siac_d_avanzovincolo_tipo vt
          where 
          a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and a.movgest_id = e.movgest_id  
          and e.movgest_ts_id = f.movgest_ts_id
          and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
          and l.movgest_ts_id=e.movgest_ts_id
          and l.movgest_stato_id=m.movgest_stato_id
          and n.classif_id = o.classif_id
          and o.classif_tipo_id=p.classif_tipo_id
          and n.elem_id = i.elem_id
          and q.movgest_ts_id=e.movgest_ts_id
          and q.attoamm_id = r.attoamm_id
          and a.bil_id = b.bil_id
          and h.elem_id=i.elem_id
          and i.movgest_id=a.movgest_id 
          and aa.avav_id=v.avav_id     
          and v.avav_tipo_id=vt.avav_tipo_id            
                --and aa.ente_proprietario_id=p_ente_prop_id
          and e.movgest_ts_id = aa.movgest_ts_b_id 
          and a.ente_proprietario_id= p_ente_prop_id      
          and c.anno = p_anno -- anno bilancio p_anno
          and p.classif_tipo_code='PROGRAMMA'
--          and o.classif_code = classifBilRec.programma_code
          and a.movgest_anno = annoBilInt -- annoBilInt
          and g.movgest_ts_det_tipo_code='I'
          and m.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          --and r.attoamm_anno::integer < annoBilInt    
          --and r.attoamm_anno < p_anno --p_anno   
          and vt.avav_tipo_code like'FPV%'
          and e.movgest_ts_id_padre is NULL  
          and i.data_cancellazione is null
          and i.validita_fine is NULL          
          and l.data_cancellazione is null
          and l.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and n.data_cancellazione is null
          and n.validita_fine is null
          and q.data_cancellazione is null
          and q.validita_fine is null          
          and aa.data_cancellazione is null
          and aa.validita_fine is null            
          	--21/05/2020 SIAC-7643 
            --aggiunti i test sulle date che mancavano
          and a.data_cancellazione is null
          and a.validita_fine is NULL
          and b.data_cancellazione is null
          and b.validita_fine is NULL 
          and c.data_cancellazione is null
          and c.validita_fine is NULL 
          and e.data_cancellazione is null
          and e.validita_fine is NULL   
          and f.data_cancellazione is null
          and f.validita_fine is NULL   
          and g.data_cancellazione is null
          and g.validita_fine is NULL   
          and h.data_cancellazione is null
          and h.validita_fine is NULL   
          and m.data_cancellazione is null
          and m.validita_fine is NULL   
          and o.data_cancellazione is null
          and o.validita_fine is NULL   
          and p.data_cancellazione is null
          and p.validita_fine is NULL   
          and r.data_cancellazione is null
          and r.validita_fine is NULL   
          and v.data_cancellazione is null
          --and v.validita_fine is NULL 
          and vt.data_cancellazione is null
          and vt.validita_fine is NULL              
          /*and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and e.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null ) */ 
          group by o.classif_code
          ),
tbriaccx as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
                (
                select sum(COALESCE(b.movgest_ts_det_importo,0)*-1) riacc_colonna_x,
                 s.classif_code programma_code
      from siac_r_modifica_stato a, siac_t_movgest_ts_det_mod b,
      siac_t_movgest_ts c, siac_d_modifica_stato d,
      siac_t_movgest e, siac_d_movgest_tipo f, siac_t_bil g,
      siac_t_periodo h, siac_t_modifica i, siac_d_modifica_tipo l,
      siac_d_modifica_stato m, 
      siac_t_bil_elem p, siac_r_movgest_bil_elem q,
      siac_r_bil_elem_class r, siac_t_class s, siac_d_class_tipo t,
      siac_r_movgest_ts_atto_amm qa,
          siac_t_atto_amm ra ,
      siac_r_movgest_ts_stato sti, siac_d_movgest_stato tipstimp    
      where b.mod_stato_r_id=a.mod_stato_r_id
      and b.movgest_ts_id = c.movgest_ts_id
      and e.movgest_tipo_id=f.movgest_tipo_id
      and d.mod_stato_id=a.mod_stato_id
      and e.movgest_id=c.movgest_id
      and g.bil_id=e.bil_id
      and i.mod_id=a.mod_id
      and i.mod_tipo_id=l.mod_tipo_id
      and m.mod_stato_id=a.mod_stato_id
      and g.periodo_id=h.periodo_id
      and qa.movgest_ts_id=c.movgest_ts_id
      and qa.attoamm_id = ra.attoamm_id
      --and ra.attoamm_anno < p_anno
       and e.movgest_anno = annoBilInt 
      --and c.movgest_ts_id=n.movgest_ts_id
      --and o.programma_id=n.programma_id
      and p.elem_id=q.elem_id
      and q.movgest_id=e.movgest_id
      and r.elem_id=p.elem_id
      and r.classif_id=s.classif_id
      and s.classif_tipo_id=t.classif_tipo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and d.mod_stato_code='V'
      and f.movgest_tipo_code='I'
      --and e.movgest_anno = annoBilInt
      and h.anno=p_anno
      and m.mod_stato_code='V'
      --and l.mod_tipo_code in  ('ECON' , 'ECONB')
      and 
      ( l.mod_tipo_code like  'ECON%'
         or l.mod_tipo_desc like  'ROR%'
      )
      and l.mod_tipo_code <> 'REIMP'
      and t.classif_tipo_code='PROGRAMMA'
      --and s.classif_code = classifBilRec.programma_code
      --and b.movgest_ts_det_importo < 0
      and sti.movgest_ts_id = c.movgest_ts_id
      and sti.movgest_stato_id = tipstimp.movgest_stato_id
      and tipstimp.movgest_stato_code in ('D', 'N')
      and sti.data_cancellazione is NULL
      and sti.validita_fine is null
      and c.movgest_ts_id_padre is null
      and a.data_cancellazione is null
      and a.validita_fine is null
      and b.data_cancellazione is null
      and b.validita_fine is null
      and c.data_cancellazione is null
      and c.validita_fine is null
      and d.data_cancellazione is null
      and d.validita_fine is null
      and e.data_cancellazione is null
      and e.validita_fine is null
      and f.data_cancellazione is null
      and f.validita_fine is null
      and g.data_cancellazione is null
      and g.validita_fine is null
      and h.data_cancellazione is null
      and h.validita_fine is null
      and i.data_cancellazione is null
      and i.validita_fine is null
      and l.data_cancellazione is null
      and l.validita_fine is null
      and m.data_cancellazione is null
      and m.validita_fine is null
      and p.data_cancellazione is null
      and p.validita_fine is null
      and q.data_cancellazione is null
      and q.validita_fine is null
      and r.data_cancellazione is null
      and r.validita_fine is null
      and s.data_cancellazione is null
      and s.validita_fine is null
      and t.data_cancellazione is null
      and t.validita_fine is null
      and qa.data_cancellazione is null
      and qa.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and c.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null 
               )
      group by s.classif_code
      ),
tbriaccy as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
( select sum(COALESCE(b.movgest_ts_det_importo,0)*-1) riacc_colonna_y,
s.classif_code programma_code
      from siac_r_modifica_stato a, siac_t_movgest_ts_det_mod b,
      siac_t_movgest_ts c, siac_d_modifica_stato d,
      siac_t_movgest e, siac_d_movgest_tipo f, siac_t_bil g,
      siac_t_periodo h, siac_t_modifica i, siac_d_modifica_tipo l,
      siac_d_modifica_stato m, 
      siac_t_bil_elem p, siac_r_movgest_bil_elem q,
      siac_r_bil_elem_class r, siac_t_class s, siac_d_class_tipo t,
      siac_r_movgest_ts_atto_amm qa, siac_t_atto_amm ra ,
      siac_r_movgest_ts_stato sti, siac_d_movgest_stato tipstimp    
      where b.mod_stato_r_id=a.mod_stato_r_id
      and b.movgest_ts_id = c.movgest_ts_id
      and e.movgest_tipo_id=f.movgest_tipo_id
      and d.mod_stato_id=a.mod_stato_id
      and e.movgest_id=c.movgest_id
      and g.bil_id=e.bil_id
      and i.mod_id=a.mod_id
      and i.mod_tipo_id=l.mod_tipo_id
      and m.mod_stato_id=a.mod_stato_id
      and g.periodo_id=h.periodo_id
      and qa.movgest_ts_id=c.movgest_ts_id
      and qa.attoamm_id = ra.attoamm_id
      --and ra.attoamm_anno < p_anno
      and e.movgest_anno > annoBilInt 
      and p.elem_id=q.elem_id
      and q.movgest_id=e.movgest_id
      and r.elem_id=p.elem_id
      and r.classif_id=s.classif_id
      and s.classif_tipo_id=t.classif_tipo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and d.mod_stato_code='V'
      and f.movgest_tipo_code='I'
      and h.anno=p_anno
      and m.mod_stato_code='V'
      --and l.mod_tipo_code in  ('ECON' , 'ECONB')
      and 
      ( l.mod_tipo_code like  'ECON%'
         or l.mod_tipo_desc like  'ROR%'
      )
      and l.mod_tipo_code <> 'REIMP'
      and t.classif_tipo_code='PROGRAMMA'
      --and b.movgest_ts_det_importo < 0
      and sti.movgest_ts_id = c.movgest_ts_id
      and sti.movgest_stato_id = tipstimp.movgest_stato_id
      and tipstimp.movgest_stato_code in ('D', 'N')
      and sti.data_cancellazione is NULL
      and sti.validita_fine is null
      and c.movgest_ts_id_padre is null
      and a.data_cancellazione is null
      and a.validita_fine is null
      and b.data_cancellazione is null
      and b.validita_fine is null
      and c.data_cancellazione is null
      and c.validita_fine is null
      and d.data_cancellazione is null
      and d.validita_fine is null
      and e.data_cancellazione is null
      and e.validita_fine is null
      and f.data_cancellazione is null
      and f.validita_fine is null
      and g.data_cancellazione is null
      and g.validita_fine is null
      and h.data_cancellazione is null
      and h.validita_fine is null
      and i.data_cancellazione is null
      and i.validita_fine is null
      and l.data_cancellazione is null
      and l.validita_fine is null
      and m.data_cancellazione is null
      and m.validita_fine is null
      and p.data_cancellazione is null
      and p.validita_fine is null
      and q.data_cancellazione is null
      and q.validita_fine is null
      and r.data_cancellazione is null
      and r.validita_fine is null
      and s.data_cancellazione is null
      and s.validita_fine is null
      and t.data_cancellazione is null
      and t.validita_fine is null
      and qa.data_cancellazione is null
      and qa.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and c.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null )
      group by s.classif_code
      ),
      tbimpanno1 as 
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
      (
      select sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and e.validita_fine is null
                        and e.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        and r.validita_fine is null
                        and r.data_cancellazione is null
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null
                    group by o.classif_code
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
                        --siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              )    
              ) as x
                group by x.programma_code 
            ),
tbimpanno2 as (
      select sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anno2_e, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno2_e, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                         
                   group by o.classif_code
              )  
               union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
              			--siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                        
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              ) 
              ) as x
                group by x.programma_code 
                ),
tbimpannisuc as (
      select sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anni_succ_f, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null                      
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anni_succ_f, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                        
                  group by o.classif_code
              )
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
                        --siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and a.validita_fine is null
                        and a.data_cancellazione is null
                        and g.validita_fine is null
                        and g.data_cancellazione is null
                        and h.validita_fine is null
                        and h.data_cancellazione is null
                        and m.validita_fine is null
                        and m.data_cancellazione is null
                        and o.validita_fine is null
                        and o.data_cancellazione is null
                        and p.validita_fine is null
                        and p.data_cancellazione is null
                        --and v.validita_fine is null
                        and v.data_cancellazione is null
                        and vt.validita_fine is null
                        and vt.data_cancellazione is null                        
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                       and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              )   
              ) as x
                group by x.programma_code 
                )                               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
tbclass.missione_tipo_desc ,
tbclass.missione_code ,
tbclass.missione_desc ,
''::varchar programma_tipo_code ,
tbclass.programma_tipo_desc ,
tbclass.programma_code ,
tbclass.programma_desc ,
	--22/02/2019: SIAC-6623. 
--coalesce(tbfpvprec.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(tbfpvprec.spese_fpv_anni_prec,0)) fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
	--22/02/2019: SIAC-6623. 
--coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(tbfpvprec.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(tbimpanno2.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
	--22/02/2019: SIAC-6623.
--coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
--coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) + coalesce(tbimpanno2.spese_da_impeg_anno2_e,0)+coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0)
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(tbfpvprec.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) + coalesce(tbimpanno2.spese_da_impeg_anno2_e,0)+coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0)
as fondo_plur_anno_g 
from tbclass left join tbimpaprec     
	on tbclass.programma_code=tbimpaprec.programma_code
left join tbfpvprec 
	on tbclass.programma_code=tbfpvprec.programma_code
left join tbriaccx     
	on tbclass.programma_code=tbriaccx.programma_code
left join tbriaccy   
	on tbclass.programma_code=tbriaccy.programma_code
left join tbimpanno1   
	on tbclass.programma_code=tbimpanno1.programma_code
left join tbimpanno2   
	on tbclass.programma_code=tbimpanno2.programma_code
left join tbimpannisuc   
	on tbclass.programma_code=tbimpannisuc.programma_code
    	--22/02/2019: SIAC-6623.
left join fpv_anno_prec_da_capitoli
	on tbclass.programma_code=fpv_anno_prec_da_capitoli.programma_code;
      
    
delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;




raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;



--la nuova funzione viene installata con il suffisso _new .
CREATE OR REPLACE FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend_new" (
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
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric
) AS
$body$
DECLARE

classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
bilancio_id integer;
bilancio_id_anno1 integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;
var_fondo_plur_anno_prec_a:=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;  
spese_da_impeg_anni_succ_f=0;

--Leggo l'id dell'anno bilancio
select bil.bil_id
into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;    

--Leggo l'id dell'anno bilancio +1
select bil.bil_id
into bilancio_id_anno1
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = annoCapImp1
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;   
            
/*
	11/11/2021 SIAC-8250.
Funzione riscritta per rendere le query piu' leggibili.
In seguito sono state applicate le nuove regole per i vari campi indicate 
nella Jira.

Colonna A: NON MODIFICATA.
	Stanziamento Capitoli di Spesa FPV in Spesa (Anno Bilancio -1).
	Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
    eventualmente caricato sulle variabili.

Colonna B: NON MODIFICATA. 
	Somma Importo VINCOLO Impegni definitivi (D, N) con anno bilancio 
	corrente e anno impegno = anno bilancio con Vincolo FPVCC+ FPVSC.
    
Colonna X: MODIFICATA
	Somma importo Modifiche non annullate su Impegni definitivi (D, N) 
	con anno bilancio corrente e anno impegno = anno bilancio 
    con Vincolo FPVCC o FPVSC
	Modifiche tipo: tutti  tranne ROR reimputazione, REANNO, AGG, RidCoi   
     
Colonna Y: MODIFICATA
	Somma importo Modifiche non annullate su Impegni definitivi (D, N) 
	con anno bilancio corrente e  anno impegno > anno bilancio 
    con Vincolo FPVCC o FPVSC
	Modifiche tipo: tutti  tranne ROR reimputazione, REANNO, AGG, RidCoi.
 
Colonna D: MODIFICATA
    Importo VINCOLO degli impegni con:
    Anno Bilancio corrente, Anno competenza dell’impegno = anno bilancio + 1
    con vincolo verso Accertamento competenza anno bilancio oppure con vinciolo AMM 
    +
    Impegni non nati da aggiudicazione e
    Anno di bilancio= anno corrente +1 e
    Anno di impegno = anno corrente +1 e
    Anno Riaccertamento = anno corrente (SIA DA ROR CHE REANNO).

    Il valore da considerare e' l'importo iniziale dell’impegno 
    con Impegno origine esercizio anno bilancio SENZA VINCOLO O CON VINCOLO VERSO 
    ACCERTAMENTO /AMM 
    (COMPET. anno bilancio -cioe' verso anno accertamento anno bilancio) 
    QUINDI NON SONO DA PRENDERE GLI IMPEGNI REIMPUTATI IL CUI IMPEGNO ORIGINE 
    ERA VINCOLATO A FPVCC/FPVSC  E NON SONO DA CONSIDERARE GLI IMPEGNI CHE 
    NASCONO NEL anno bilancio+1 A SEGUITO DI RIDUZIONE PER AGGIUDICAZIONE  
       
Colonna E: MODIFICATA
	Come colonna D ma gli anni sono anno bilancio +2
    
Colonna F: MODIFICATA
	Come colonna D ma gli anni sono > anno bilancio +2    

Colonna G: NON MODIFICATA
	La formula non e' cambiata (colonna_G =colonna_C+colonna_D+colonna_E+colonna_F)
    ma e' cambiato il modo di calcolare gli addendi.
    
*/        

return query           
with struttura as (
  select v1.missione_tipo_desc			missione_tipo_desc,
          v1.missione_code				missione_code,
          v1.missione_desc				missione_desc,
          v1.programma_tipo_desc		programma_tipo_desc,
          v1.programma_code				programma_code,
          v1.programma_desc				programma_desc,
          v1.programma_id					programma_id,
          v1.ente_proprietario_id
  from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
                                                      p_anno, '') v1
		/* 03/08/2021: il seguente controllo era stato inserito nella
           versione originale della procedura.
           Viene lasciato anche se non sono sicuro sia corretto */
        /* ANNA 31-05 inizio */
  where  v1.missione_code::integer <= 19
 		/* ANNA 31-05 fine */  
  group by v1.missione_tipo_desc, v1.missione_code, v1.missione_desc, 
            	v1.programma_tipo_desc, v1.programma_code, v1.programma_desc,
                v1.programma_id,
                v1.ente_proprietario_id 
            order by missione_code,programma_code  ),                      
fpv_anno_prec_da_variabili as (
select  
  importi.repimp_desc programma_code,
 sum(coalesce(importi.repimp_importo,0)) spese_fpv_anni_prec     
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,		
        siac_t_periodo 					anno_comp
where 	r_report_importi.rep_id			=	report.rep_id
        and r_report_importi.repimp_id		=	importi.repimp_id	
        and importi.periodo_id 				=	anno_comp.periodo_id              	
        and report.ente_proprietario_id		=	p_ente_prop_id
		and importi.bil_id					=	bilancio_id 			
      	and report.rep_codice				=	'BILR147'   				
      	and report.data_cancellazione IS NULL
        and importi.data_cancellazione IS NULL
        and r_report_importi.data_cancellazione IS NULL
        and anno_comp.data_cancellazione IS NULL
        group by importi.repimp_desc),
/*
	22/02/2019: SIAC-6623.
    	E' stato richiesto di estrarre gli importi FPV dell'anno precedente dai capitoli.
        Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
        eventualmente caricato sulle variabili (fpv_anno_prec_da_variabili). 
*/        
 fpv_anno_prec_da_capitoli as (               
select 	 t_class.classif_code programma_code,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = 'CAP-UG' -- prendere i capitoli di GESTIONE
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY t_class.classif_code ),
tbimpaprec as (
select 
--sum(coalesce(f.movgest_ts_det_importo,0)) spese_impe_anni_prec
--Spese impegnate negli esercizi precedenti e imputate all'esercizio N e coperte dal fondo pluriennale vincolato
-- si prendono le quote di impegni di competenza   
-- gli impegni considerati devono inoltre essere vincolati a fondo
-- l'importo considerato e' quello attuale
sum(coalesce(r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec,
 class.classif_code programma_code
          from siac_t_movgest mov,              
            siac_t_movgest_ts mov_ts, 
            siac_t_movgest_ts_det mov_ts_det,
            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
            siac_t_bil_elem bil_elem, 
            siac_r_movgest_bil_elem r_mov_bil_elem,
            siac_r_movgest_ts_stato r_mov_ts_stato, 
            siac_d_movgest_stato d_mov_stato,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class class, 
            siac_d_class_tipo d_class_tipo, 
            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
            siac_t_atto_amm atto,
            siac_d_movgest_tipo d_mov_tipo,
            siac_r_movgest_ts r_movgest_ts, 
            siac_t_avanzovincolo av_vincolo, 
            siac_d_avanzovincolo_tipo av_vincolo_tipo
          where mov.movgest_id = mov_ts.movgest_id  
          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = class.classif_id
          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
          and bil_elem.elem_id=r_mov_bil_elem.elem_id
          and r_mov_bil_elem.movgest_id=mov.movgest_id 
          and r_movgest_ts.avav_id=av_vincolo.avav_id     
          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id            
          and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and mov.ente_proprietario_id= p_ente_prop_id    
          and mov.bil_id = bilancio_id            
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and mov.movgest_anno = annoBilInt 
          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_mov_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and av_vincolo_tipo.avav_tipo_code like'FPV%'
          and mov_ts.movgest_ts_id_padre is NULL  
          and r_mov_bil_elem.data_cancellazione is null
          and r_mov_bil_elem.validita_fine is NULL          
          and r_mov_ts_stato.data_cancellazione is null
          and r_mov_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and r_mov_ts_atto.data_cancellazione is null
          and r_mov_ts_atto.validita_fine is null          
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null            
          	--21/05/2020 SIAC-7643 
            --aggiunti i test sulle date che mancavano
          and mov.data_cancellazione is null
          and mov.validita_fine is NULL
          and mov_ts.data_cancellazione is null
          and mov_ts.validita_fine is NULL   
          and mov_ts_det.data_cancellazione is null
          and mov_ts_det.validita_fine is NULL   
          and d_mov_ts_det_tipo.data_cancellazione is null
          and d_mov_ts_det_tipo.validita_fine is NULL   
          and bil_elem.data_cancellazione is null
          and bil_elem.validita_fine is NULL   
          and d_mov_stato.data_cancellazione is null
          and d_mov_stato.validita_fine is NULL   
          and class.data_cancellazione is null
          and class.validita_fine is NULL   
          and d_class_tipo.data_cancellazione is null
          and d_class_tipo.validita_fine is NULL   
          and atto.data_cancellazione is null
          and atto.validita_fine is NULL   
          and av_vincolo.data_cancellazione is null
          --and av_vincolo.validita_fine is NULL 
          and av_vincolo_tipo.data_cancellazione is null
          and av_vincolo_tipo.validita_fine is NULL              
          group by class.classif_code
          ),
tbriaccx as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                                 
  select sum(COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x,
   class.classif_code programma_code
      from siac_r_modifica_stato r_mod_stato, 
      	siac_t_movgest_ts_det_mod mov_ts_det_mod,
      	siac_t_movgest_ts mov_ts, 
      	siac_d_modifica_stato d_mod_stato,
        siac_t_movgest mov, 
        siac_d_movgest_tipo d_mov_tipo,       
        siac_t_modifica modif, 
        siac_d_modifica_tipo d_modif_tipo,
        siac_d_modifica_stato d_modif_stato, 
        siac_t_bil_elem t_bil_elem, 
        siac_r_movgest_bil_elem r_mov_bil_elem,
        siac_r_bil_elem_class r_bil_elem_class, 
        siac_t_class class, 
        siac_d_class_tipo d_class_tipo,
        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
        siac_t_atto_amm atto_amm ,
        siac_r_movgest_ts_stato r_mov_ts_stato, 
        siac_d_movgest_stato d_mov_stato    
      where mov_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and mov_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_modif_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_movgest_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_movgest_ts_atto_amm.attoamm_id = atto_amm.attoamm_id
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mov_ts_stato.movgest_ts_id = mov_ts_det_mod.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id        
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno = anno del bilancio
        and mov.movgest_anno = annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I' 
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione 
      /*  and 
        ( d_modif_tipo.mod_tipo_code like  'ECON%'
           or d_modif_tipo.mod_tipo_desc like  'ROR%'
        )      
        and d_modif_tipo.mod_tipo_code <> 'REIMP' */          
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG') 
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and mov_ts_det_mod.data_cancellazione is null
        and mov_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_modif_tipo.data_cancellazione is null
        and d_modif_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_movgest_ts_atto_amm.data_cancellazione is null
        and r_movgest_ts_atto_amm.validita_fine is null
        and d_mov_stato.data_cancellazione is null
        and d_mov_stato.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                      siac_t_avanzovincolo av_vincolo, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id                                 
                  and mov_ts_det_mod.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%' 
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null 
                 )
      group by class.classif_code
      ),
tbriaccy as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
( select sum(COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y,
	class.classif_code programma_code
      from siac_r_modifica_stato r_mod_stato, 
      siac_t_movgest_ts_det_mod movgest_ts_det_mod,
      siac_t_movgest_ts mov_ts, 
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest mov, 
      siac_d_movgest_tipo d_mov_tipo, 
      siac_t_modifica modif, 
      siac_d_modifica_tipo d_mod_tipo,
      siac_d_modifica_stato d_modif_stato, 
      siac_t_bil_elem t_bil_elem, 
      siac_r_movgest_bil_elem r_mov_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class class, 
      siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_mov_ts_atto_amm, 
      siac_t_atto_amm atto_amm ,
      siac_r_movgest_ts_stato r_mov_ts_stato, 
      siac_d_movgest_stato d_mov_stato    
      where movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and movgest_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_mod_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_mov_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_mov_ts_atto_amm.attoamm_id = atto_amm.attoamm_id        
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno > anno del bilancio
        and mov.movgest_anno > annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I'
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione         
  /*      and 
        ( d_mod_tipo.mod_tipo_code like  'ECON%'
           or d_mod_tipo.mod_tipo_desc like  'ROR%'
        )
        and d_mod_tipo.mod_tipo_code <> 'REIMP' */
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        'RIDCOI', 'AGG')         
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ts_stato.movgest_ts_id = mov_ts.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and movgest_ts_det_mod.data_cancellazione is null
        and movgest_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_mod_tipo.data_cancellazione is null
        and d_mod_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_mov_ts_atto_amm.data_cancellazione is null
        and r_mov_ts_atto_amm.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                  siac_t_avanzovincolo av_vincolo, 
                  siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                  and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%'                                      
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null )
      group by class.classif_code
      ),
imp_colonna_d as 
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
      (
      select sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d, 
      x.programma_code as programma_code from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 1
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_d, 
                          class.classif_code as programma_code
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 1
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id               
              select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_d, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 1
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))))) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code)    
              ) as x
                group by x.programma_code 
            ),
imp_colonna_e as (      
    select sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e , 
           x.programma_code as programma_code from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio
              select sum(COALESCE(r_movgest_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno2_e, 
                     		 class.classif_code as programma_code
                        from siac_t_movgest mov,  
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id 
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id                        
                        and mov.ente_proprietario_id=p_ente_prop_id
                        and mov.bil_id = bilancio_id
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 2
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and acc.movgest_anno = annoBilInt
                        and dstacc.movgest_stato_code in ('D', 'N')
                        --and atto.attoamm_anno = p_anno   
                        and mov.data_cancellazione is null
                        and mov_ts.data_cancellazione is null
                        and mov_ts.movgest_ts_id_padre is NULL                            
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and d_mov_stato.validita_fine is null
                        and d_mov_stato.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code )
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                      		spese_da_impeg_anno2_e, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato,
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id                          
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id     
                          and mov.bil_id = bilancio_id  
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null  
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                                                  
                     group by class.classif_code
              )  
               union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id               
				select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_e, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo 
                                 --con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))))) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code                 
              ) 
              ) as x
                group by x.programma_code 
                ),
imp_colonna_f as (
      select sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f , x.programma_code as programma_code from (
               (
 				 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio               
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      		as spese_da_impeg_anni_succ_f, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,  
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_movgest_ts acc_ts,
                          siac_t_movgest acc,
                          siac_r_movgest_ts_stato r_acc_ts_stato,
                          siac_d_movgest_stato d_acc_stato
                        where mov.movgest_id = mov_ts.movgest_id  
                            and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                            and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                            and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                            and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                            and r_bil_elem_class.classif_id = class.classif_id
                            and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                            and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                            and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                            and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                            and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id
                            and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                            and acc_ts.movgest_id = acc.movgest_id
                            and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                            and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id
                            and r_mov_bil_elem.movgest_id=mov.movgest_id 
                            and mov.ente_proprietario_id= p_ente_prop_id 
                            and mov.bil_id = bilancio_id     
                            and d_class_tipo.classif_tipo_code='PROGRAMMA'
                            and mov.movgest_anno > annoBilInt + 2
                            and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and d_mov_stato.movgest_stato_code in ('D', 'N')
                            and d_mov_tipo.movgest_tipo_code='I' 
                            and acc.movgest_anno = annoBilInt
                            and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                            --and atto.attoamm_anno = p_anno   
                            and mov_ts.movgest_ts_id_padre is NULL  
                            and mov_ts.data_cancellazione is null
                            and mov_ts.validita_fine is NULL                           
                            and r_mov_bil_elem.data_cancellazione is null
                            and r_mov_bil_elem.validita_fine is NULL          
                            and r_mov_ts_stato.data_cancellazione is null
                            and r_mov_ts_stato.validita_fine is null
                            and mov_ts_det.data_cancellazione is null
                            and mov_ts_det.validita_fine is null
                            and d_mov_tipo.data_cancellazione is null
                            and d_mov_tipo.validita_fine is null              
                            and r_bil_elem_class.data_cancellazione is null
                            and r_bil_elem_class.validita_fine is null
                            and r_mov_ts_atto.data_cancellazione is null
                            and r_mov_ts_atto.validita_fine is null                         
                            and r_mov_ts.data_cancellazione is null
                            and r_mov_ts.validita_fine is null                         
                            and acc_ts.movgest_ts_id_padre is null                        
                            and acc.validita_fine is null
                            and acc.data_cancellazione is null
                            and acc_ts.validita_fine is null
                            and acc_ts.data_cancellazione is null                                                
                            and r_acc_ts_stato.validita_fine is null
                            and r_acc_ts_stato.data_cancellazione is null                                                
                                --21/05/2020 SIAC-7643 
                                --aggiunti i test sulle date che mancavano                        
                            and mov.validita_fine is null
                            and mov.data_cancellazione is null
                            and d_mov_ts_det_tipo.validita_fine is null
                            and d_mov_ts_det_tipo.data_cancellazione is null
                            and t_bil_elem.validita_fine is null
                            and t_bil_elem.data_cancellazione is null
                            and d_mov_stato.validita_fine is null
                            and d_mov_stato.data_cancellazione is null
                            and class.validita_fine is null
                            and class.data_cancellazione is null
                            and d_class_tipo.validita_fine is null
                            and d_class_tipo.data_cancellazione is null 
                            and atto.validita_fine is null
                            and atto.data_cancellazione is null                                                                                                                                                   
                           group by class.classif_code)
              union(
              	 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anni_succ_f, 
                          class.classif_code as programma_code
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
						  siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 	
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id  
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id    
                          and mov.bil_id = bilancio_id   
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno > annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM' 
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL    
                          and mov_ts.data_cancellazione is null
                          and mov_ts.validita_fine is NULL   
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null   
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                       
                  group by class.classif_code
              )
              union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno > anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id              
             select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_e, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno > annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo 
                                 --con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))))) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code
              )   
              ) as x
                group by x.programma_code 
                )                               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
struttura.missione_tipo_desc ,
struttura.missione_code ,
struttura.missione_desc ,
''::varchar programma_tipo_code ,
struttura.programma_tipo_desc ,
struttura.programma_code ,
struttura.programma_desc ,
	--22/02/2019: SIAC-6623. 
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)) fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
	--22/02/2019: SIAC-6623. 
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
	--22/02/2019: SIAC-6623.
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
--coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) + coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0)+coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0)
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) + 
coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0)+
coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0)
as fondo_plur_anno_g 
from struttura left join tbimpaprec     
	on struttura.programma_code=tbimpaprec.programma_code
left join fpv_anno_prec_da_variabili 
	on struttura.programma_code=fpv_anno_prec_da_variabili.programma_code
left join tbriaccx     
	on struttura.programma_code=tbriaccx.programma_code
left join tbriaccy   
	on struttura.programma_code=tbriaccy.programma_code
left join imp_colonna_d   
	on struttura.programma_code=imp_colonna_d.programma_code
left join imp_colonna_e   
	on struttura.programma_code=imp_colonna_e.programma_code
left join imp_colonna_f   
	on struttura.programma_code=imp_colonna_f.programma_code
    	--22/02/2019: SIAC-6623.
left join fpv_anno_prec_da_capitoli
	on struttura.programma_code=fpv_anno_prec_da_capitoli.programma_code;
          

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8522 - Maurizio - FINE


--SIAC-8524 e SIAC-8579 - Maurizio - INIZIO


CREATE OR REPLACE FUNCTION siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
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
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;

perc_delta numeric;
perc_media numeric;
afde_bilancioId integer;
perc_massima numeric;

h_count integer :=0;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;

/*
	SIAC-8154 20/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil.

-- percentuale accantonamento bilancio
if p_anno_competenza = annoCapImp then
   	strpercAccantonamento = 'percentualeAccantonamentoAnno';
elseif  p_anno_competenza = annoCapImp1 then
	strpercAccantonamento = 'percentualeAccantonamentoAnno1';
else 
	strpercAccantonamento = 'percentualeAccantonamentoAnno2';
end if;



select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

select attr_bilancio."boolean"
into flagAccantGrad  from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'accantonamentoGraduale' and 
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;


if flagAccantGrad = 'N' then
   percAccantonamento = 100;
else  
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
    siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where 
    bilancio.periodo_id = anno_eserc.periodo_id and
    anno_eserc.anno = 	p_anno and
    bilancio.bil_id =  attr_bilancio.bil_id and
    attr_bilancio.attr_id= attr.attr_id and
    attr.attr_code = strpercAccantonamento and 
    attr_bilancio.data_cancellazione is null and
    attr_bilancio.ente_proprietario_id=p_ente_prop_id;
end if;

if tipomedia is null then
	tipomedia = 'SEMPLICE';
end if;
*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

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
codice_pdc='';

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA' 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
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
            siac_r_bil_elem_categoria r_cat_capitolo--,
         --22/12/2021 SIAC-8254
         --I capitoli devono essere presi tutti e non solo quelli
         --coinvolti in FCDE per avere l'importo effettivo dello stanziato
         --nella colonna (a).
            --siac_t_acc_fondi_dubbia_esig fcde
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and   fcde.elem_id						= capitolo.elem_id
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno				
        --and   fcde.afde_bil_id				=  afde_bilancioId
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
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
       -- and fcde.data_cancellazione IS NULL     
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               
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
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


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
codice_pdc:=classifBilRec.codice_pdc;


-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.elem_id = classifBilRec.bil_ele_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S';

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE

/*
	SIAC-8154 21/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/ 
/*
select COALESCE(datifcd.perc_acc_fondi,0), 
COALESCE(datifcd.perc_acc_fondi_1,0), COALESCE(datifcd.perc_acc_fondi_2,0),
COALESCE(datifcd.perc_acc_fondi_3,0), COALESCE(datifcd.perc_acc_fondi_4,0), 
COALESCE(datifcd.perc_delta,0), 
-- false -- SIAC-5854
1
into perc1, perc2, perc3, perc4, perc5, perc_delta
-- , flag_acc_cassa -- SIAC-5854
, h_count
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
where
  rbilelem.elem_id=classifBilRec.bil_ele_id and  
  rbilelem.acc_fde_id = datifcd.acc_fde_id and
  rbilelem.data_cancellazione is null;

if tipomedia = 'SEMPLICE' then
    perc_media = round((perc1+perc2+perc3+perc4+perc5)/5,2);
else 
    perc_media = round((perc1*0.10+perc2*0.10+perc3*0.10+perc4*0.35+perc5*0.35),2);
end if;

if perc_media is null then
   perc_media := 0;
end if;

if perc_delta is null then
   perc_delta := 0;
end if;
*/

raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
  COALESCE(datifcd.acc_fde_media_utente,0), 
  COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
  COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
  COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0),
  greatest (COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  	 COALESCE(datifcd.acc_fde_media_semplice_rapporti,0),
  	COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0))
  into perc_delta, h_count, tipomedia,
  fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
  fde_media_ponderata_totali, fde_media_ponderata_rapporti, perc_massima
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;
end if;

if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;

raise notice 'tipomedia % - media: % - delta: % - massima %', tipomedia , perc_media, perc_delta, perc_massima ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

--SIAC-8154 14/10/2021
--la colonna C diventa quello che prima era la colonna B
--la colonna B invece della percentuale media deve usa la percentuale 
--che ha il valore massimo (esclusa quella utente).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);   

--SIAC-8579 17/01/2022 l'accantonamento obbligatorio (Colonna B) diventa uguale
--all'accantonamento effettivo (Colonna C).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_massima/100) * percAccantonamento/100,2);
importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
importo_collb:=importo_collc;

raise notice 'importo_collb % - %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'percAccantonamento % - %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

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
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


--SIAC-8524 e SIAC-8579 - Maurizio - FINE


--SIAC-8508 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
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
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  spese_da_impeg_non_def_g numeric,
  fondo_plur_anno_h numeric
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
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
conflagfpv:=TRUE;
a_dacapfpv:=false;
h_dacapfpv:=false;
flagretrocomp:=false;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
annoProspInt=p_anno_prospetto::INTEGER;
annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

fondo_plur_anno_prec_a=0;
spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
spese_da_impeg_non_def_g=0;
fondo_plur_anno_h=0;

/* 08/03/2019: revisione per SIAC-6623 
	I campi fondo_plur_anno_prec_a, spese_impe_anni_prec_b, quota_fond_plur_anni_prec_c e
    fondo_plur_anno_h anche se valorizzati non sono utilizzati dal report perche'
    prende quelli di gestione calcolati tramite la funzione 
    BILR011_allegato_fpv_previsione_con_dati_gestione (ex BILR171).
*/

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

for classifBilRec in
	with strutt_capitoli as (select *
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
	capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroag_id,
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
	where macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    	macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    	programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    	programma.classif_id=r_capitolo_programma.classif_id					and    		       
    	capitolo.elem_id=r_capitolo_programma.elem_id							and
    	capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
   		capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    	capitolo.elem_id				=	r_capitolo_stato.elem_id			and
		r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    	capitolo.elem_id				=	r_cat_capitolo.elem_id				and
		r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        capitolo.bil_id= id_bil													and   	
    	tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    	programma_tipo.classif_tipo_code='PROGRAMMA' 							and	        
		stato_capitolo.elem_stato_code	=	'VA'								and    
			--04/08/2016: aggiunto FPVC 
		cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
    	and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
		and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
      	and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
        and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
        and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())        
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
        and	r_cat_capitolo.data_cancellazione 			is null),
    importi_capitoli_anno1 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno1      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp --p_anno       		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null            
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno),
	importi_capitoli_anno2 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno2      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where  	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id            
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and	capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp1 --p_anno +1      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    		capitolo_imp_periodo.anno),
    importi_capitoli_anno3 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno3      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp2 --p_anno +2      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno)            
    select strutt_capitoli.missione_tipo_desc			missione_tipo_desc,
		strutt_capitoli.missione_code				missione_code,
		strutt_capitoli.missione_desc				missione_desc,
		strutt_capitoli.programma_tipo_desc			programma_tipo_desc,
		strutt_capitoli.programma_code				programma_code,
		strutt_capitoli.programma_desc				programma_desc,
        COALESCE(SUM(importi_capitoli_anno1.stanziamento_fpv_anno1),0) stanziamento_fpv_anno1,
        COALESCE(SUM(importi_capitoli_anno2.stanziamento_fpv_anno2),0) stanziamento_fpv_anno2,
        COALESCE(SUM(importi_capitoli_anno3.stanziamento_fpv_anno3),0) stanziamento_fpv_anno3,
        0 fondo_pluri_anno_prec
    from  strutt_capitoli 
        left join capitoli 
            on (capitoli.programma_id = strutt_capitoli.programma_id
                AND capitoli.macroag_id = strutt_capitoli.macroag_id)          
        left join importi_capitoli_anno1
            on importi_capitoli_anno1.elem_id = capitoli.elem_id
        left join importi_capitoli_anno2
            on importi_capitoli_anno2.elem_id = capitoli.elem_id
        left join importi_capitoli_anno3
            on importi_capitoli_anno3.elem_id = capitoli.elem_id
--27/12/2021 SIAC-8508
-- Occorre eliminare le missioni '20', '50', '60', '99'.             
    where strutt_capitoli.missione_code not in('20', '50', '60', '99')
    group by strutt_capitoli.missione_tipo_desc, strutt_capitoli.missione_code, 
    	strutt_capitoli.missione_desc, strutt_capitoli.programma_tipo_desc, 
        strutt_capitoli.programma_code, strutt_capitoli.programma_desc
loop
	missione_tipo_desc:= classifBilRec.missione_tipo_desc;
    missione_code:= classifBilRec.missione_code;
    missione_desc:= classifBilRec.missione_desc;
    programma_tipo_desc:= classifBilRec.programma_tipo_desc;
    programma_code:= classifBilRec.programma_code;
    programma_desc:= classifBilRec.programma_desc;

    bil_anno:=p_anno;
    
    if annoProspInt = annoBilInt then
		fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno1;
   	elsif  annoProspInt = annoBilInt+1 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno1;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno2;
    elsif  annoProspInt = annoBilInt+2 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno2;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno3;
    end if;      
    
    if  annoProspInt > annoBilInt and a_dacapfpv=false and flagretrocomp=false then       
        	--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
	      spese_impe_anni_prec_b=0;
           
        /*  select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-1 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-1)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		*/
       	    
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          --siac_r_cronop_elem_class rcl1, siac_d_class_tipo clt1,siac_t_class cl1, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-1)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+1 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;


        if  annoProspInt = annoBilInt+1 then
          	fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	raise notice 'Anno prospetto = %',annoProspInt;
            
        elsif  annoProspInt = annoBilInt+2  then
          fondo_plur_anno_prec_a= - spese_impe_anni_prec_b +
          spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;
          	
          	--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
          spese_impe_anni_prec_b=0;
            
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer-2 -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno= (p_anno_prospetto::integer-2)::varchar -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;		
       	    */
          spese_da_impeg_anno1_d=0;
        
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = (p_anno_prospetto::integer -2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer-1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anno2_e=0;  
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e  
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::integer-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

          spese_da_impeg_anni_succ_f=0;
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =(p_anno_prospetto::INTEGER-2)::varchar -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null

		fondo_plur_anno_prec_a=fondo_plur_anno_prec_a+classifBilRec.fondo_pluri_anno_prec - spese_impe_anni_prec_b +
            spese_da_impeg_anno1_d + spese_da_impeg_anno2_e + spese_da_impeg_anni_succ_f;            
            
        end if; --if annoProspInt = annoBilInt+1 then 

       end if; -- if  annoProspInt > annoBilInt

--raise notice 'programma_code = %', programma_code;
--raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
--raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
--raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
--raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
--raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
--raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;


/* 17/05/2016: al momento questi campi sono impostati a zero in attesa di
	capire le modalita' di valorizzazione */
		spese_impe_anni_prec_b=0;
        quota_fond_plur_anni_prec_c=0;
        spese_da_impeg_anno1_d=0;
        spese_da_impeg_anno2_e=0;  
        spese_da_impeg_anni_succ_f=0;
        spese_da_impeg_non_def_g=0;
        
        /*COLONNA B -Spese impegnate negli anni precedenti con copertura costituita dal FPV e imputate all’esercizio N
		Occorre prendere tutte le quote di spesa previste nei cronoprogrammi con FPV selezionato, 
		con anno di entrata 2016 (o precedenti) e anno di spesa uguale al 2017.*/ 
       if flagretrocomp = false then

	   		--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
         
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno=p_anno_prospetto -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;*/
          
         -- raise notice 'spese_impe_anni_prec_b %' , spese_impe_anni_prec_b; 
        
        /* 3.	Colonna (c) – e' data dalla differenza tra la colonna b e la colonna a genera e
        rappresenta il valore del fondo costituito che verra' utilizzato negli anni 2018 e seguenti; */
        quota_fond_plur_anni_prec_c=fondo_plur_anno_prec_a-spese_impe_anni_prec_b ;  
       -- raise notice 'quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;  
        
        /*
        Colonna d – Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2018;
        */
          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno1_d
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id= p_ente_prop_id
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata = p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+1  -- anno prospetto + 1
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
          --and rcl1.data_cancellazione is null;
              
        
        /*
        Colonna e - Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata 2017 e anno di spesa uguale al 2019;
        */
                  
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anno2_e
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno di bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer=p_anno_prospetto::integer+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;

        
        
        /* Colonna f - Occorre prendere tutte le quote di 
        spesa previste nei cronoprogrammi con FPV selezionato, 
        con anno di entrata 2017 e anno di spesa uguale al 2020 e successivi;*/
                          
          select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_da_impeg_anni_succ_f 
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f, 
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno=p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata =p_anno_prospetto -- anno prospetto 
          and e.periodo_id = f.periodo_id
          and f.anno::integer > p_anno_prospetto::INTEGER+2 -- anno prospetto + 2
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;
        
        /*
        d.	Colonna g – Occorre prendere l’importo previsto nella sezione spese dei progetti. 
        E’ necessario quindi implementare una tipologia “Cronoprogramma da  definire”, 
        agganciato al progetto per il quale sono necessarie solo due informazioni: 
        l’importo e la Missione/Programma. Rimane incognito l’anno relativo alla spesa 
        (anche se apparira' formalmente agganciato al 2017). 
        Nel momento in cui saranno note le altre informazioni relative al progetto, 
        l’ente operera' nel modo consueto, ovvero inserendo una nuova versione di cronoprogramma 
        e selezionandone il relativo FPV. Operativamente e' sufficiente inserire un flag "Cronoprogramma da definire". 
        L'operatore entrera' comunque nelle due maschere (cosi' come sono ad oggi) di entrata e 
        spesa e inserira' l'importo e la spesa agganciandola a uno o piu' missioni per la spesa e analogamente per le entrate... 
        Inserira' 2017 sia nelle entrate che nella spesa. Essendo anno entrata=anno spesa non si creera' FPV 
        ma avendo il Flag "Cronoprogramma da Definire" l'unione delle due informazione generera' il 
        popolamento della colonna G. Questo escamotage peraltro potra' essere utilizzato anche dagli enti 
        che vorranno tracciare la loro 
        programmazione anche laddove non ci sia la generazione di FPV, ovviamente senza flaggare il campo citato.
        */
         
        
        /*5.	La colonna h  e' la somma dalla colonna c alla colonna g.
        		NON e' piu' calcolata in questa procedura. */
        
    	if h_dacapfpv = false then
        	fondo_plur_anno_h=quota_fond_plur_anni_prec_c+spese_da_impeg_anno1_d+
            	spese_da_impeg_anno2_e+spese_da_impeg_anni_succ_f+spese_da_impeg_non_def_g;
        end if;
     end if; --if flagretrocomp = false then
    
/*raise notice 'programma_codeXXX = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;*/
    

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

  fondo_plur_anno_prec_a=0;
  spese_impe_anni_prec_b=0;
  quota_fond_plur_anni_prec_c=0;
  spese_da_impeg_anno1_d=0;
  spese_da_impeg_anno2_e=0;
  spese_da_impeg_anni_succ_f=0;
  spese_da_impeg_non_def_g=0;
  fondo_plur_anno_h=0;        
end loop;  

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8508 - Maurizio - FINE

-- Allineamento function da all.sql 4.37 - Alessandro T.
DROP FUNCTION IF EXISTS siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER);

CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER)
RETURNS SETOF VARCHAR AS 
$body$
DECLARE
    v_messaggiorisultato VARCHAR;
    v_perc_media_confronto NUMERIC;
    v_tipo_media_confronto VARCHAR;
    v_uid_capitolo_previsione INTEGER;
    v_elem_code VARCHAR;
    v_elem_code2 VARCHAR;
BEGIN

	SELECT stbe.elem_code, stbe.elem_code2 
	FROM siac_t_bil_elem stbe 
	WHERE stbe.elem_id = p_uid_elem_gestione
	AND stbe.data_cancellazione IS NULL INTO v_elem_code, v_elem_code2;

	v_messaggiorisultato := 'Ricerca per capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di GESTIONE';
	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	
    v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti precedenti di GESTIONE';
    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

    v_tipo_media_confronto := 'GESTIONE';

    SELECT COALESCE (
        -- (
        --     SELECT tafdeEquiv.perc_acc_fondi
        --     FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        --     JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        --     JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        --     JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        --     JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        --     JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        --     JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        --     WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
        --     AND tafdeEquiv.elem_id = p_uid_elem_gestione
        --     AND step.ente_proprietario_id = p_uid_ente_proprietario
        --     AND sdafdes.afde_stato_code = 'DEFINITIVA'
        --     AND tafdeEquiv.data_cancellazione IS NULL 
        --     AND tafdeEquiv.validita_fine IS NULL 
        --     ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
        -- ),
        (
            SELECT tafdeEquiv.perc_acc_fondi 
            FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
            JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
            JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
            JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
            JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
            --JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
            --JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
            WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
            AND tafdeEquiv.elem_id = p_uid_elem_gestione
            AND step.ente_proprietario_id = p_uid_ente_proprietario
            --AND sdafdes.afde_stato_code = 'BOZZA'
            AND tafdeEquiv.data_cancellazione IS NULL 
            AND tafdeEquiv.validita_fine IS NULL 
            ORDER BY stafdeb.afde_bil_versione ASC LIMIT 1
        )
    ) INTO v_perc_media_confronto;

    
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA IN GESTIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco uid del capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT stbe.elem_id
        FROM siac_t_bil_elem stbe 
        JOIN siac_t_bil stb ON stbe.bil_id = stb.bil_id 
        JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
        JOIN siac_d_bil_elem_tipo sdbet ON stbe.elem_tipo_id = sdbet.elem_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = stbe.ente_proprietario_id 
        WHERE stbe.elem_code = v_elem_code 
        AND stbe.elem_code2 = v_elem_code2
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND stp.anno = p_anno_bilancio::VARCHAR
        AND sdbet.elem_tipo_code = 'CAP-EP'
        AND stbe.data_cancellazione IS NULL INTO v_uid_capitolo_previsione;
        
        IF v_uid_capitolo_previsione IS NOT NULL THEN
            v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - UID: [' || v_uid_capitolo_previsione || '] TROVATO.';
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	    END IF;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti precedenti di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'PREVISIONE';

        SELECT COALESCE (
            (
                SELECT tafdeEquiv.perc_acc_fondi
                FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
                JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
                JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
                JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
                JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
                JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
                JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
                WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
                AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
                AND step.ente_proprietario_id = p_uid_ente_proprietario
                AND sdafdes.afde_stato_code = 'DEFINITIVA'
                AND tafdeEquiv.data_cancellazione IS NULL 
                AND tafdeEquiv.validita_fine IS NULL 
                ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
            ),
            (
                SELECT tafdeEquiv.perc_acc_fondi 
                FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
                JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
                JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
                JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
                JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
                JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
                JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
                WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
                AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
                AND step.ente_proprietario_id = p_uid_ente_proprietario
                AND sdafdes.afde_stato_code = 'BOZZA'
                AND tafdeEquiv.data_cancellazione IS NULL 
                AND tafdeEquiv.validita_fine IS NULL 
                ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
            )
        ) INTO v_perc_media_confronto;
    
    END IF;

    IF v_perc_media_confronto IS NOT NULL THEN
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - MEDIA DI CONFRONTO: [' || v_perc_media_confronto || ' - ' || v_tipo_media_confronto || ' ]';
	ELSE 
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA';
    END IF;

    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

	-- [0, 1] => [0] percentuale incasso precedente, [1] => tipoMedia
    RETURN QUERY VALUES (v_perc_media_confronto::VARCHAR), (v_tipo_media_confronto);

    EXCEPTION
        WHEN RAISE_EXCEPTION THEN
            v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;
        WHEN others THEN
            v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
-- Allineamento function da all.sql 4.37 - Alessandro T.




--SIAC-8351 - Haitham - INIZIO 

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying,  integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata(integer, character varying, character varying, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(_uid_capitolospesa integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, impegno_anno integer, impegno_numero numeric, impegno_desc character varying, impegno_stato character varying, impegno_importo numeric, soggetto_code character varying, soggetto_desc character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_oggetto character varying, attoal_causale character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, pdc_code character varying, pdc_desc character varying, impegno_anno_capitolo integer, impegno_nro_capitolo integer, impegno_nro_articolo integer, impegno_flag_prenotazione character varying, impegno_cup character varying, impegno_cig character varying, impegno_tipo_debito character varying, impegno_motivo_assenza_cig character varying, impegno_componente character varying, cap_sac_code character varying, cap_sac_desc character varying, imp_sac_code character varying, imp_sac_desc character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY 
		with imp_sogg_attoamm as (
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
                    soggall.impegno_componente

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
                            zzz.impegno_componente
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
                                componente_desc.elem_det_comp_tipo_desc impegno_componente
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
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
                imp_sogg.impegno_componente

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
			and class_imp.data_cancellazione is NULL
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
			sac_impegno.classif_desc as imp_sac_desc        --  	SIAC-8351 Haitham 05/11/2021
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
$function$
;



CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata(_uid_capitoloentrata integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, accertamento_anno integer, accertamento_numero numeric, accertamento_desc character varying, soggetto_code character varying, soggetto_desc character varying, accertamento_stato_desc character varying, importo numeric, capitolo_anno integer, capitolo_numero integer, capitolo_articolo integer, ueb_numero character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, pdc_code character varying, pdc_desc character varying, attoamm_oggetto character varying, attoal_causale character varying, cap_sac_code character varying, cap_sac_desc character varying, acc_sac_code character varying, acc_sac_desc character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero,
			c.movgest_desc,
			f.movgest_ts_det_importo,
			l.movgest_stato_desc,
			c.movgest_id,
			n.classif_code pdc_code,
			n.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_class m,
			siac_t_class n,
			siac_d_class_tipo o,
			siac_t_bil p,
			siac_t_periodo q
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and l.movgest_stato_id=i.movgest_stato_id
		and i.movgest_ts_id=e.movgest_ts_id
		and m.movgest_ts_id = e.movgest_ts_id
		and n.classif_id = m.classif_id
		and o.classif_tipo_id = n.classif_tipo_id
		and p.bil_id = c.bil_id
		and q.periodo_id = p.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
		and o.data_cancellazione is null
		and d.movgest_tipo_code='A'
		and h.movgest_ts_det_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and a.elem_id=_uid_capitoloentrata
		and q.anno = _anno
        -- 12.07.2018 Sofia jira siac-6193
        and (case when coalesce(_filtro_crp,'X')='R' then c.movgest_anno<_anno::integer
                  when coalesce(_filtro_crp,'X')='C' then c.movgest_anno=_anno::integer
                  when coalesce(_filtro_crp,'X')='P' then c.movgest_anno>_anno::integer
                  else true end )
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset

		loop

			uid:=rec.movgest_id;
			capitolo_anno:=rec.anno::integer;
			capitolo_numero:=rec.elem_code::integer;
			capitolo_articolo:=rec.elem_code2::integer;
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;

			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;

			--classe di soggetti
			if soggetto_code is null then

				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;

			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc,
                -- 12.07.2018 Sofia jira siac-6193
                q.attoamm_oggetto,
                --SIAC-8188
               	staa.attoal_causale
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc,
                attoamm_oggetto,
                --SIAC-8188
                attoal_causale
			from
				siac_r_movgest_ts_atto_amm p,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t,
				siac_t_atto_amm q
			--SIAC-8188 se ci sono corrisponsenze le ritorno
			left join siac_t_atto_allegato staa on q.attoamm_id = staa.attoamm_id 
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;

			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

		
		
			select
				class_cap.classif_code,
				class_cap.classif_desc
			into
				cap_sac_code,
				cap_sac_desc
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
			and class_cap.data_cancellazione is null
		    and r_class_cap.elem_id=_uid_capitoloentrata;

            select
				class_imp.classif_code,
				class_imp.classif_desc
			into
				acc_sac_code,
				acc_sac_desc
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
     		and r_class_imp.movgest_ts_id=v_movgest_ts_id;

			return next;

		end loop;

	return;

END;
$function$
;



--SIAC-8351 - Haitham - FINE  

--SIAC-8558 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR258_rend_gest_costi_missione_all_h_cont_gen"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR258_rend_gest_costi_missione_all_h_cont_gen" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  code_missione varchar,
  desc_missione varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  codice_codifica_albero varchar,
  livello_codifica integer,
  importo_dare numeric,
  importo_avere numeric,
  elem_id integer,
  collegamento_tipo_code varchar,
  tipo_prima_nota varchar,
  pnota_id integer
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;
anno_bil_int integer;

BEGIN


/* 16/12/2021 - SIAC-8238.
	Funzione creata per il report BILR258 per la SIAC-8238.
    Questo report sistituisce a partire dal 2021 il report di rendiconto BILR166
    che rimane per gli anni precedenti.
    Rispetto al BILR166 i dati sono presi dalle scritture contabili (prime note)
    invece che dalla contabilita' finanziaria (capitoli).
    I dati estratti corrispondono esattamente a quelli del report BILR125 dove pero' 
    non sono raggruppati per missione.
    Per poter raggruppare per missione e' necessario passare dai capitoli che sono
    estratti partendo dalle prime note ed i relativi eventi differenti a seconda
    dell'entita' coinvolta (impegni, accertamenti, liquidazioni, modifiche...).

*/

code_missione:='';
desc_missione:='';
codice_codifica:='';
descrizione_codifica:='';
codice_codifica_albero:='';
livello_codifica:=0;
importo_dare:=0;
importo_avere:=0;
elem_id:=0;
collegamento_tipo_code:='';

anno_competenza_int=p_anno ::INTEGER;

anno_bil_int:=p_anno::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 

return query 
select 
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_miss_lib,'')::varchar
   else 
   		COALESCE(missioni.code_missione,'')::varchar end code_missione,
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_miss_lib,'')::varchar
   else
   		COALESCE(missioni.desc_missione,'')::varchar end desc_missione,
   COALESCE(query_totale.codice_codifica,'') codice_codifica,
   COALESCE(query_totale.descrizione_codifica,'') descrizione_codifica,
   COALESCE(query_totale.codice_codifica_albero,'') codice_codifica_albero,
   COALESCE(query_totale.livello_codifica,0) livello_codifica,
   COALESCE(query_totale.importo_dare,0) importo_dare,
   COALESCE(query_totale.importo_avere,0) importo_avere,
   COALESCE(query_totale.elem_id,0) elem_id,
   COALESCE(query_totale.collegamento_tipo_code,'') collegamento_tipo_code,
   COALESCE(query_totale.causale_ep_tipo_code,'') tipo_prima_nota,
   query_totale.pnota_id
   	from (
    	--Estraggo i capitoli di spesa gestione e i relativi dati di struttura
        --per poter avere le missioni.
	with capitoli as(
  select distinct programma.classif_id programma_id,
          macroaggr.classif_id macroaggregato_id,          
          capitolo.elem_id
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
  where 	
      programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
      and	programma.classif_id=r_capitolo_programma.classif_id			    
      and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
      and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
      and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
      and	capitolo.elem_id=r_capitolo_programma.elem_id					
      and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
      and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
      and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
      and	capitolo.ente_proprietario_id=p_ente_prop_id 	
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.				
      --and	capitolo.bil_id = idBilancio										 
      and	programma_tipo.classif_tipo_code='PROGRAMMA'							
      and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
      and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
      and	stato_capitolo.elem_stato_code	=	'VA'						     							
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
      and	r_cat_capitolo.data_cancellazione 			is null),
   strut_bilancio as(
        select *
        from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')) 
  select COALESCE(strut_bilancio.missione_code,'') code_missione,
    COALESCE(strut_bilancio.missione_desc,'') desc_missione,
    capitoli.elem_id
  from capitoli  
    full JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
  ) missioni 
  --devo estrarre con full join perche' nella query seguente ci sono anche le
  --prime note libere che non hanno il collegamento con i capitoli.
  full join  (     
  	--Estraggo i dati dei classificatori.
    --Questa parte della query e' la stessa del report BILR125.
        with classificatori as (
  SELECT classif_tot.classif_code AS codice_codifica, 
         classif_tot.classif_desc AS descrizione_codifica,
         classif_tot.ordine AS codice_codifica_albero, 
         case when classif_tot.ordine='E.26' then 3 
         	else classif_tot.level end livello_codifica,
         classif_tot.classif_id
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
             AND   (cf.classif_fam_code = '00020')-- OR cf.classif_fam_code = v_classificatori1)
             AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
             AND anno_bil_int BETWEEN date_part('year',tt1.validita_inizio) AND 
             date_part('year',COALESCE(tt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',rt1.validita_inizio) AND 
             date_part('year',COALESCE(rt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',c.validita_inizio) AND 
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
          AND anno_bil_int BETWEEN date_part('year',tn.validita_inizio) AND 
             date_part('year',COALESCE(tn.validita_fine,now())) 
  AND anno_bil_int BETWEEN date_part('year',c2.validita_inizio) AND 
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
      AND anno_bil_int BETWEEN date_part('year',t1.validita_inizio) 
      AND date_part('year',COALESCE(t1.validita_fine,now()))
  ) classif_tot
  ORDER BY classif_tot.classif_tipo_code desc, classif_tot.ordine),
pdce as(  
	--Estraggo le prime note collegate ai classificatori ed anche i relativi ID
    --degli eventi coinvolti per poterli poi collegare ai capitoli.
SELECT r_pdce_conto_class.classif_id,
		d_pdce_fam.pdce_fam_code, t_mov_ep_det.movep_det_segno, 
        d_coll_tipo.collegamento_tipo_code,
        r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2,
        COALESCE(t_mov_ep_det.movep_det_importo,0) importo,
         t_mov_ep_det.movep_det_id,d_caus_tipo.causale_ep_tipo_code,
         t_prima_nota.pnota_id
    FROM  siac_r_pdce_conto_class r_pdce_conto_class
    INNER JOIN siac_t_pdce_conto pdce_conto 
    	ON r_pdce_conto_class.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree t_pdce_fam_tree 
    	ON pdce_conto.pdce_fam_tree_id = t_pdce_fam_tree.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d_pdce_fam 
    	ON t_pdce_fam_tree.pdce_fam_id = d_pdce_fam.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det t_mov_ep_det 
    	ON t_mov_ep_det.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_mov_ep t_mov_ep 
    	ON t_mov_ep_det.movep_id = t_mov_ep.movep_id
    INNER JOIN siac_t_prima_nota t_prima_nota 
    	ON t_mov_ep.regep_id = t_prima_nota.pnota_id    
    INNER JOIN siac_r_prima_nota_stato r_prima_nota_stato 
    	ON t_prima_nota.pnota_id = r_prima_nota_stato.pnota_id
    INNER JOIN siac_d_prima_nota_stato d_prima_nota_stato 
    	ON r_prima_nota_stato.pnota_stato_id = d_prima_nota_stato.pnota_stato_id
    --devo estrarre con left join per prendere anche le prime note libere
    --che non hanno eventi.
    LEFT JOIN siac_r_evento_reg_movfin r_ev_reg_movfin 
    	ON r_ev_reg_movfin.regmovfin_id = t_mov_ep.regmovfin_id
    LEFT JOIN siac_d_evento d_evento 
    	ON d_evento.evento_id = r_ev_reg_movfin.evento_id
    LEFT JOIN siac_d_collegamento_tipo d_coll_tipo
    	ON d_coll_tipo.collegamento_tipo_id = d_evento.collegamento_tipo_id
    inner join siac_d_causale_ep_tipo d_caus_tipo
    	on d_caus_tipo.causale_ep_tipo_id=t_prima_nota.causale_ep_tipo_id
    WHERE r_pdce_conto_class.ente_proprietario_id = p_ente_prop_id
    AND   t_prima_nota.bil_id = idBilancio 
    AND   d_prima_nota_stato.pnota_stato_code = 'D'
    AND   r_pdce_conto_class.data_cancellazione IS NULL
    AND   pdce_conto.data_cancellazione IS NULL
    AND   t_pdce_fam_tree.data_cancellazione IS NULL
    AND   d_pdce_fam.data_cancellazione IS NULL
    AND   t_mov_ep_det.data_cancellazione IS NULL
    AND   t_mov_ep.data_cancellazione IS NULL
    AND   t_prima_nota.data_cancellazione IS NULL
    AND   r_prima_nota_stato.data_cancellazione IS NULL
    AND   d_prima_nota_stato.data_cancellazione IS NULL
    AND   r_ev_reg_movfin.data_cancellazione IS NULL
    AND   d_evento.data_cancellazione IS NULL
    AND   d_coll_tipo.data_cancellazione IS NULL
    AND   anno_bil_int BETWEEN date_part('year',pdce_conto.validita_inizio) 
    		AND date_part('year',COALESCE(pdce_conto.validita_fine,now()))  
    AND  anno_bil_int BETWEEN date_part('year',r_pdce_conto_class.validita_inizio)::integer
    		AND coalesce (date_part('year',r_pdce_conto_class.validita_fine)::integer ,anno_bil_int) 
   ),
   --Di seguito tutti gli eventi da collegarsi alle prime note come quelli estratti
   --dal report BILR159.
collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND	rms.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND 	rms.ente_proprietario_id = p_ente_prop_id
  AND   dms.mod_stato_code = 'V'
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL),
  collegamento_I_A AS ( --Impegni e Accertamenti
    SELECT DISTINCT r_mov_bil_elem.elem_id, r_mov_bil_elem.movgest_id
      FROM   siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem 
      WHERE  t_bil_elem.elem_id=r_mov_bil_elem.elem_id
      AND	 r_mov_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
     -- AND 	 t_bil_elem.bil_id = idBilancio
      AND    r_mov_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_SI_SA AS ( --Subimpegni e Subaccertamenti
  SELECT DISTINCT r_mov_bil_elem.elem_id, mov_ts.movgest_ts_id
  FROM  siac_t_movgest_ts mov_ts, siac_r_movgest_bil_elem r_mov_bil_elem,
  		siac_t_bil_elem t_bil_elem 
  WHERE mov_ts.movgest_id = r_mov_bil_elem.movgest_id
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND   mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   mov_ts.data_cancellazione IS NULL
  AND   r_mov_bil_elem.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_SS_SE AS ( --SUBDOC
  SELECT DISTINCT r_mov_bil_elem.elem_id, r_subdoc_mov_ts.subdoc_id
  FROM   siac_r_subdoc_movgest_ts r_subdoc_mov_ts, siac_t_movgest_ts mov_ts, 
  		 siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem
  WHERE  r_subdoc_mov_ts.movgest_ts_id = mov_ts.movgest_ts_id
  AND    mov_ts.movgest_id = r_mov_bil_elem.movgest_id 
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND 	 mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND	 t_bil_elem.bil_id = idBilancio
  AND    (r_subdoc_mov_ts.data_cancellazione IS NULL OR 
  				(r_subdoc_mov_ts.data_cancellazione IS NOT NULL
  				AND r_subdoc_mov_ts.validita_fine IS NOT NULL AND
                r_subdoc_mov_ts.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
  AND    mov_ts.data_cancellazione IS NULL
  AND    r_mov_bil_elem.data_cancellazione IS NULL
  AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_OP_OI AS ( --Ordinativi di pagamento e incasso.
    SELECT DISTINCT r_ord_bil_elem.elem_id, r_ord_bil_elem.ord_id
      FROM   siac_r_ordinativo_bil_elem r_ord_bil_elem, siac_t_bil_elem t_bil_elem
      WHERE  r_ord_bil_elem.elem_id=t_bil_elem.elem_id 
      AND	 r_ord_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
      --AND	 t_bil_elem.bil_id = idBilancio  
      AND    r_ord_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_L AS ( --Liquidazioni
    SELECT DISTINCT c.elem_id, a.liq_id
      FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
             siac_r_movgest_bil_elem c
      WHERE  a.movgest_ts_id = b.movgest_ts_id
      AND    b.movgest_id = c.movgest_id
      AND	 b.ente_proprietario_id = p_ente_prop_id
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    c.data_cancellazione IS NULL),
  collegamento_RR AS ( --Giustificativi.
  	SELECT DISTINCT d.elem_id, a.gst_id
      FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
      WHERE a.ente_proprietario_id = p_ente_prop_id
      AND   a.ricecon_id = b.ricecon_id
      AND   b.movgest_ts_id = c.movgest_ts_id
      AND   c.movgest_id = d.movgest_id
      AND   a.data_cancellazione  IS NULL
      AND   b.data_cancellazione  IS NULL
      AND   c.data_cancellazione  IS NULL
      AND   d.data_cancellazione  IS NULL),
  collegamento_RE AS ( --Richieste economali.
  SELECT DISTINCT c.elem_id, a.ricecon_id
    FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    WHERE b.ente_proprietario_id = p_ente_prop_id
    AND   a.movgest_ts_id = b.movgest_ts_id
    AND   b.movgest_id = c.movgest_id
    AND   a.data_cancellazione  IS NULL
    AND   b.data_cancellazione  IS NULL
    AND   c.data_cancellazione  IS NULL),
  collegamento_SS_SE_NCD AS ( --Note di credito
    select c.elem_id, a.subdoc_id
    from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    where a.movgest_ts_id = b.movgest_ts_id
    AND    b.movgest_id = c.movgest_id
    AND b.ente_proprietario_id = p_ente_prop_id
    AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
                  AND a.validita_fine IS NOT NULL AND
                  a.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL),      
--estraggo la missione collegata a siac_r_mov_ep_det_class per le 
--prime note libere.    
ele_prime_note_lib_miss as (
  	select t_class.classif_code code_miss_lib,
    t_class.classif_desc desc_miss_lib,
     r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id=3
        and d_class_tipo.classif_tipo_code='MISSIONE'
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL)                                    
SELECT classificatori.codice_codifica::varchar codice_codifica,
    classificatori.descrizione_codifica::varchar descrizione_codifica,
    classificatori.codice_codifica_albero::varchar codice_codifica_albero,
    classificatori.livello_codifica::integer livello_codifica,       
    case when upper(pdce.movep_det_segno)='DARE' then pdce.importo
    	else 0::numeric end importo_dare,
    case when upper(pdce.movep_det_segno)='AVERE' then pdce.importo
    	else 0::numeric end importo_avere,
    COALESCE(collegamento_MMGS_MMGE_a.elem_id, 
    	COALESCE(collegamento_MMGS_MMGE_b.elem_id,
        	COALESCE(collegamento_I_A.elem_id,
        		COALESCE(collegamento_SI_SA.elem_id,
                	COALESCE(collegamento_SS_SE.elem_id,
                    	COALESCE(collegamento_OP_OI.elem_id,
                        	COALESCE(collegamento_L.elem_id,
                            	COALESCE(collegamento_RR.elem_id,
                                	COALESCE(collegamento_RE.elem_id,
                                    	COALESCE(collegamento_SS_SE_NCD.elem_id,
                                          	0),0),0),0),0),0),0),0),0),0) elem_id,
	pdce.collegamento_tipo_code,--, pdce.campo_pk_id, pdce.campo_pk_id_2                                            
    ele_prime_note_lib_miss.code_miss_lib,
	ele_prime_note_lib_miss.desc_miss_lib,
	pdce.movep_det_id, pdce.causale_ep_tipo_code, pdce.pnota_id
from classificatori
	inner join pdce
    	ON pdce.classif_id = classificatori.classif_id     
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RE'
  --collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = pdce.campo_pk_id_2
  										AND pdce.collegamento_tipo_code IN ('SS','SE')                
  LEFT JOIN ele_prime_note_lib_miss ON ele_prime_note_lib_miss.movep_det_id=pdce.movep_det_id
 ) query_totale
on missioni.elem_id =query_totale.elem_id  
where COALESCE(query_totale.code_miss_lib,'') <> '' OR
	COALESCE(missioni.code_missione,'')  <> ''
--where (query_totale.codice_codifica_albero = '' OR
--		left(query_totale.codice_codifica_albero,1) <> 'A')
order by missioni.code_missione, query_totale.codice_codifica;

RTN_MESSAGGIO:='Fine estrazione dei dati''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

--SIAC-8558 - Maurizio - FINE


--SIAC-8196, SIAC-8557 e SIAC-8578 - Maurizio - INIZIO

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

WITH Importipn AS (
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
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
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
    AND   a.data_cancellazione is null
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
    select a.importo_codice_bilancio
    into v_importo_anno_prec
    from "BILR125_rendiconto_gestione_anno_prec"(p_ente_prop_id, anno_prec, 
    	p_classificatori, classifGestione.codice_codifica,
        classifGestione.descrizione_codifica) a;
  --  where a.codice_codifica = classifGestione.codice_codifica
   -- and a.descrizione_codifica = classifGestione.descrizione_codifica
   -- and a.tipo_codifica = classifGestione.tipo_codifica
   -- and a.livello_codifica = classifGestione.livello_codifica;
    
           
	v_importo_prec:=v_importo_anno_prec;
        
    raise notice 'codice_codifica = %, descr_codifica = %, importo_prec = %', 
    	classifGestione.codice_codifica, classifGestione.descrizione_codifica,
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione_anno_prec" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar,
  p_codice_codifica varchar,
  p_descrizione_codifica varchar
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


BEGIN

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
--raise notice '1 - %' , clock_timestamp()::text;

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

--raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
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
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
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
    AND   a.data_cancellazione is null
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
WHERE zz.classif_code = p_codice_codifica     
     AND zz.classif_desc = p_descrizione_codifica
ORDER BY zz.classif_tipo_code desc, 
--case when zz.ordine='26' then 'E.26' else zz.ordine end asc
zz.ordine


LOOP
   -- raise notice 'codice_codifica = %, descr_codifica = %', 
    --	classifGestione.codice_codifica, classifGestione.descrizione_codifica;
        
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
    AND   (i.anno = p_anno)-- OR i.anno = anno_prec)
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
              v_imp_avere_prec := pdce.importo;
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

--raise notice '2 - %' , clock_timestamp()::text;
--raise notice 'fine OK';

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
COST 100 ROWS 1000;

--SIAC-8196, SIAC-8557 e SIAC-8578 - Maurizio - FINE
