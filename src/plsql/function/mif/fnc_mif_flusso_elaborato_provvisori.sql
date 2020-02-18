/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_provvisori
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  flussoElabMifId integer,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out codiceRisultato integer,
  out messaggioRisultato varchar,
  out countOrdAggRisultato numeric )
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    ELAB_MIF_ESITO_IN       CONSTANT  varchar :='IN';


    -- costante tipo flusso presenti nei flussi e in siac_d_ricevuta_tipo
    QUIET_MIF_FLUSSO_TIPO   CONSTANT  varchar :='R';    -- quietanze e storni
    FIRME_MIF_FLUSSO_TIPO   CONSTANT  varchar :='S';    -- firme
    PROVC_MIF_FLUSSO_TIPO   CONSTANT  varchar :='P';    -- provvisori

    -- costante tipo ricevuta presente in siac_d_ricevuta_tipo
    QUIET_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='Q';    -- quietanze
    STORNI_MIF_FLUSSO_TIPO_CODE  CONSTANT  varchar :='S';    -- storni
    FIRME_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='F';    -- firme
    PROVC_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='P';    -- provvisori
    PROVC_ST_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='PS';    -- storno provvisori

    -- costante tipo flusso presenti nella mif_d_flusso_elaborato_tipo
    -- valori di parametro tipoFlussoMif devono essere presenti in mif_d_flusso_elaborato_tipo
    QUIET_MIF_ELAB_FLUSSO_TIPO   CONSTANT  varchar :='RICQUMIF';    -- quietanze e storni
    FIRME_MIF_ELAB_FLUSSO_TIPO   CONSTANT  varchar :='RICFIMIF';    -- firme
    PROVC_MIF_ELAB_FLUSSO_TIPO   CONSTANT  varchar :='RICPCMIF';    -- provvisori di cassa

	-- tipo_record in mif_t_emap_hrer
    TIPO_REC_TESTA CONSTANT varchar :='HR';
    TIPO_REC_CODA  CONSTANT varchar :='ER';
    TIPO_REC_RR    CONSTANT varchar :='RR';
    TIPO_REC_DR    CONSTANT varchar :='DR';

	-- codici errori
    MIF_TESTATA_COD_ERR         CONSTANT varchar :='1'; -- record testata non presente
    MIF_CODA_COD_ERR            CONSTANT varchar :='2'; -- record coda non presente
    MIF_RR_COD_ERR              CONSTANT varchar :='3'; -- record ricevuta non presente
    MIF_DR_COD_ERR              CONSTANT varchar :='4'; -- record dettaglio ricevuta non presente

    MIF_FLUSSO_QU_COD_ERR       CONSTANT varchar:='5'; -- tipo flusso quietanza
    MIF_FLUSSO_FI_COD_ERR       CONSTANT varchar:='6'; -- tipo flusso firme
    MIF_FLUSSO_PC_COD_ERR       CONSTANT varchar:='7'; -- tipo flusso provvisori cassa
    MIF_FLUSSO_QU_C_COD_ERR       CONSTANT varchar:='8'; -- tipo flusso quietanza
    MIF_FLUSSO_FI_C_COD_ERR       CONSTANT varchar:='9'; -- tipo flusso firme
    MIF_FLUSSO_PC_C_COD_ERR       CONSTANT varchar:='10'; -- tipo flusso provvisori cassa

    MIF_DT_ORA_TESTA_COD_ERR    CONSTANT varchar:='11';  -- data ora flusso non presente in testata
    MIF_RICEVUTE_TESTA_COD_ERR  CONSTANT varchar:='12'; -- numero ricevute non prensente in testata
    MIF_DATI_ENTE_TESTA_COD_ERR CONSTANT varchar:='13'; -- dati enteOil non prensente in testata o non validi
    MIF_DT_ORA_CODA_COD_ERR    CONSTANT varchar:='14';  -- data ora flusso non presente in coda
    MIF_RICEVUTE_CODA_COD_ERR  CONSTANT varchar:='15'; -- numero ricevute non prensente in coda
    MIF_DATI_ENTE_CODA_COD_ERR CONSTANT varchar:='16'; -- dati enteOil non prensente in coda o non validi

    MIF_RR_NO_DR_COD_ERR CONSTANT varchar:='17'; -- record RR senza DR
    MIF_DR_NO_RR_COD_ERR CONSTANT varchar:='18'; -- record DR senza RR

	MIF_RR_NO_TIPO_REC_COD_ERR CONSTANT varchar:='19'; -- tipo record non valorizzato
    MIF_DR_NO_TIPO_REC_COD_ERR CONSTANT varchar:='20'; -- tipo record non valorizzato

    -- scarti record rr
	MIF_RR_PROGR_RIC_COD_ERR CONSTANT varchar:='21'; -- progressivo ricevuta non valorizzato
	MIF_RR_DATA_MSG_COD_ERR  CONSTANT varchar:='22'; -- data ora messaggio ricevuta non valorizzato
    MIF_RR_ESITO_DER_COD_ERR CONSTANT varchar:='23'; -- esito derivato non valorizzato o non ammesso per ricevuta
	MIF_RR_DATI_ENTE_COD_ERR CONSTANT varchar:='24'; -- dati ente non valorizzati o errati
    MIF_RR_ESITO_NEG_COD_ERR CONSTANT varchar:='25'; -- codice_esito non valorizzato o non positivo
    MIF_RR_COD_FUNZIONE_COD_ERR CONSTANT varchar:='26'; -- codice_funzione non valorizzato o non ammesso
    MIF_RR_QUALIFICATORE_COD_ERR CONSTANT varchar:='27'; -- qualificatore non valorizzato o non ammesso
    MIF_RR_DATI_ORD_COD_ERR CONSTANT varchar:='28';  -- dati ordinativo non indicati ( anno_esercizio, numero_ordinativo, data_pagamento)
    MIF_RR_ANNO_ORD_COD_ERR CONSTANT varchar:='29';  -- anno ordinativo non corretto ( anno_esercizio>annoBilancio)
    MIF_RR_ORD_COD_ERR CONSTANT varchar:='30'; -- ordinativo non esistente
	MIF_RR_ORD_ANNULL_COD_ERR CONSTANT varchar:='31'; -- ordinativo annullato
	MIF_RR_ORD_DT_EMIS_COD_ERR CONSTANT varchar:='32'; -- ordinativo data_emissione successiva alla data di quietanza/firma
    MIF_RR_ORD_DT_TRASM_COD_ERR CONSTANT varchar:='33'; -- ordinativo data_trasmisisione non valorizzata o successiva alla data di quietanza
	MIF_RR_ORD_DT_FIRMA_COD_ERR CONSTANT varchar:='34'; -- ordinativo data_firma non valorizzata o successiva alla data di quietanza

	-- scarto record dr
    MIF_DR_ORD_PROGR_RIC_COD_ERR CONSTANT varchar:='35'; -- esistenza di ricevute con record DR con progressivo_ricevuta non valorizzato
    MIF_DR_ORD_NUM_RIC_COD_ERR CONSTANT   varchar:='36'; -- esistenza di ricevute con record DR con numero_ricevuta non valorizzato
	MIF_DR_ORD_IMPORTO_RIC_COD_ERR CONSTANT   varchar:='37'; -- esistenza di ricevute con record DR con importo_ricevuta non valorizzato o non valido

    MIF_DR_ORD_IMP_NEG_RIC_COD_ERR CONSTANT   varchar:='38'; -- totale ricevuta in DR negativo
	MIF_DR_ORD_NUM_ERR_RIC_COD_ERR CONSTANT   varchar:='39'; -- lettura numero ricevuta ultimo in DR non riuscita
    MIF_DR_ORD_IMP_ORD_Z_COD_ERR   CONSTANT    varchar:='40';  -- lettura importo ordinativo in ciclo di elaborazione non riuscita
    MIF_DR_ORD_NON_QUIET_COD_ERR   CONSTANT    varchar:='41';  -- verifica esistenza quietanza in ciclo di elaborazione per ord in fase di storno non riuscita
    MIF_DR_ORD_IMP_QUIET_ERR_COD_ERR CONSTANT  varchar:='42';  -- importo quietanzato totale > importo ordinativo
    MIF_DR_ORD_IMP_QUIET_NEG_COD_ERR CONSTANT  varchar:='43';  -- importo quietanzato totale < 0
 	MIF_DR_ORD_STATO_ORD_ERR_COD_ERR CONSTANT  varchar:='44';  -- stato attuale ordinativo non congruente con operazione ricevuta


	MIF_RR_DATI_FIRMA_COD_ERR CONSTANT  varchar:='45';   -- dati firma non indicati
    MIF_RR_ORD_FIRMATO_COD_ERR CONSTANT  varchar:='46';  -- ordinativo firmato
    MIF_RR_ORD_QUIET_COD_ERR CONSTANT  varchar:='47';    -- ordinativo quietanzato in data antecedente alla data di firma
	MIF_RR_ORD_NO_FIRMA_COD_ERR CONSTANT  varchar:='48'; -- ordinativo non firmato
    MIF_RR_ORD_FIRMA_QU_COD_ERR CONSTANT  varchar:='49'; -- ordinativo quietanzato

	MIF_RR_PC_CASSA_COD_ERR CONSTANT varchar:='50';       -- dati provvisorio di cassa non indicati ( anno_esercizio, numero_ordinativo, data_ordinativo, importo_ordinativo)
    MIF_RR_PC_CASSA_ANNO_COD_ERR CONSTANT varchar:='51';  -- anno provvisorio non corretto ( anno_esercizio>annoBilancio)
    MIF_RR_PC_CASSA_DT_COD_ERR  CONSTANT varchar:='52';   --  data provvisorio non corretto ( data_ordinativo>dataElaborazione)
	MIF_RR_PC_CASSA_IMP_COD_ERR  CONSTANT varchar:='53';  --  importo provvisorio non corretto ( importo_ordinativo<=0)
	MIF_RR_PROVC_S_COD_ERR CONSTANT varchar:='54';        --  provvisorio di cassa non esistente per ricevuta di storno
	MIF_RR_PROVC_S_REG_COD_ERR CONSTANT varchar:='55';    --  provvisorio di cassa esistente per ricevuta di storno , collegato a ordinativo
	MIF_RR_PROVC_S_IMP_COD_ERR CONSTANT varchar:='56';    --  provvisorio di cassa esistente per ricevuta di storno , importo storno != importo provvisorio
    MIF_RR_PROVC_S_SOG_COD_ERR  CONSTANT varchar:='57';    --  provvisorio di cassa esistente per ricevuta di storno , soggetto storno != soggetto provvisorio
    MIF_RR_PROVC_S_STO_COD_ERR  CONSTANT varchar:='58';    --  provvisorio di cassa esistente per ricevuta di storno , provvisorio stornato data_annullamento valorizzata
	MIF_RR_PROVC_ESISTE_COD_ERR  CONSTANT varchar:='59';   --  provvisorio di cassa esistente per ricevuta di inserimento , provvisorio esistente

    -- codice_esito positivo
    CODICE_ESITO_POS CONSTANT varchar:='00';
    -- codice_funzione I
    CODICE_FUNZIONE_I CONSTANT varchar:='I';
    -- codice_funzione A
    CODICE_FUNZIONE_A CONSTANT varchar:='A';

	ORD_TIPO_SPESA CONSTANT varchar :='P';
    ORD_TIPO_ENTRATA CONSTANT varchar :='I';

    PROVC_TIPO_SPESA CONSTANT varchar :='S';
    PROVC_TIPO_ENTRATA CONSTANT varchar :='E';



    ordTipoSpesaId integer:=null;
    ordTipoEntrataId integer:=null;

	provCTipoSpesaId integer:=null;
    provCTipoEntrataId integer:=null;

	flussoMifTipoId integer:=null;
    tipoFlusso VARCHAR(200):=null;
    dataOraFlusso VARCHAR(200):=null;
    codiceAbiBt VARCHAR(200):=null;
    codiceEnteBt VARCHAR(200):=null;
    numRicevute VARCHAR(200):=null;

    oilRicevutaTipoId integer:=null;
    oilRicevutaTipoCodeFl varchar(10) :=null;


    enteOilRec record;
    ricevutaRec record;

	bilancioId integer:=null;
	periodoId integer:=null;

    codResult integer :=null;
    codErrore varchar(10) :=null;

    oilRicevutaId  integer :=null;
    provCId integer :=null;

	codErroreId integer:=null;
    provvCEsisteCodeErrId integer:=null;

    -- 10.02.2017 Sofia HD-INC000001550316
    provvCNonEsisteCodeErrId integer:=null;
    provvCStornatoCodeErrId integer:=null;
    provvCImpStornatoCodeErrId integer:=null;

	dataAnnullamento timestamp:=null;
    importoProvvisorio numeric:=null;

	countOrdAgg numeric:=0;
BEGIN

	strMessaggioFinale:='Elaborazione flusso provvisori tipo flusso='||tipoFlussoMif||'.Identificativo flusso='||flussoElabMifId||'.';

    codiceRisultato:=0;
    countOrdAggRisultato:=0;
    messaggioRisultato:='';

	strMessaggio:='Lettura identificativo tipo flusso.';
    select tipo.flusso_elab_mif_tipo_id into  flussoMifTipoId
    from mif_d_flusso_elaborato_tipo tipo
    where tipo.flusso_elab_mif_tipo_code=tipoFlussoMif
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    and   tipoFlussoMif=PROVC_MIF_ELAB_FLUSSO_TIPO;

    if flussoMifTipoId is null then
    	raise exception ' Dato non reperito.';
    end if;

    strMessaggio:='Verifica esistenza identificativo flusso passato [mif_t_flusso_elaborato].';
    select distinct 1 into codResult
    from mif_t_flusso_elaborato mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   mif.data_cancellazione is null
    and   mif.validita_fine is null
    and   mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;

    if codResult is null then
    	raise exception ' Dato non reperito.';
    end if;

	-- letture enteOIL
    strMessaggio:='Lettura dati ente OIL.';
    select * into strict enteOilRec
    from siac_t_ente_oil
    where ente_proprietario_id=enteProprietarioId;


    -- verifica  elaborazioni diverse da quella passata non completata
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_flusso_elaborato].';
    select distinct 1 into codResult
    from mif_t_flusso_elaborato mif
    where mif.flusso_elab_mif_id!=flussoElabMifId
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   mif.data_cancellazione is null
    and   mif.validita_fine is null
    and   mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;

    -- verifca esistenza mif_t_oil_ricevuta ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_oil_ricevuta].';
    select distinct 1  into codResult
    from mif_t_oil_ricevuta m, mif_t_flusso_elaborato mif
    where m.ente_proprietario_id=enteProprietarioId
    and   mif.flusso_elab_mif_id=m.flusso_elab_mif_id
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   m.data_cancellazione is null
    and   m.validita_fine is null
    and   mif.data_cancellazione is null
    and   mif.validita_fine is NULL;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;

	-- verifica esistenza mif_t_elab_emat_hrer ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emat_hrer].';
    select distinct 1  into codResult
    from  mif_t_elab_emat_hrer m, mif_t_flusso_elaborato mif
    where m.ente_proprietario_id=enteProprietarioId
    and   mif.flusso_elab_mif_id=m.flusso_elab_mif_id
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   m.data_cancellazione is null
    and   m.validita_fine is null
    and   mif.data_cancellazione is null
    and   mif.validita_fine is NULL;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;

	-- verifca esistenza mif_t_elab_emat_rr ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emat_rr].';
    select distinct 1  into codResult
    from  mif_t_elab_emat_rr m, mif_t_flusso_elaborato mif
    where m.ente_proprietario_id=enteProprietarioId
    and   mif.flusso_elab_mif_id=m.flusso_elab_mif_id
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   m.data_cancellazione is null
    and   m.validita_fine is null
    and   mif.data_cancellazione is null
    and   mif.validita_fine is NULL;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;


	-- verifca esistenza mif_t_emat_hrer
    strMessaggio:='Verifica esistenza record da elaborare [mif_t_emat_hrer].';
    select distinct 1  into codResult
    from  mif_t_emat_hrer m
    where m.flusso_elab_mif_id=flussoElabMifId
    and   m.ente_proprietario_id=enteProprietarioId;

    if codResult is null then
    	raise exception ' Nessun record da elaborare.';
    end if;

    -- inserimento mif_t_emat_hrer
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emat_hrer da mif_t_emat_hrer].';
    insert into mif_t_elab_emat_hrer
    ( flusso_elab_mif_id,
	  id,
      tipo_record,
      data_ora_flusso,
      tipo_flusso,
      codice_abi_bt,
      codice_ente_bt,
      tipo_servizio,
      aid,
      num_ricevute,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select
      flusso_elab_mif_id,
	  id,
      tipo_record,
      data_ora_flusso,
      tipo_flusso,
      codice_abi_bt,
      codice_ente_bt,
      tipo_servizio,
      aid,
      num_ricevute,
      now(),
      loginOperazione,
      enteProprietarioId
     from mif_t_emat_hrer mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );

    -- inserimento mif_t_elab_emat_rr
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emat_rr da mif_t_emat_rr].';
    insert into mif_t_elab_emat_rr
    ( flusso_elab_mif_id,
      id,
      tipo_record,
      progressivo_ricevuta,
      data_messaggio,
      ora_messaggio,
      esito_derivato,
      qualificatore,
      codice_esito,
      codice_abi_bt,
      codice_ente,
      codice_ente_bt,
      codice_funzione,
      numero_ordinativo,
      esercizio,
      data_ordinativo,
	  importo_ordinativo,
      nome_cognome,
	  causale,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select
      flusso_elab_mif_id,
      id,
      tipo_record,
      progressivo_ricevuta,
      data_messaggio,
      ora_messaggio,
      esito_derivato,
      qualificatore,
      codice_esito,
      codice_abi_bt,
      codice_ente,
      codice_ente_bt,
      codice_funzione,
      numero_ordinativo,
      esercizio,
      data_ordinativo,
	  importo_ordinativo,
      nome_cognome,
	  causale,
      now(),
      loginOperazione,
      enteProprietarioId
     from mif_t_emat_rr mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );


	-- lettura tipoRicevuta
    strMessaggio:='Lettura tipo ricevuta '||PROVC_MIF_FLUSSO_TIPO_CODE||'.';
	select tipo.oil_ricevuta_tipo_id, coalesce(tipo.oil_ricevuta_tipo_code_fl ,PROVC_MIF_FLUSSO_TIPO_CODE)
           into strict oilRicevutaTipoId, oilRicevutaTipoCodeFl
    from siac_d_oil_ricevuta_tipo tipo
    where tipo.oil_ricevuta_tipo_code=PROVC_MIF_FLUSSO_TIPO_CODE
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


	-- lettura dati bilancio
    strMessaggio:='Lettura dati bilancio per anno='||annoBilancio||'.';
	select bil.bil_id, per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where per.anno=annoBilancio::varchar
    and   per.ente_proprietario_id=enteProprietarioId
    and   bil.periodo_id=per.periodo_id;

	-- lettura ordTipoSpesaId
    strMessaggio:='Lettura Id tipo ordinativo='||ORD_TIPO_SPESA||'.';
    select tipo.ord_tipo_id into strict ordTipoSpesaId
    from siac_d_ordinativo_tipo tipo
    where tipo.ord_tipo_code=ORD_TIPO_SPESA
    and   tipo.ente_proprietario_id=enteProprietarioId;

	-- lettura ordTipoEntrataId
    strMessaggio:='Lettura Id tipo ordinativo='||ORD_TIPO_ENTRATA||'.';
    select tipo.ord_tipo_id into strict ordTipoEntrataId
    from siac_d_ordinativo_tipo tipo
    where tipo.ord_tipo_code=ORD_TIPO_ENTRATA
    and   tipo.ente_proprietario_id=enteProprietarioId;

    -- lettura provCTipoSpesaId
    strMessaggio:='Lettura Id tipo ordinativo='||PROVC_TIPO_SPESA||'.';
    select tipo.provc_tipo_id into strict provCTipoSpesaId
    from siac_d_prov_cassa_tipo tipo
    where tipo.provc_tipo_code=PROVC_TIPO_SPESA
    and   tipo.ente_proprietario_id=enteProprietarioId;

    -- lettura provCTipoEntrataId
    strMessaggio:='Lettura Id tipo ordinativo='||PROVC_TIPO_ENTRATA||'.';
    select tipo.provc_tipo_id into strict provCTipoEntrataId
    from siac_d_prov_cassa_tipo tipo
    where tipo.provc_tipo_code=PROVC_TIPO_ENTRATA
    and   tipo.ente_proprietario_id=enteProprietarioId;


	-- provvCEsisteCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_ESISTE_COD_ERR||' per verifica esistenza provvisorio.';
    select errore.oil_ricevuta_errore_id into strict provvCEsisteCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_ESISTE_COD_ERR;

    -- 10.02.2017 Sofia HD-INC000001550316
	-- provvCNonEsisteCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_S_COD_ERR||' per verifica esistenza provvisorio.';
    select errore.oil_ricevuta_errore_id into strict provvCNonEsisteCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_COD_ERR;


    -- 10.02.2017 Sofia HD-INC000001550316
	-- provvCStornatoCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_S_STO_COD_ERR||' provvisorio stornato.';
    select errore.oil_ricevuta_errore_id into strict provvCStornatoCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_STO_COD_ERR;

    -- 10.02.2017 Sofia HD-INC000001550316
	-- provvCImpStornatoCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_S_IMP_COD_ERR||' provvisorio importo < stornato.';
    select errore.oil_ricevuta_errore_id into strict provvCImpStornatoCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_IMP_COD_ERR;


	-- controlli di integrita flusso
    strMessaggio:='Verifica integrita'' flusso-esistenza record di testata ['||TIPO_REC_TESTA||'].';
    codResult:=null;
    select distinct 1  into codResult
    from mif_t_elab_emat_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_TESTA;

    if codResult is null then
    	codErrore:=MIF_TESTATA_COD_ERR;
        raise exception ' COD.ERRORE=%',codErrore;
    end if;


	strMessaggio:='Verifica integrita'' flusso-esistenza record di coda ['||TIPO_REC_CODA||'].';
    codResult:=null;
    select distinct 1  into codResult
    from mif_t_elab_emat_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_CODA;

    if codResult is null then
    	codErrore:=MIF_CODA_COD_ERR;
        raise exception ' COD.ERRORE=%',codErrore;
    end if;


    strMessaggio:='Verifica integrita'' flusso-controlli record di testata ['||TIPO_REC_TESTA||'].';
    codResult:=null;
    select mif.id, mif.tipo_flusso, mif.data_ora_flusso , mif.codice_abi_bt, mif.codice_ente_bt, mif.num_ricevute
           into codResult, tipoFlusso, dataOraFlusso, codiceAbiBt, codiceEnteBt, numRicevute
    from mif_t_elab_emat_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_TESTA;

    if codResult is null then
    	codErrore:=MIF_TESTATA_COD_ERR;
    end if;
    if codErrore is null and
       ( tipoFlusso is null or tipoFlusso='' or tipoFlusso!=oilRicevutaTipoCodeFl ) then
    	codErrore:=MIF_FLUSSO_PC_COD_ERR;
    end if;

    if codErrore is null and
       ( dataOraFlusso is null or dataOraFlusso='' ) then
    	codErrore:=MIF_DT_ORA_TESTA_COD_ERR;
    end if;

    if codErrore is null and
       ( numRicevute is null or numRicevute='' ) then
	    codErrore:=MIF_RICEVUTE_TESTA_COD_ERR;
    end if;

    if codErrore is null and
       ( codiceAbiBt is null or codiceAbiBt='' or codiceAbiBt!=enteOilRec.ente_oil_abi or
         codiceEnteBt is null or codiceEnteBt='' or codiceEnteBt!=enteOilRec.ente_oil_codice ) then
         codErrore:=MIF_DATI_ENTE_TESTA_COD_ERR;
    end if;

    if codErrore is null then
     strMessaggio:='Verifica integrita'' flusso-controlli record di coda ['||TIPO_REC_CODA||'].';
     codResult:=null;
     tipoFlusso:=null;
     dataOraFlusso:=null;
     codiceAbiBt:=null;
     codiceEnteBt:=null;
     numRicevute:=null;
     select mif.id, mif.tipo_flusso, mif.data_ora_flusso , mif.codice_abi_bt, mif.codice_ente_bt, mif.num_ricevute
           into codResult, tipoFlusso, dataOraFlusso, codiceAbiBt, codiceEnteBt, numRicevute
     from mif_t_elab_emat_hrer  mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.tipo_record=TIPO_REC_CODA;


      if codResult is null then
    	codErrore:=MIF_CODA_COD_ERR;
      end if;
      if codErrore is null and
       ( tipoFlusso is null or tipoFlusso='' or tipoFlusso!=oilRicevutaTipoCodeFl ) then
    	codErrore:=MIF_FLUSSO_PC_COD_ERR;
      end if;

      if codErrore is null and
       ( dataOraFlusso is null or dataOraFlusso='' ) then
    	codErrore:=MIF_DT_ORA_CODA_COD_ERR;
      end if;

      if codErrore is null and
       ( numRicevute is null or numRicevute='' ) then
	    codErrore:=MIF_RICEVUTE_CODA_COD_ERR;
      end if;

      if codErrore is null and
        ( codiceAbiBt is null or codiceAbiBt='' or codiceAbiBt!=enteOilRec.ente_oil_abi or
         codiceEnteBt is null or codiceEnteBt='' or codiceEnteBt!=enteOilRec.ente_oil_codice ) then
         codErrore:=MIF_DATI_ENTE_CODA_COD_ERR;
      end if;
    end if;

    -- verifica integrita'' flusso esistenza di un record RR
	if codErrore is null then
    	strMessaggio:='Verifica integrita'' flusso-esistenza record di ricevuta ['||TIPO_REC_RR||'].';
    	codResult:=null;
   		select distinct 1  into codResult
   		from mif_t_elab_emat_rr  mif
    	where mif.flusso_elab_mif_id=flussoElabMifId
   		and   mif.tipo_record=TIPO_REC_RR;

        if codResult is null then
        	codErrore:=MIF_RR_COD_ERR;
        end if;
     end if;


    if codErrore is null then
    	codResult:=null;
        strMessaggio:='Verifica integrita'' flusso-esistenza record di ricevuta con tipo record '||TIPO_REC_RR||'errato.';
    	select distinct 1 into codResult
        from mif_t_elab_emat_rr mif
        where mif.flusso_elab_mif_id=flussoElabMifId
   		and   ( mif.tipo_record is null or mif.tipo_record='' or mif.tipo_record!=TIPO_REC_RR);

        if codResult is not null then
        	codErrore:=MIF_RR_NO_TIPO_REC_COD_ERR;
        end if;
    end if;


	if codErrore is not null then
	    raise exception ' COD.ERRORE=%',codErrore;
    end if;


    -- inserimento in mif_t_ricevuta_oil scarti
    -- MIF_RR_PROGR_RIC_COD_ERR progressivo_ricevuta non valorizzato
    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] con progressivo_ricevuta non valorizzato.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
     from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   (rr.progressivo_ricevuta is null or rr.progressivo_ricevuta='')
     and errore.oil_ricevuta_errore_code=MIF_RR_PROGR_RIC_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId);

     -- MIF_RR_DATA_MSG_COD_ERR data_messaggio o ora_messaggio non valorizzato
    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] con data o ora messaggio non valorizzato.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
     from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   (rr.data_messaggio is null or rr.data_messaggio='' or
            rr.ora_messaggio is null or rr.ora_messaggio='')
     and errore.oil_ricevuta_errore_code=MIF_RR_DATA_MSG_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_ESITO_DER_COD_ERR esito_derivato  non valorizzato o non censito
    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] esito_derivato non valorizzato.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
     from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   ( rr.esito_derivato is null or rr.esito_derivato ='')
     and errore.oil_ricevuta_errore_code=MIF_RR_ESITO_DER_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


    -- MIF_RR_ESITO_DER_COD_ERR esito_derivato  non valorizzato o non censito
    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] esito_derivato non noto.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
     from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   rr.esito_derivato is not null and  rr.esito_derivato !=''
     and   not exists (select distinct 1 from siac_d_oil_esito_derivato d, siac_d_oil_ricevuta_tipo tipo
     				   where d.oil_esito_derivato_code=rr.esito_derivato
                       and   d.ente_proprietario_id=enteProprietarioId
                       and   tipo.oil_ricevuta_tipo_id=d.oil_ricevuta_tipo_id
                       and   tipo.oil_ricevuta_tipo_code in (PROVC_ST_MIF_FLUSSO_TIPO_CODE,PROVC_MIF_FLUSSO_TIPO_CODE)
     				  )
     and errore.oil_ricevuta_errore_code=MIF_RR_ESITO_DER_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

    -- MIF_RR_DATI_ENTE_COD_ERR dati ente  non valorizzati o errati
    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] dati ente non valorizzati o errati.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
     from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   ( rr.codice_abi_bt is null or rr.codice_abi_bt='' or rr.codice_abi_bt!=enteOilRec.ente_oil_abi or
             rr.codice_ente_bt is null or rr.codice_ente_bt='' or rr.codice_ente_bt!=enteOilRec.ente_oil_codice)
     and errore.oil_ricevuta_errore_code=MIF_RR_DATI_ENTE_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

      -- MIF_RR_ESITO_NEG_COD_ERR codice esito non positivo !=00
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] codice esito non valorizzati o non positivo.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.codice_esito is null or rr.codice_esito='' or rr.codice_esito !=CODICE_ESITO_POS)
      and errore.oil_ricevuta_errore_code=MIF_RR_ESITO_NEG_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_COD_FUNZIONE_COD_ERR codice_funzione non valorizzato o non ammesso
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] codice funzione non valorizzato o non ammesso.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.codice_funzione is null or rr.codice_funzione='' or
             (rr.codice_funzione !=CODICE_FUNZIONE_I and
              rr.codice_funzione !=CODICE_FUNZIONE_A ))
      and errore.oil_ricevuta_errore_code=MIF_RR_COD_FUNZIONE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_QUALIFICATORE_COD_ERR qualificatore non valorizzato
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] qualificatore non valorizzato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.qualificatore is null or rr.qualificatore='' )
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_QUALIFICATORE_COD_ERR qualificatore non ammesso
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] qualificatore non ammesso.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.qualificatore is not null and rr.qualificatore!=''
      and   not exists ( select distinct 1
                         from siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e, siac_d_oil_ricevuta_tipo tipo
                         where q.oil_qualificatore_code=rr.qualificatore
                         and   q.ente_proprietario_id=enteProprietarioId
                         and   e.oil_esito_derivato_id=q.oil_esito_derivato_id
                         and   e.oil_esito_derivato_code=rr.esito_derivato
                         and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
                         and   tipo.oil_ricevuta_tipo_code in (PROVC_ST_MIF_FLUSSO_TIPO_CODE,PROVC_MIF_FLUSSO_TIPO_CODE)
      				   )
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


     -- MIF_RR_PC_CASSA_COD_ERR dati provvisorio non indicati
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] dati provvisorio non indicati.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   ( rr.esercizio is null or rr.esercizio='' or
	          rr.numero_ordinativo is null or  rr.numero_ordinativo='' or
              rr.data_ordinativo is null or rr.data_ordinativo='' or
              rr.importo_ordinativo is null or rr.importo_ordinativo='')
      and errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_PC_CASSA_ANNO_COD_ERR anno provvisorio di cassa non corretto
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] anno provvisorio di cassa non corretto rispetto all''anno di bilancio corrente.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.esercizio::integer != annoBilancio
      and errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_ANNO_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- MIF_RR_PC_CASSA_DT_COD_ERR data emissione provvisorio di cassa non corretto
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] data emissione provvisorio di cassa non corretto rispetto alla data di elaborazione.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.data_ordinativo::timestamp>dataElaborazione
      and errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_DT_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_PC_CASSA_IMP_COD_ERR importo provvisorio di cassa non corretto
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] importo provvisorio di cassa non corretto.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   round(rr.importo_ordinativo::numeric/100,2)<=0
      and errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_IMP_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- esistenza provvisorio di cassa per ricevuta di inserimento provvisorio - provvisorio esistente
     -- MIF_RR_PROVC_ESISTE_COD_ERR
     -- [provvissorio_cassa_spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa spesa esistente per operazione di inserimento.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoSpesaId
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_ESISTE_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
                        and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa entrata esistente per operazione di inserimento.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoEntrataId
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_ESISTE_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
                        and   rr1.oil_progr_ricevuta_id=rr.id));


     -- esistenza provvissorio di cassa per ricevuta di storno
/* 10.02.2017 Sofia HD-INC000001550316 -
   commentato per gestione in ciclo , per gestione di flussi con inserimento provvisorio e storno
     -- MIF_RR_PROVC_S_COD_ERR provvissorio di cassa non esistente per storno
     -- [provvissorio_cassa_spesa]

     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa spesa non esistente per operazione di storno.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists ( select distinct 1
                         from  siac_t_prov_cassa prov
                         where prov.ente_proprietario_id=enteProprietarioId
                         and   prov.provc_anno=rr.esercizio::integer
                         and   prov.provc_numero=rr.numero_ordinativo::integer
                         and   prov.provc_tipo_id=provCTipoSpesaId
                         and   prov.data_cancellazione is null
                         and   prov.validita_fine is null
                     )
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa entrata non esistente per operazione di storno.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists ( select distinct 1
                         from  siac_t_prov_cassa prov
                         where prov.ente_proprietario_id=enteProprietarioId
                         and   prov.provc_anno=rr.esercizio::integer
                         and   prov.provc_numero=rr.numero_ordinativo::integer
                         and   prov.provc_tipo_id=provCTipoEntrataId
                         and   prov.data_cancellazione is null
                         and   prov.validita_fine is null
                       )
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
      				  where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.id));
   **/
     -- provvissorio di cassa esistente per ricevuta di storno provvisorio completamente stornato (data_annullamento valorizzata )

     -- MIF_RR_PROVC_S_STO_COD_ERR provvissorio di cassa  esistente per storno provv stornato (data_annullamento valorizzata )
     -- [provvissorio_cassa_spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa spesa per operazione di storno provvisorio stornato [data_annullamento valorizzata].';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
       oil_provc_id,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
             prov.provc_id,
             now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoSpesaId
      and   prov.provc_data_annullamento is not null -- stornato
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_STO_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.id));


     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa entrata per operazione di storno provvisorio stornato [data_annullamento valorizzata].';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
       oil_provc_id,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
             prov.provc_id,
             now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoEntrataId
      and   prov.provc_data_annullamento is not null -- stornato
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_STO_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.id));



     -- provvissorio di cassa esistente per ricevuta di storno importo di storno>  importo prov

     -- MIF_RR_PROVC_S_IMP_COD_ERR provvissorio di cassa  esistente per storno importo storno > importo prov
     -- [provvissorio_cassa_spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa spesa per operazione di storno con importo storno maggiore importo provvisorio.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
       oil_provc_id,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
             prov.provc_id,
             now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoSpesaId
      and   prov.provc_importo<round(rr.importo_ordinativo::numeric/100,2)
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_IMP_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa entrata per operazione di storno con importo storno maggiore importo provvisorio.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_tipo,
       oil_provc_id,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             q.oil_qualificatore_segno,
             prov.provc_id,
             now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoEntrataId
      and   prov.provc_importo<round(rr.importo_ordinativo::numeric/100,2)
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_IMP_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


     -- provvissorio di cassa esistente per ricevuta di storno soggetto diverso da denominazione su provvisorio

     -- MIF_RR_PROVC_S_SOG_COD_ERR provvissorio di cassa  esistente per storno soggetto diverso da denominazione su provvisorio
     -- [provvissorio_cassa_spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa spesa per operazione di storno con soggetto non coerente con provvisorio.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_ricevuta_tipo,
       oil_provc_id,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             rr.nome_cognome,
             q.oil_qualificatore_segno,
             prov.provc_id,
             now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   rr.nome_cognome is not null
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoSpesaId
      and   prov.provc_denom_soggetto is not null
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   prov.provc_denom_soggetto!=rr.nome_cognome
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_SOG_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa entrata per operazione di storno con soggetto non coerente con provvisorio.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_ricevuta_tipo,
       oil_provc_id,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,rr.data_ordinativo::timestamp,
             round(rr.importo_ordinativo::numeric/100,2),
             rr.nome_cognome,
             q.oil_qualificatore_segno,
             prov.provc_id,
             now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emat_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_d_oil_ricevuta_tipo tipo, siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   rr.nome_cognome is not null
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   tipo.ente_proprietario_id=enteProprietarioId
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno=rr.esercizio::integer
      and   prov.provc_numero=rr.numero_ordinativo::integer
      and   prov.provc_tipo_id=provCTipoEntrataId
      and   prov.provc_denom_soggetto is not null
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   prov.provc_denom_soggetto!=rr.nome_cognome
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_SOG_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     --- esistenza provvisorio - storno , legato ad un ordinativo

     -- MIF_RR_PROVC_S_REG_COD_ERR provvissorio di cassa  esistente per storno collegato a ordinativo di spesa
     -- [provvissorio_cassa_spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa spesa per operazione di storno regolarizzato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_ricevuta_tipo,
       oil_provc_id,
       oil_ord_bil_id,oil_ord_id, oil_ord_anno_bil,oil_ord_numero,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (with
       provOrd as
       (select distinct rr.id progr_ricevuta, tipo.oil_ricevuta_tipo_id,
               rr.esercizio::integer prov_anno,rr.numero_ordinativo::integer prov_numero,
               rr.data_ordinativo::timestamp prov_data,
	           round(rr.importo_ordinativo::numeric/100,2) prov_importo,
               rr.nome_cognome prov_denominazione,
               q.oil_qualificatore_segno,
               prov.provc_id prov_provc_id,
               ord.bil_id ord_bil_id, ord.ord_id ord_id, ord.ord_numero ord_numero,   per.anno::integer ord_bil_anno
        from   mif_t_elab_emat_rr rr, siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
	           siac_d_oil_ricevuta_tipo tipo,
               siac_t_prov_cassa prov, siac_r_ordinativo_prov_cassa r, siac_t_ordinativo ord,
               siac_t_periodo per, siac_t_bil bil
        where rr.flusso_elab_mif_id=flussoElabMifId
        and   q.oil_qualificatore_code=rr.qualificatore
      	and   q.ente_proprietario_id=enteProprietarioId
	    and   q.oil_qualificatore_segno='U'
    	and   e.oil_esito_derivato_code=rr.esito_derivato
	    and   e.ente_proprietario_id=q.ente_proprietario_id
	    and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	    and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
    	and   tipo.ente_proprietario_id=enteProprietarioId
        and   prov.provc_anno=rr.esercizio::INTEGER
        and   prov.provc_numero=rr.numero_ordinativo::integer
        and   prov.provc_tipo_id=provCTipoSpesaId
        and   prov.data_cancellazione is null
        and   prov.validita_fine is null
        and   r.provc_id=prov.provc_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        and   ord.ord_id=r.ord_id
        and   ord.data_cancellazione is null
        and   ord.validita_fine is NULL
        and   ord.ord_tipo_id=ordTipoSpesaId
        and   bil.bil_id=ord.bil_id
        and   per.periodo_id=bil.periodo_id
       )
       ( select errore.oil_ricevuta_errore_id, provOrd.oil_ricevuta_tipo_id ,flussoElabMifId,
                provOrd.progr_ricevuta, provOrd.prov_anno, provOrd.prov_numero,provOrd.prov_data,
		        provOrd.prov_importo,
                provOrd.prov_denominazione,
		        provOrd.oil_qualificatore_segno,
                provOrd.prov_provc_id,
                provOrd.ord_bil_id, provOrd.ord_id,provOrd.ord_bil_anno,provOrd.ord_numero,
	            now(),enteProprietarioId,loginOperazione
	     from  siac_d_oil_ricevuta_errore errore, provOrd
	     where errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_REG_COD_ERR::varchar
         and   errore.ente_proprietario_id=enteProprietarioId
         and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                 where rr1.flusso_elab_mif_id=flussoElabMifId
         	             and   rr1.oil_progr_ricevuta_id=provOrd.progr_ricevuta)
       ));

	 -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  provvisorio di cassa entrata per operazione di storno regolarizzato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,oil_ricevuta_data,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_ricevuta_tipo,
       oil_provc_id,
       oil_ord_bil_id,oil_ord_id, oil_ord_anno_bil,oil_ord_numero,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (with
       provOrd as
       (select distinct rr.id progr_ricevuta, tipo.oil_ricevuta_tipo_id,
               rr.esercizio::integer prov_anno,rr.numero_ordinativo::integer prov_numero,
               rr.data_ordinativo::timestamp prov_data,
	           round(rr.importo_ordinativo::numeric/100,2) prov_importo,
               rr.nome_cognome prov_denominazione,
               q.oil_qualificatore_segno,
               prov.provc_id prov_provc_id,
               ord.bil_id ord_bil_id, ord.ord_id ord_id, ord.ord_numero ord_numero,   per.anno::integer ord_bil_anno
        from   mif_t_elab_emat_rr rr, siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
	           siac_d_oil_ricevuta_tipo tipo,
               siac_t_prov_cassa prov, siac_r_ordinativo_prov_cassa r, siac_t_ordinativo ord,
               siac_t_periodo per, siac_t_bil bil
        where rr.flusso_elab_mif_id=flussoElabMifId
        and   q.oil_qualificatore_code=rr.qualificatore
      	and   q.ente_proprietario_id=enteProprietarioId
	    and   q.oil_qualificatore_segno='E'
    	and   e.oil_esito_derivato_code=rr.esito_derivato
	    and   e.ente_proprietario_id=q.ente_proprietario_id
	    and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	    and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
    	and   tipo.ente_proprietario_id=enteProprietarioId
        and   prov.provc_anno=rr.esercizio::INTEGER
        and   prov.provc_numero=rr.numero_ordinativo::integer
        and   prov.provc_tipo_id=provCTipoEntrataId
        and   prov.data_cancellazione is null
        and   prov.validita_fine is null
        and   r.provc_id=prov.provc_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        and   ord.ord_id=r.ord_id
        and   ord.data_cancellazione is null
        and   ord.validita_fine is NULL
        and   ord.ord_tipo_id=ordTipoEntrataId
        and   bil.bil_id=ord.bil_id
        and   per.periodo_id=bil.periodo_id
       )
       ( select errore.oil_ricevuta_errore_id, provOrd.oil_ricevuta_tipo_id ,flussoElabMifId,
                provOrd.progr_ricevuta, provOrd.prov_anno, provOrd.prov_numero,provOrd.prov_data,
		        provOrd.prov_importo,
                provOrd.prov_denominazione,
		        provOrd.oil_qualificatore_segno,
                provOrd.prov_provc_id,
                provOrd.ord_bil_id, provOrd.ord_id,provOrd.ord_bil_anno,provOrd.ord_numero,
	            now(),enteProprietarioId,loginOperazione
	     from  siac_d_oil_ricevuta_errore errore, provOrd
	     where errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_REG_COD_ERR::varchar
         and   errore.ente_proprietario_id=enteProprietarioId
         and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                 where rr1.flusso_elab_mif_id=flussoElabMifId
         	             and   rr1.oil_progr_ricevuta_id=provOrd.progr_ricevuta)
       ));



		-- inserimento record da elaborare
    	-- [provvisorio_cassa_spesa]
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ricevuta provvisorio di cassa spesa da elaborare.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,
          flusso_elab_mif_id,
          oil_progr_ricevuta_id,
          oil_provc_id,
          oil_ricevuta_anno,
          oil_ricevuta_numero,
          oil_ricevuta_data,
          oil_ricevuta_importo,
          oil_ricevuta_denominazione,
          oil_ricevuta_note,
	      oil_ricevuta_tipo,
		  validita_inizio,
          ente_proprietario_id,
          login_operazione
	    )
    	(select
          tipo.oil_ricevuta_tipo_id,
          flussoElabMifId,
          rr.id,
--          (case when tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE then
--                     provCassa.provc_id else null end ), 10.02.2017 Sofia HD-INC000001550316
         (case when tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE then -1 else null end ),
     	  rr.esercizio::integer,
          rr.numero_ordinativo::integer,
          rr.data_ordinativo::timestamp,
          round(rr.importo_ordinativo::numeric/100,2),
          rr.nome_cognome,
          rr.causale,
          q.oil_qualificatore_segno,
          now(),enteProprietarioId,loginOperazione
         from  siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
               siac_d_oil_ricevuta_tipo tipo,
               mif_t_elab_emat_rr rr
               left outer join
               (select prov.provc_id,prov.provc_anno, prov.provc_numero, prov.provc_tipo_id
                from siac_t_prov_cassa prov
				where prov.ente_proprietario_id=enteProprietarioId
                and   prov.data_cancellazione is null
                and   prov.validita_fine is null) provCassa
                      on (provCassa.provc_anno=rr.esercizio::integer
                      and provCassa.provc_numero=rr.numero_ordinativo::integer
                      and provCassa.provc_tipo_id=provCTipoSpesaId )
	     where rr.flusso_elab_mif_id=flussoElabMifId
         and   q.oil_qualificatore_code=rr.qualificatore
         and   q.ente_proprietario_id=enteProprietarioId
         and   q.oil_qualificatore_segno='U'
         and   e.oil_esito_derivato_code=rr.esito_derivato
         and   e.ente_proprietario_id=q.ente_proprietario_id
         and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
         and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( PROVC_ST_MIF_FLUSSO_TIPO_CODE,PROVC_MIF_FLUSSO_TIPO_CODE)
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
   	                       where rr1.flusso_elab_mif_id=flussoElabMifId
       	                   and   rr1.oil_progr_ricevuta_id=rr.id));

    	-- [provvisorio_cassa_entrata]
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ricevuta provvisorio di cassa entrata da elaborare.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,
          flusso_elab_mif_id,
          oil_progr_ricevuta_id,
          oil_provc_id,
          oil_ricevuta_anno,
          oil_ricevuta_numero,
          oil_ricevuta_data,
          oil_ricevuta_importo,
          oil_ricevuta_denominazione,
          oil_ricevuta_note,
	      oil_ricevuta_tipo,
		  validita_inizio,
          ente_proprietario_id,
          login_operazione
	    )
    	(select
          tipo.oil_ricevuta_tipo_id,
          flussoElabMifId,
          rr.id,
--          (case when tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE then
--                     provCassa.provc_id else null end ), -- 10.02.2017 Sofia HD-INC000001550316
         (case when tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE then -1  else null end ),
     	  rr.esercizio::integer,
          rr.numero_ordinativo::integer,
          rr.data_ordinativo::timestamp,
          round(rr.importo_ordinativo::numeric/100,2),
          rr.nome_cognome,
          rr.causale,
          q.oil_qualificatore_segno,
          now(),enteProprietarioId,loginOperazione
         from  siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
               siac_d_oil_ricevuta_tipo tipo,
               mif_t_elab_emat_rr rr
               left outer join
               (select prov.provc_id,prov.provc_anno, prov.provc_numero, prov.provc_tipo_id
                from siac_t_prov_cassa prov
				where prov.ente_proprietario_id=enteProprietarioId
                and   prov.data_cancellazione is null
                and   prov.validita_fine is null) provCassa
                      on (provCassa.provc_anno=rr.esercizio::integer
                      and provCassa.provc_numero=rr.numero_ordinativo::integer
                      and provCassa.provc_tipo_id=provCTipoEntrataId )
	     where rr.flusso_elab_mif_id=flussoElabMifId
         and   q.oil_qualificatore_code=rr.qualificatore
         and   q.ente_proprietario_id=enteProprietarioId
         and   q.oil_qualificatore_segno='E'
         and   e.oil_esito_derivato_code=rr.esito_derivato
         and   e.ente_proprietario_id=q.ente_proprietario_id
         and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
         and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( PROVC_ST_MIF_FLUSSO_TIPO_CODE,PROVC_MIF_FLUSSO_TIPO_CODE)
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
   	                       where rr1.flusso_elab_mif_id=flussoElabMifId
       	                   and   rr1.oil_progr_ricevuta_id=rr.id));


    strMessaggio:='Inizio ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta].';
	for ricevutaRec in
    (
	 select mif.oil_progr_ricevuta_id,
     	    mif.oil_provc_id,
            mif.oil_ricevuta_tipo_id,
            mif.oil_ricevuta_anno,
      	    mif.oil_ricevuta_numero,
            mif.oil_ricevuta_data,
            mif.oil_ricevuta_importo,
            mif.oil_ricevuta_note,
            mif.oil_ricevuta_denominazione,
            mif.oil_ricevuta_tipo
     from mif_t_oil_ricevuta mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.oil_ricevuta_errore_id is null
     order by mif.oil_progr_ricevuta_id
    )
    loop
		codResult:=null;
        oilRicevutaId:=null;
		provCId:=null;
		codErroreId:=null;

        -- 10.02.2017 Sofia HD-INC000001550316
        dataAnnullamento:=null;
        importoProvvisorio:=null;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';


        if ricevutaRec.oil_provc_id is null then
			strMessaggio:='Verifica esistenza provvisorio di cassa prima di operazione inserimento [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
			select cassa.provc_id into codResult
            from siac_t_prov_cassa cassa
            where cassa.ente_proprietario_id=enteProprietarioId
            and   cassa.provc_anno=ricevutaRec.oil_ricevuta_anno
            and   cassa.provc_numero=ricevutaRec.oil_ricevuta_numero
            and   cassa.provc_tipo_id=(case when ricevutaRec.oil_ricevuta_tipo='U' then provCTipoSpesaId else provCTipoEntrataId END)
            and   cassa.data_cancellazione is null
            and   cassa.validita_fine is null;

            if codResult is not null then
            	codErroreId:=provvCEsisteCodeErrId;
                provCId:=codResult;
        	end if;
		elsif ricevutaRec.oil_provc_id=-1 then -- 10.02.2017 Sofia HD-INC000001550316
        	strMessaggio:='Verifica esistenza provvisorio di cassa prima di operazione storno [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
			select cassa.provc_id, cassa.provc_data_annullamento, cassa.provc_importo
                 into codResult, dataAnnullamento, importoProvvisorio
            from siac_t_prov_cassa cassa
            where cassa.ente_proprietario_id=enteProprietarioId
            and   cassa.provc_anno=ricevutaRec.oil_ricevuta_anno
            and   cassa.provc_numero=ricevutaRec.oil_ricevuta_numero
            and   cassa.provc_tipo_id=(case when ricevutaRec.oil_ricevuta_tipo='U' then provCTipoSpesaId else provCTipoEntrataId END)
            and   cassa.data_cancellazione is null
            and   cassa.validita_fine is null;


            if codResult is null then                    -- provvisorio inesistente
            	codErroreId:=provvCNonEsisteCodeErrId;
            elsif dataAnnullamento is not null then      -- provvisorio completamente stornato
             	codErroreId:=provvCStornatoCodeErrId;
            elsif importoProvvisorio<ricevutaRec.oil_ricevuta_importo then -- provvisorio con storno superiore di importo cassa
            	codErroreId:=provvCImpStornatoCodeErrId;
            end if;

            if codErroreId is null then
	            provCId:=codResult;
                ricevutaRec.oil_provc_id:=codResult;
            end if;

           /* -- 10.02.2017 Sofia HD-INC000001550316
            if codResult is  null then
            	codErroreId:=provvCEsisteCodeErrId;
            else
                provCId:=codResult;
                ricevutaRec.oil_provc_id:=codResult;
        	end if; */
        end if;

		strMessaggio:='Inserimento  ricevuta [siac_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
		-- inserimento siac_t_oil_ricevuta
       	insert into siac_t_oil_ricevuta
   		( oil_ricevuta_anno,
          oil_ricevuta_numero,
   	      oil_ricevuta_data,
   	      oil_ricevuta_importo,
          oil_ricevuta_denominazione,
          oil_ricevuta_note,
  		  oil_ricevuta_tipo,
   	      oil_ricevuta_tipo_id,
          oil_ricevuta_errore_id,
          flusso_elab_mif_id,
   	      oil_progr_ricevuta_id,
          validita_inizio,
	      ente_proprietario_id,
		  login_operazione)
        values
       	( ricevutaRec.oil_ricevuta_anno,
          ricevutaRec.oil_ricevuta_numero,
   	      ricevutaRec.oil_ricevuta_data,
          ricevutaRec.oil_ricevuta_importo,
          ricevutaRec.oil_ricevuta_denominazione,
          ricevutaRec.oil_ricevuta_note,
       	  ricevutaRec.oil_ricevuta_tipo,
          ricevutaRec.oil_ricevuta_tipo_id,
          codErroreId, -- solo per provvCEsisteCodeErrId
          flussoElabMifId,
          ricevutaRec.oil_progr_ricevuta_id,
          now(),
		  enteProprietarioId,
          loginOperazione
    	)
      	returning oil_ricevuta_id into oilRicevutaId;

        if oilRicevutaId is null then
           	raise exception ' Errore in inserimento.';
        end if;

        if codErroreId is null then


		 if ricevutaRec.oil_provc_id is null then

			strMessaggio:='Inserimento provvissorio di cassa [siac_t_prov_cassa] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
        	insert into siac_t_prov_cassa
            (provc_anno,
			 provc_numero,
			 provc_causale,
			 provc_denom_soggetto,
			 provc_data_emissione,
			 provc_importo,
			 provc_tipo_id,
             validita_inizio,
             login_operazione,
             ente_proprietario_id)
            values
            (ricevutaRec.oil_ricevuta_anno,
             ricevutaRec.oil_ricevuta_numero,
             ricevutaRec.oil_ricevuta_note,
             ricevutaRec.oil_ricevuta_denominazione,
             ricevutaRec.oil_ricevuta_data,
             ricevutaRec.oil_ricevuta_importo,
             (case when ricevutaRec.oil_ricevuta_tipo='U' then provCTipoSpesaId else provCTipoEntrataId END),
             now(),
             loginOperazione,
             enteProprietarioId
            )
            returning provc_id into provCId;

            if provCId is null then
            	raise exception ' Errore in inserimento.';
            end if;
         else
        	strMessaggio:='Aggiornamento provvissorio di cassa per storno [siac_t_prov_cassa] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
        	update siac_t_prov_cassa set
               provc_importo=provc_importo-ricevutaRec.oil_ricevuta_importo,
               data_modifica=now(),
               login_operazione=loginOperazione,
               provc_data_annullamento=(case when provc_importo-ricevutaRec.oil_ricevuta_importo=0 then now() else null end)
            where provc_id=ricevutaRec.oil_provc_id;

            provCId:=  ricevutaRec.oil_provc_id;
         end if;

        end if;

        codResult:=null;
    	strMessaggio:='Inserimento relazione provvissorio di cassa - ricevuta [siac_r_prov_cassa_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
        insert into siac_r_prov_cassa_oil_ricevuta
        (provc_id,
	     oil_ricevuta_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id )
         values
         (provCId,
          oilRicevutaId,
          now(),
          loginOperazione,
          enteProprietarioId
         )
         returning provc_oil_ricevuta_id into codResult;

         if codResult is null then
         	raise exception ' Errore in inserimento.';
         end if;

       -- aggiorno contatore provvisori elaborati
       countOrdAgg:=countOrdAgg+1;

    end loop;

	strMessaggio:='Inserimento scarti ricevute [siac_oil_ricevute] dopo ciclo di elaborazione.';
    -- inserire in siac_t_oil_ricevuta i dati scartati presenti in mif_t_oil_ricevuta
    insert into siac_t_oil_ricevuta
    ( oil_ricevuta_anno,
      oil_ricevuta_numero,
   	  oil_ricevuta_data,
   	  oil_ricevuta_importo,
      oil_ricevuta_denominazione,
      oil_ricevuta_note,
  	  oil_ricevuta_tipo,
   	  oil_ricevuta_tipo_id,
      flusso_elab_mif_id,
   	  oil_progr_ricevuta_id,
      oil_ricevuta_errore_id,
      validita_inizio,
	  ente_proprietario_id,
	  login_operazione)
    ( select
       m.oil_ricevuta_anno,
       m.oil_ricevuta_numero,
       m.oil_ricevuta_data,
       m.oil_ricevuta_importo,
       m.oil_ricevuta_denominazione,
       m.oil_ricevuta_note,
       m.oil_ricevuta_tipo,
       m.oil_ricevuta_tipo_id,
       flussoElabMifId,
       m.oil_progr_ricevuta_id,
       m.oil_ricevuta_errore_id,
       now(),
	   enteProprietarioId,
       loginOperazione
     from  mif_t_oil_ricevuta m
     where m.flusso_elab_mif_id=flussoElabMifId
     and   m.oil_ricevuta_errore_id is not null
     order by m.oil_ricevuta_id);

	-- verificare se altre tab temporanee da cancellare
    -- cancellazione tabelle temporanee
    -- cancellare mif_t_oil_ricevuta
    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_hrer flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emat_hrer where flusso_elab_mif_id=flussoElabMifId;
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_rr flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emat_rr  where flusso_elab_mif_id=flussoElabMifId;

    -- chiudere elaborazione
	-- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
    strMessaggio:='Elaborazione flusso provvisori.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId||'.'
                  ||'Aggiornati provvisori num='||countOrdAgg||'.';
    update  mif_t_flusso_elaborato
    set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
   	   ('OK','ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '||PROVC_MIF_ELAB_FLUSSO_TIPO||'. AGGIORNATI NUM='||countOrdAgg||' PROVVISORI.',countOrdAgg,now())
    where flusso_elab_mif_id=flussoElabMifId;

--    messaggioRisultato:=strMessaggioFinale||' Elaborazione conclusa OK.';
    messaggioRisultato:=strMessaggio;
    messaggioRisultato:=upper(messaggioRisultato);
    countOrdAggRisultato:=countOrdAgg;

    return;

exception
    when RAISE_EXCEPTION THEN
		if codErrore is null then
         messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
        else
        	messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
        end if;
     	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

  		-- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emat_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emat_rr  where flusso_elab_mif_id=flussoElabMifId;

       	update  mif_t_flusso_elaborato
   		set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
  		('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
	    where flusso_elab_mif_id=flussoElabMifId;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emat_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emat_rr  where flusso_elab_mif_id=flussoElabMifId;

		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
		where flusso_elab_mif_id=flussoElabMifId;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_hrer flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emat_hrer where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_rr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emat_rr  where flusso_elab_mif_id=flussoElabMifId;


		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
		where flusso_elab_mif_id=flussoElabMifId;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_hrer flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emat_hrer where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emat_rr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emat_rr  where flusso_elab_mif_id=flussoElabMifId;

        update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
		where flusso_elab_mif_id=flussoElabMifId;

        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;