/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_quietanze
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

    -- codice_esito positivo
    CODICE_ESITO_POS CONSTANT varchar:='00';
    -- codice_funzione I
    CODICE_FUNZIONE_I CONSTANT varchar:='I';

	ORD_TIPO_SPESA CONSTANT varchar :='P';
    ORD_TIPO_ENTRATA CONSTANT varchar :='I';

    ORD_STATO_ANNULLATO CONSTANT varchar:='A';
    ORD_STATO_QUIET CONSTANT varchar:='Q';
    ORD_STATO_FIRMA CONSTANT varchar:='F';
    ORD_STATO_TRASM CONSTANT varchar:='T';

	ORD_TS_DET_TIPO_A   CONSTANT varchar:='A';
	PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';
    COM_PCC_ATTR  CONSTANT  varchar :='flagComunicaPCC';

    INVIO_EMAIL_TIPO_FLUSSO CONSTANT varchar:='INVIO_AVVISO_EMAIL_BONIF';

    -- 20.04.2017 Sofia invio email bonifico
    flussoElabEmailMifId integer:=null;
    emailRec record;

    ordTipoSpesaId integer:=null;
    ordTipoEntrataId integer:=null;
    ordStatoAnnullatoId integer:=null;

	flussoMifTipoId integer:=null;
    tipoFlusso VARCHAR(200):=null;
    dataOraFlusso VARCHAR(200):=null;
    codiceAbiBt VARCHAR(200):=null;
    codiceEnteBt VARCHAR(200):=null;
    numRicevute VARCHAR(200):=null;

    oilRicevutaTipoId integer:=null;
    oilRicevutaTipoCodeFl varchar(10) :=null;

	ordTsDetTipoId integer:=null;
	ordStatoFirmaId integer:=null;
    ordStatoTrasmId integer:=null;
    ordStatoQuietId integer:=null;
	pccOperazTipoId integer:=null;
	comPccAttrId integer:=null;

    enteOilRec record;
    ricevutaRec record;

	bilancioId integer:=null;
	periodoId integer:=null;

    codResult integer :=null;
    codErrore varchar(10) :=null;

    numeroRicevuta integer :=null;
    oilRicevutaId  integer :=null;
    oilProgrDettRicevutaId integer :=null;
    importoOrdinativo numeric :=0;
    importoQuiet numeric :=null;
    importoStorno numeric :=null;
    ordStatoId integer :=null;
    ordCambioStatoId integer :=null;
    ordStatoRId integer :=null;
    ordStatoRChiudiId integer :=null;
    ordStatoApriId integer :=null;

	countOrdAgg numeric:=0;
BEGIN

	strMessaggioFinale:='Elaborazione flusso quietanze tipo flusso='||tipoFlussoMif||'.Identificativo flusso='||flussoElabMifId||'.';

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
    and   tipoFlussoMif=QUIET_MIF_ELAB_FLUSSO_TIPO;

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

	-- verifca esistenza mif_t_elab_emap_hrer ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emap_hrer].';
    select distinct 1  into codResult
    from  mif_t_elab_emap_hrer m, mif_t_flusso_elaborato mif
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

	-- verifca esistenza mif_t_elab_emap_rr ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emap_rr].';
    select distinct 1  into codResult
    from  mif_t_elab_emap_rr m, mif_t_flusso_elaborato mif
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

	-- verifca esistenza mif_t_elab_emap_dr ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emap_dr].';
    select distinct 1  into codResult
    from  mif_t_elab_emap_dr m, mif_t_flusso_elaborato mif
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

	-- verifca esistenza mif_t_emap_hrer
    strMessaggio:='Verifica esistenza record da elaborare [mif_t_emap_hrer].';
    select distinct 1  into codResult
    from  mif_t_emap_hrer m
    where m.flusso_elab_mif_id=flussoElabMifId
    and   m.ente_proprietario_id=enteProprietarioId;

    if codResult is null then
    	raise exception ' Nessun record da elaborare.';
    end if;

    -- inserimento mif_t_elab_emap_hrer
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emap_hrer da mif_t_emap_hrer].';
    insert into mif_t_elab_emap_hrer
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
     from mif_t_emap_hrer mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );

    -- inserimento mif_t_elab_emap_rr
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emap_rr da mif_t_emap_rr].';
    insert into mif_t_elab_emap_rr
    ( flusso_elab_mif_id,
      id,
      tipo_record,
      progressivo_ricevuta,
      data_messaggio,
      ora_messaggio,
      esito_derivato,
      qualificatore,
      codice_abi_bt,
      codice_ente,
      codice_ente_bt,
      codice_funzione,
      numero_ordinativo,
      esercizio,
      codice_esito,
      data_pagamento,
      importo_ordinativo,
      cro1,
      cro2,
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
      codice_abi_bt,
      codice_ente,
      codice_ente_bt,
      codice_funzione,
      numero_ordinativo,
      esercizio,
      codice_esito,
      data_pagamento,
      importo_ordinativo,
      cro1,
      cro2,
      now(),
      loginOperazione,
      enteProprietarioId
     from mif_t_emap_rr mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );

    -- inserimento mif_t_elab_emap_rr
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emap_dr da mif_t_emap_dr].';
    insert into mif_t_elab_emap_dr
    (flusso_elab_mif_id,
     id,
     tipo_record,
     progressivo_ricevuta,
     num_ricevuta,
     importo_ricevuta,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select
      flusso_elab_mif_id,
      id,
      tipo_record,
      progressivo_ricevuta,
      num_ricevuta,
      importo_ricevuta,
      now(),
      loginOperazione,
      enteProprietarioId
     from mif_t_emap_dr mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );

	-- letture enteOIL
    strMessaggio:='Lettura dati ente OIL.';
    select * into strict enteOilRec
    from siac_t_ente_oil
    where ente_proprietario_id=enteProprietarioId;

	-- lettura tipoRicevuta
    strMessaggio:='Lettura tipo ricevuta '||QUIET_MIF_FLUSSO_TIPO_CODE||'.';
	select tipo.oil_ricevuta_tipo_id, coalesce(tipo.oil_ricevuta_tipo_code_fl ,QUIET_MIF_FLUSSO_TIPO)
           into strict oilRicevutaTipoId, oilRicevutaTipoCodeFl
    from siac_d_oil_ricevuta_tipo tipo
    where tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE
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

    -- lettura ordTsDetTipoId
    strMessaggio:='Lettura Id tipo importo ordinativo='||ORD_TS_DET_TIPO_A||'.';
    select  tipo.ord_ts_det_tipo_id into strict ordTsDetTipoId
    from siac_d_ordinativo_ts_det_tipo tipo
    where tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
    and   tipo.ente_proprietario_id=enteProprietarioId;

	-- lettura ordStatoAnnullatoId
    strMessaggio:='Lettura Id stato ordinativo='||ORD_STATO_ANNULLATO||'.';
    select stato.ord_stato_id into strict ordStatoAnnullatoId
    from siac_d_ordinativo_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and stato.ord_stato_code=ORD_STATO_ANNULLATO;


	-- lettura ordStatoQuietId
    strMessaggio:='Lettura Id stato ordinativo='||ORD_STATO_QUIET||'.';
    select stato.ord_stato_id into strict ordStatoQuietId
    from siac_d_ordinativo_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and stato.ord_stato_code=ORD_STATO_QUIET;

	-- lettura ordStatoFirmaId
    strMessaggio:='Lettura Id stato ordinativo='||ORD_STATO_FIRMA||'.';
    select stato.ord_stato_id into strict ordStatoFirmaId
    from siac_d_ordinativo_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and stato.ord_stato_code=ORD_STATO_FIRMA;

	-- lettura ordStatoTrasmId
    strMessaggio:='Lettura Id stato ordinativo='||ORD_STATO_TRASM||'.';
    select stato.ord_stato_id into strict ordStatoTrasmId
    from siac_d_ordinativo_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and stato.ord_stato_code=ORD_STATO_TRASM;

	-- lettura pccOperazTipoId
    strMessaggio:='Lettura Id tipo operazine PCC='||PCC_OPERAZ_CPAG||'.';
	select pcc.pccop_tipo_id into strict pccOperazTipoId
    from siac_d_pcc_operazione_tipo pcc
    where pcc.ente_proprietario_id=enteProprietarioId
    and   pcc.pccop_tipo_code=PCC_OPERAZ_CPAG;

	-- comPccAttrId
    strMessaggio:='Lettura comPccAttrId per attributo='||COM_PCC_ATTR||'.';
    select attr.attr_id into strict  comPccAttrId
	from siac_t_attr attr
	where attr.ente_proprietario_id=enteProprietarioId
	and   attr.attr_code=COM_PCC_ATTR;


	-- controlli di integrita flusso
    strMessaggio:='Verifica integrita'' flusso-esistenza record di testata ['||TIPO_REC_TESTA||'].';
    codResult:=null;
    select distinct 1  into codResult
    from mif_t_elab_emap_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_TESTA;

    if codResult is null then
    	codErrore:=MIF_TESTATA_COD_ERR;
        raise exception ' COD.ERRORE=%',codErrore;
    end if;


	strMessaggio:='Verifica integrita'' flusso-esistenza record di coda ['||TIPO_REC_CODA||'].';
    codResult:=null;
    select distinct 1  into codResult
    from mif_t_elab_emap_hrer  mif
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
    from mif_t_elab_emap_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_TESTA;

    if codResult is null then
    	codErrore:=MIF_TESTATA_COD_ERR;
    end if;
    if codErrore is null and
       ( tipoFlusso is null or tipoFlusso='' or tipoFlusso!=oilRicevutaTipoCodeFl ) then
    	codErrore:=MIF_FLUSSO_QU_COD_ERR;
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
     from mif_t_elab_emap_hrer  mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.tipo_record=TIPO_REC_CODA;


      if codResult is null then
    	codErrore:=MIF_CODA_COD_ERR;
      end if;
      if codErrore is null and
       ( tipoFlusso is null or tipoFlusso='' or tipoFlusso!=oilRicevutaTipoCodeFl ) then
    	codErrore:=MIF_FLUSSO_QU_C_COD_ERR;
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
   		from mif_t_elab_emap_rr  mif
    	where mif.flusso_elab_mif_id=flussoElabMifId
   		and   mif.tipo_record=TIPO_REC_RR;

        if codResult is null then
        	codErrore:=MIF_RR_COD_ERR;
        end if;
     end if;

     -- verifica integrita'' flusso esistenza di un record DR
	/* if codErrore is null then
    	strMessaggio:='Verifica integrita'' flusso-esistenza record di dettaglio ricevuta ['||TIPO_REC_DR||'].';
    	codResult:=null;
   		select distinct 1  into codResult
   		from mif_t_elab_emap_dr  mif
    	where mif.flusso_elab_mif_id=flussoElabMifId
   		and   mif.tipo_record=TIPO_REC_DR;

        if codResult is  null then
        	codErrore:=MIF_DR_COD_ERR;
        end if;
     end if; 20.05.2016 Sofia - siac-3435 - tolto perche per gli storni senza DR aggiunto flag e  controllo specifico di seguito */

     -- esistenza di record RR senza DR
/*     if codErrore is null then
     	strMessaggio:='Verifica integrita'' flusso-esistenza record di ricevuta senza record di dettaglio.';
    	codResult:=null;
   		select distinct 1  into codResult
   		from mif_t_emap_rr  mif
    	where mif.flusso_elab_mif_id=flussoElabMifId
   		and   mif.tipo_record=TIPO_REC_RR
        and not exists (select distinct 1 from mif_t_emap_dr mif1
                       where mif1.flusso_elab_mif_id=flussoElabMifId
                       and   mif1.tipo_record=TIPO_REC_DR
                       and   mif1.progressivo_ricevuta=mif.progressivo_ricevuta);

        if codResult is not null then
        	codErrore:=MIF_RR_NO_DR_COD_ERR;
        end if;
     end if;*/

    -- esistenza di record DR senza RR
    if codErrore is null then
     	strMessaggio:='Verifica integrita'' flusso-esistenza record di dettaglio ricevuta senza record di riferimento.';
		codResult:=null;
   		select distinct 1  into codResult
   		from mif_t_elab_emap_dr  mif
    	where mif.flusso_elab_mif_id=flussoElabMifId
   		and   mif.tipo_record=TIPO_REC_DR
        and not exists (select distinct 1 from mif_t_elab_emap_rr mif1
                       where mif1.flusso_elab_mif_id=flussoElabMifId
                       and   mif1.tipo_record=TIPO_REC_RR
                       and   mif1.progressivo_ricevuta=mif.progressivo_ricevuta);

        if codResult is not null then
        	codErrore:=MIF_DR_NO_RR_COD_ERR;
        end if;
     end if;

    if codErrore is null then
    	codResult:=null;
        strMessaggio:='Verifica integrita'' flusso-esistenza record di ricevuta con tipo record '||TIPO_REC_RR||'errato.';
    	select distinct 1 into codResult
        from mif_t_elab_emap_rr mif
        where mif.flusso_elab_mif_id=flussoElabMifId
   		and   ( mif.tipo_record is null or mif.tipo_record='' or mif.tipo_record!=TIPO_REC_RR);

        if codResult is not null then
        	codErrore:=MIF_RR_NO_TIPO_REC_COD_ERR;
        end if;
    end if;

    if codErrore is null then
    	codResult:=null;
        strMessaggio:='Verifica integrita'' flusso-esistenza record di dettaglio ricevuta con tipo record '||TIPO_REC_DR||'errato.';
    	select distinct 1 into codResult
        from mif_t_elab_emap_dr mif
        where mif.flusso_elab_mif_id=flussoElabMifId
   		and   ( mif.tipo_record is null or mif.tipo_record='' or mif.tipo_record!=TIPO_REC_DR);

        if codResult is not null then
        	codErrore:=MIF_DR_NO_TIPO_REC_COD_ERR;
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
     from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
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
     from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
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
     from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
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
     from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   rr.esito_derivato is not null and  rr.esito_derivato !=''
     and   not exists (select distinct 1 from siac_d_oil_esito_derivato d,siac_d_oil_ricevuta_tipo tipo
     				   where d.oil_esito_derivato_code=rr.esito_derivato
                       and   d.ente_proprietario_id=enteProprietarioId
                       and   tipo.oil_ricevuta_tipo_id=d.oil_ricevuta_tipo_id
                       and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
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
     from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
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
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
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
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.codice_funzione is null or rr.codice_funzione='' or rr.codice_funzione !=CODICE_FUNZIONE_I)
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
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
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
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.qualificatore is not null and rr.qualificatore!=''
      and   not exists ( select distinct 1
                         from siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
                         where q.oil_qualificatore_code=rr.qualificatore
                         and   q.ente_proprietario_id=enteProprietarioId
                         and   e.oil_esito_derivato_id=q.oil_esito_derivato_id
                         and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	                     and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      				   )
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

      -- MIF_RR_NO_DR_COD_ERR esistenza record RR con
      -- qualificatore, esito_derivato, codice_funzione,codice_esito valorizzati e ammessi
      -- senza corrispondente record DR

      -- siac-3435-26.04.2016 Sofia aggiungere controllo sul flag del qualificatore
	  strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] senza corrispondente record di dettaglio.';
      insert into mif_t_oil_ricevuta
      ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
   	    oil_ricevuta_data,oil_ricevuta_tipo,
	    validita_inizio, ente_proprietario_id,login_operazione
	  )
      (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		  rr.data_pagamento::timestamp,q.oil_qualificatore_segno,
    	      now(),enteProprietarioId,loginOperazione
	   from  mif_t_elab_emap_rr  rr,  siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
       where rr.flusso_elab_mif_id=flussoElabMifId
       and   q.oil_qualificatore_code=rr.qualificatore
       and   q.ente_proprietario_id=enteProprietarioId
       and   e.oil_esito_derivato_code=rr.esito_derivato
       and   e.ente_proprietario_id=q.ente_proprietario_id
	   and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
       and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016
       and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	   and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
       and   errore.oil_ricevuta_errore_code=MIF_RR_NO_DR_COD_ERR::varchar
       and   errore.ente_proprietario_id=enteProprietarioId
       and   not exists (select distinct 1 from mif_t_elab_emap_dr dr
                         where dr.flusso_elab_mif_id=flussoElabMifId
                         and   dr.progressivo_ricevuta=rr.progressivo_ricevuta)
       and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_DATI_ORD_COD_ERR dati ordinativo non indicati
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] dati ordinativo non indicati.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   ( rr.esercizio is null or rr.esercizio='' or
	          rr.numero_ordinativo is null or  rr.numero_ordinativo='' or
              rr.data_pagamento is null or rr.data_pagamento='')
      and errore.oil_ricevuta_errore_code=MIF_RR_DATI_ORD_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     codResult:=null;
     select count(*) into codResult
     from mif_t_oil_ricevuta
     where flusso_elab_mif_id=flussoElabMifId;
     raise notice 'numero record senza dati fin =%',codResult;

     -- MIF_RR_ANNO_ORD_COD_ERR anno ordinativo non corretto
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] anno ordinativo non corretto rispetto all''anno di bilancio corrente.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.esercizio::integer > annoBilancio
      and errore.oil_ricevuta_errore_code=MIF_RR_ANNO_ORD_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- esistenza ordinativo e annullamento

     -- MIF_RR_ORD_COD_ERR dati ordinativo non esistente
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa non esistente.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists ( select distinct 1
                       from  siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per
                       where ord.ente_proprietario_id=enteProprietarioId
                       and   ord.ord_numero=rr.numero_ordinativo::integer
                       and   ord.ord_tipo_id=ordTipoSpesaId
                       and   bil.bil_id=ord.bil_id
                       and   per.periodo_id=bil.periodo_id
                       and   per.anno=rr.esercizio
                     )
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata non esistente.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists ( select distinct 1
                       from  siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per
                       where ord.ente_proprietario_id=enteProprietarioId
                       and   ord.ord_numero=rr.numero_ordinativo::integer
                       and   ord.ord_tipo_id=ordTipoEntrataId
                       and   bil.bil_id=ord.bil_id
                       and   per.periodo_id=bil.periodo_id
                       and   per.anno=rr.esercizio
                     )
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


     -- MIF_RR_ORD_ANNULL_COD_ERR dati ordinativo annullato
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa annullato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_bil_id,oil_ord_id,oil_ord_anno_bil,oil_ord_numero,oil_ord_data_annullamento,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 ord.bil_id,ord.ord_id,rr.esercizio::integer,rr.numero_ordinativo::integer,stato.validita_inizio,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_stato stato
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_ANNULL_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
--      and   ord.ord_tipo_id=ordTipoSpesaId
--      and   ord.ord_tipo_id=ordTipoEntrataId -- Sofia 16.05.2016 SIAC-3555 22.09.2016 Sofia HD-INC000001250308
      and   ord.ord_tipo_id=ordTipoSpesaId --  22.09.2016 Sofia HD-INC000001250308
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   stato.ord_id=ord.ord_id
      and   stato.ord_stato_id=ordStatoAnnullatoId
      and   stato.data_cancellazione is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata annullato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_bil_id,oil_ord_id,oil_ord_anno_bil,oil_ord_numero,oil_ord_data_annullamento,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 ord.bil_id,ord.ord_id,rr.esercizio::integer,rr.numero_ordinativo::integer,stato.validita_inizio,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_stato stato
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_ANNULL_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
  --    and   ord.ord_tipo_id=ordTipoSpesaId --  22.09.2016 Sofia HD-INC000001250308
      and   ord.ord_tipo_id=ordTipoEntrataId --  22.09.2016 Sofia HD-INC000001250308
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   stato.ord_id=ord.ord_id
      and   stato.ord_stato_id=ordStatoAnnullatoId
      and   stato.data_cancellazione is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- data_emissione ordinativo  successiva data_pagamento
     -- MIF_RR_ORD_DT_EMIS_COD_ERR data_emissione ordinativo  successiva data_pagamento
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa emesso in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.data_pagamento::timestamp, -- capire come convertire
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   ord.ord_emissione_data>rr.data_pagamento::timestamp -- capire come convertire
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_EMIS_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata emesso in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.data_pagamento::timestamp, -- capire come convertire
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   ord.ord_emissione_data>rr.data_pagamento::timestamp -- capire come convertire
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_EMIS_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


	 -- data_trasmissione ordinativo non valorizzata o  successiva data_pagamento
     -- MIF_RR_ORD_DT_TRASM_COD_ERR data_emissione ordinativo  successiva data_pagamento
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa non trasmesso o in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.data_pagamento::timestamp, -- capire come convertire
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             ord.ord_trasm_oil_data,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   ( ord.ord_trasm_oil_data is null or --ord.ord_trasm_oil_data='' or
              date_trunc('DAY',ord.ord_trasm_oil_data)>date_trunc('DAY',rr.data_pagamento::timestamp) )
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_TRASM_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata non trasmesso o in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		 rr.data_pagamento::timestamp, -- capire come convertire
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             ord.ord_trasm_oil_data,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   ( ord.ord_trasm_oil_data is null or --ord.ord_trasm_oil_data='' or
              date_trunc('DAY',ord.ord_trasm_oil_data)>date_trunc('DAY',rr.data_pagamento::timestamp) )
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_TRASM_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

      if enteOilRec.ente_oil_firme_ord=true then
      	-- ordinativo non firmato o firmato in data successiva
	    -- MIF_RR_ORD_DT_FIRMA_COD_ERR ordinativo non firmato
    	-- [ordinativo spesa]
	   /* strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa non firmato.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
    	  oil_ricevuta_data,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	    siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoSpesaId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   not exists (select distinct 1
                            from siac_r_ordinativo_firma firma
                            where firma.ord_id=ord.ord_id
                            and   firma.data_cancellazione is null
                            and   firma.validita_fine is null )
	      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_FIRMA_COD_ERR::varchar
    	  and errore.ente_proprietario_id=enteProprietarioId
	      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                  where rr1.flusso_elab_mif_id=flussoElabMifId
         	              and   rr1.oil_progr_ricevuta_id=rr.id));

        -- [ordinativo entrata]
	    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata non firmato.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
    	  oil_ricevuta_data,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	    siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='E'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoEntrataId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   not exists (select distinct 1
                            from siac_r_ordinativo_firma firma
                            where firma.ord_id=ord.ord_id
                            and   firma.data_cancellazione is null
                            and   firma.validita_fine is null )
	      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_FIRMA_COD_ERR::varchar
    	  and errore.ente_proprietario_id=enteProprietarioId
	      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                  where rr1.flusso_elab_mif_id=flussoElabMifId
         	              and   rr1.oil_progr_ricevuta_id=rr.id));*/

	    -- MIF_RR_ORD_DT_FIRMA_COD_ERR ordinativo  firmato successivamente alla data di quietanza
    	-- [ordinativo spesa]
	    strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa firmato successivamente alla data di quietanza.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
    	  oil_ricevuta_data,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_firma,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                firma.ord_firma_data,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	    siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per,
                siac_r_ordinativo_firma firma
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoSpesaId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   firma.ord_id=ord.ord_id
--          and   firma.ord_firma_data>rr.data_pagamento::timestamp -- verificare conversione
          and   date_trunc('DAY',firma.ord_firma_data)>date_trunc('DAY',rr.data_pagamento::timestamp)
          and   firma.data_cancellazione is null
          and   firma.validita_fine is null
	      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_FIRMA_COD_ERR::varchar
    	  and errore.ente_proprietario_id=enteProprietarioId
	      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                  where rr1.flusso_elab_mif_id=flussoElabMifId
         	              and   rr1.oil_progr_ricevuta_id=rr.id));

          -- [ordinativo entrata]
	      strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata firmato successivamente alla data di quietanza.';
    	  insert into mif_t_oil_ricevuta
	      ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
    	    oil_ricevuta_data,
	        oil_ord_id,oil_ord_bil_id,
	        oil_ord_anno_bil,oil_ord_numero,
	        oil_ord_data_emissione,
	        oil_ord_trasm_oil_data,
            oil_ord_data_firma,
	        oil_ricevuta_tipo,
		    validita_inizio, ente_proprietario_id,login_operazione
	      )
    	  (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,rr.id,
     		      rr.data_pagamento::timestamp, -- capire come convertire
     		   	  ord.ord_id, ord.bil_id,
	     		  rr.esercizio::integer,rr.numero_ordinativo::integer,
	              ord.ord_emissione_data,
	              ord.ord_trasm_oil_data,
                  firma.ord_firma_data,
	              q.oil_qualificatore_segno,
    	          now(),enteProprietarioId,loginOperazione
 	       from  mif_t_elab_emap_rr rr, siac_d_oil_ricevuta_errore errore,
    	         siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	     siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per,
                 siac_r_ordinativo_firma firma
 	       where rr.flusso_elab_mif_id=flussoElabMifId
    	   and   q.oil_qualificatore_code=rr.qualificatore
	       and   q.ente_proprietario_id=enteProprietarioId
    	   and   q.oil_qualificatore_segno='E'
	       and   e.oil_esito_derivato_code=rr.esito_derivato
    	   and   e.ente_proprietario_id=q.ente_proprietario_id
	       and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	   and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	       and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	   and   ord.ente_proprietario_id=enteProprietarioId
	       and   ord.ord_numero=rr.numero_ordinativo::integer
    	   and   ord.ord_tipo_id=ordTipoEntrataId
	       and   bil.bil_id=ord.bil_id
    	   and   per.periodo_id=bil.periodo_id
	       and   per.anno=rr.esercizio
           and   firma.ord_id=ord.ord_id
--           and   firma.ord_firma_data>rr.data_pagamento::timestamp -- verificare conversione
           and   date_trunc('DAY',firma.ord_firma_data)>date_trunc('DAY',rr.data_pagamento::timestamp)
           and   firma.data_cancellazione is null
           and   firma.validita_fine is null
	       and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_FIRMA_COD_ERR::varchar
    	   and   errore.ente_proprietario_id=enteProprietarioId
	       and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                  where rr1.flusso_elab_mif_id=flussoElabMifId
         	              and   rr1.oil_progr_ricevuta_id=rr.id));

      end if;


	  -- MIF_DR_ORD_PROGR_RIC_COD_ERR esistenza di record DR con progressivo_ricevuta non valorizzato
	  strMessaggio:='Verifica esistenza record dettaglio ricevuta ['||TIPO_REC_DR||'] con progressivo_ricevuta non valorizzato.';
      insert into mif_t_oil_ricevuta
	  ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_dett_ricevuta_id,
	    validita_inizio, ente_proprietario_id,login_operazione
	  )
      (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
    	      now(),enteProprietarioId,loginOperazione
	   from  mif_t_elab_emap_dr rr, siac_d_oil_ricevuta_errore errore
       where rr.flusso_elab_mif_id=flussoElabMifId
       and   (rr.progressivo_ricevuta is null or rr.progressivo_ricevuta='')
       and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_PROGR_RIC_COD_ERR::varchar
       and   errore.ente_proprietario_id=enteProprietarioId);


        -- poi passare ai controlli sui dettagli

		-- MIF_DR_ORD_NUM_RIC_COD_ERR esistenza di dettagli ricevute con numero_ricevuta non valorizzato
    	-- [ricevute di  spesa]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Verifica esistenza record dettaglio ricevuta spesa ['||TIPO_REC_DR||']  con numero_ricevuta non valorizzato.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,dr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, mif_t_elab_emap_dr dr , siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
	      where rr.flusso_elab_mif_id=flussoElabMifId
          and   dr.flusso_elab_mif_id=flussoElabMifId
          and   dr.progressivo_ricevuta=rr.progressivo_ricevuta
          and   (dr.num_ricevuta is null or dr.num_ricevuta='')
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
--	      and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016 Sofia
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
	      and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_NUM_RIC_COD_ERR::varchar
    	  and   errore.ente_proprietario_id=enteProprietarioId
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id)
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
--         	                and   rr1.oil_progr_ricevuta_id=rr.id
                            and   rr1.oil_progr_dett_ricevuta_id=dr.id));

    	-- [ricevute di  entrata]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Verifica esistenza record dettaglio ricevuta entrata ['||TIPO_REC_DR||']  con numero_ricevuta non valorizzato.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,dr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, mif_t_elab_emap_dr dr , siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
	      where rr.flusso_elab_mif_id=flussoElabMifId
          and   dr.flusso_elab_mif_id=flussoElabMifId
          and   dr.progressivo_ricevuta=rr.progressivo_ricevuta
          and   (dr.num_ricevuta is null or dr.num_ricevuta='')
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='E'
--   	      and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016 Sofia
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
	      and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_NUM_RIC_COD_ERR::varchar
    	  and   errore.ente_proprietario_id=enteProprietarioId
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id)
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
--         	                and   rr1.oil_progr_ricevuta_id=rr.id
                            and   rr1.oil_progr_dett_ricevuta_id=dr.id));


		-- MIF_DR_ORD_IMPORTO_RIC_COD_ERR esistenza di dettagli ricevute con importo_ricevuta non valorizzato  o non valido
    	-- [ordinativo spesa]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Verifica esistenza record dettaglio ricevuta  ['||TIPO_REC_DR||'] per ordinativato spesa con importo ricevuta non valorizzato o non valido.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ricevuta_numero,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,dr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
                dr.num_ricevuta::integer,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, mif_t_elab_emap_dr dr, siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	    siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	      where rr.flusso_elab_mif_id=flussoElabMifId
          and   dr.flusso_elab_mif_id=flussoElabMifId
          and   dr.progressivo_ricevuta=rr.progressivo_ricevuta
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
--   	      and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016 Sofia
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoSpesaId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   (dr.importo_ricevuta is null or dr.importo_ricevuta='' or  dr.importo_ricevuta::NUMERIC<=0)
	      and errore.oil_ricevuta_errore_code=MIF_DR_ORD_IMPORTO_RIC_COD_ERR::varchar
    	  and errore.ente_proprietario_id=enteProprietarioId
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id)
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
--         	                and   rr1.oil_progr_ricevuta_id=rr.id
                            and   rr1.oil_progr_dett_ricevuta_id=dr.id));

    	-- [ordinativo entrata]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Verifica esistenza record dettaglio ricevuta  ['||TIPO_REC_DR||'] per ordinativato entrata con importo ricevuta non valorizzato o non valido.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ricevuta_numero,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
	      oil_ricevuta_tipo,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,dr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
                dr.num_ricevuta::integer,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	      from  mif_t_elab_emap_rr rr, mif_t_elab_emap_dr dr, siac_d_oil_ricevuta_errore errore,
    	        siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	    siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	      where rr.flusso_elab_mif_id=flussoElabMifId
          and   dr.flusso_elab_mif_id=flussoElabMifId
          and   dr.progressivo_ricevuta=rr.progressivo_ricevuta
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='E'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
 --  	      and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016 Sofia
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoEntrataId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   (dr.importo_ricevuta is null or dr.importo_ricevuta::NUMERIC<=0)
	      and errore.oil_ricevuta_errore_code=MIF_DR_ORD_IMPORTO_RIC_COD_ERR::varchar
    	  and errore.ente_proprietario_id=enteProprietarioId
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id)
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
--         	                and   rr1.oil_progr_ricevuta_id=rr.id
                            and   rr1.oil_progr_dett_ricevuta_id=dr.id));


		-- inserimento record da elaborare
    	-- [ordinativo spesa]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativato spesa da elaborare.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ricevuta_numero,
          oil_ricevuta_importo,
          oil_ricevuta_cro1,
          oil_ricevuta_cro2,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_firma,
	      oil_ricevuta_tipo,
          oil_ricevuta_note,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,dr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
                dr.num_ricevuta::integer,
                round(dr.importo_ricevuta::numeric/100,2),
                rr.cro1,
                rr.cro2,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                firmaOrd.ord_firma_data,
	            q.oil_qualificatore_segno,
                ( case when enteOilRec.ente_oil_firme_ord=true and firmaOrd.ord_firma_data is null
                       then  errore.oil_ricevuta_errore_desc
                       else  null end),
    	        now(),enteProprietarioId,loginOperazione
	     from  mif_t_elab_emap_rr rr, mif_t_elab_emap_dr dr,
    	       siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	   siac_t_bil bil, siac_t_periodo per,siac_d_oil_ricevuta_errore errore,
               siac_t_ordinativo ord
               left outer join
	          (select firma.ord_id, firma.ord_firma_data
    	       from siac_r_ordinativo_firma firma
        	   where firma.ente_proprietario_id=enteProprietarioId
               and   firma.data_cancellazione is null
    	       and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
          and   dr.flusso_elab_mif_id=flussoElabMifId
          and   dr.progressivo_ricevuta=rr.progressivo_ricevuta
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
--		  and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016 Sofia
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoSpesaId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   errore.ente_proprietario_id=enteProprietarioId
          and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id)
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
--         	                and   rr1.oil_progr_ricevuta_id=rr.id
                            and   rr1.oil_progr_dett_ricevuta_id=dr.id));

		-- [ordinativo spesa]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativo spesa da elaborare.Storni  senza dettaglio ricevuta.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ricevuta_numero,
          oil_ricevuta_importo,
          oil_ricevuta_cro1,
          oil_ricevuta_cro2,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_firma,
	      oil_ricevuta_tipo,
          oil_ricevuta_note,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,0,
     		    rr.data_pagamento::timestamp, -- capire come convertire
                quiet.ord_quietanza_numero,
                quiet.ord_quietanza_importo,
                null,
                null,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                firmaOrd.ord_firma_data,
	            q.oil_qualificatore_segno,
                ( case when enteOilRec.ente_oil_firme_ord=true and firmaOrd.ord_firma_data is null
                       then  errore.oil_ricevuta_errore_desc
                       else  null end),
    	        now(),enteProprietarioId,loginOperazione
	     from  mif_t_elab_emap_rr rr, siac_r_ordinativo_quietanza quiet,
    	       siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	   siac_t_bil bil, siac_t_periodo per,siac_d_oil_ricevuta_errore errore,
               siac_t_ordinativo ord
               left outer join
	          (select firma.ord_id, firma.ord_firma_data
    	       from siac_r_ordinativo_firma firma
        	   where firma.ente_proprietario_id=enteProprietarioId
               and   firma.data_cancellazione is null
    	       and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
		  and   q.oil_qualificatore_dr_rec=false -- siac-3435-26.04.2016 Sofia
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoSpesaId
          and   quiet.ord_id=ord.ord_id
          and   quiet.data_cancellazione is null
          and   quiet.validita_fine is null
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   errore.ente_proprietario_id=enteProprietarioId
          and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id));

    	-- [ordinativo entrata]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativo entrata da elaborare.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ricevuta_numero,
          oil_ricevuta_importo,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_firma,
	      oil_ricevuta_tipo,
          oil_ricevuta_note,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,dr.id,
     		    rr.data_pagamento::timestamp, -- capire come convertire
                dr.num_ricevuta::integer,
                round(dr.importo_ricevuta::numeric/100,2),
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                firmaOrd.ord_firma_data,
	            q.oil_qualificatore_segno,
                ( case when enteOilRec.ente_oil_firme_ord=true and firmaOrd.ord_firma_data is null
                       then  errore.oil_ricevuta_errore_desc
                       else  null end),
    	        now(),enteProprietarioId,loginOperazione
	     from  mif_t_elab_emap_rr rr, mif_t_elab_emap_dr dr,
    	       siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	   siac_t_bil bil, siac_t_periodo per,siac_d_oil_ricevuta_errore errore,
               siac_t_ordinativo ord
	           left outer join
	          (select firma.ord_id, firma.ord_firma_data
    	       from siac_r_ordinativo_firma firma
        	   where firma.ente_proprietario_id=enteProprietarioId
               and   firma.data_cancellazione is null
    	       and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
          and   dr.flusso_elab_mif_id=flussoElabMifId
          and   dr.progressivo_ricevuta=rr.progressivo_ricevuta
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='E'
--  		  and   q.oil_qualificatore_dr_rec=true -- siac-3435-26.04.2016 Sofia
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoEntrataId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   errore.ente_proprietario_id=enteProprietarioId
          and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id)
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
--         	                and   rr1.oil_progr_ricevuta_id=rr.id
                            and   rr1.oil_progr_dett_ricevuta_id=dr.id));

    	-- [ordinativo entrata]
        -- siac-3435-26.04.2016 Sofia
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativo entrata da elaborare.Storni senza dettaglio ricevuta.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,flusso_elab_mif_id,
          oil_progr_ricevuta_id,oil_progr_dett_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ricevuta_numero,
          oil_ricevuta_importo,
	      oil_ord_id,oil_ord_bil_id,
	      oil_ord_anno_bil,oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_firma,
	      oil_ricevuta_tipo,
          oil_ricevuta_note,
		  validita_inizio, ente_proprietario_id,login_operazione
	    )
    	(select tipo.oil_ricevuta_tipo_id,flussoElabMifId,
        		rr.id,0,
     		    rr.data_pagamento::timestamp, -- capire come convertire
                quiet.ord_quietanza_numero,
                quiet.ord_quietanza_importo,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                firmaOrd.ord_firma_data,
	            q.oil_qualificatore_segno,
                ( case when enteOilRec.ente_oil_firme_ord=true and firmaOrd.ord_firma_data is null
                       then  errore.oil_ricevuta_errore_desc
                       else  null end),
    	        now(),enteProprietarioId,loginOperazione
	     from  mif_t_elab_emap_rr rr, siac_r_ordinativo_quietanza quiet,
    	       siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo,
        	   siac_t_bil bil, siac_t_periodo per,siac_d_oil_ricevuta_errore errore,
               siac_t_ordinativo ord
	           left outer join
	          (select firma.ord_id, firma.ord_firma_data
    	       from siac_r_ordinativo_firma firma
        	   where firma.ente_proprietario_id=enteProprietarioId
               and   firma.data_cancellazione is null
    	       and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='E'
  		  and   q.oil_qualificatore_dr_rec=false -- siac-3435-26.04.2016 Sofia
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoEntrataId
          and   quiet.ord_id=ord.ord_id
          and   quiet.data_cancellazione is null
          and   quiet.validita_fine is null
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   errore.ente_proprietario_id=enteProprietarioId
          and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id));


    strMessaggio:='Inizio ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta].';
	for ricevutaRec in
    (
	 select mif.oil_progr_ricevuta_id,
            mif.oil_ricevuta_tipo_id,
            mif.oil_ricevuta_data,
            mif.oil_ricevuta_tipo,
            tipo.oil_ricevuta_tipo_code,
            mif.oil_ricevuta_cro1,
            mif.oil_ricevuta_cro2,
            mif.oil_ord_bil_id,mif.oil_ord_anno_bil,mif.oil_ord_id,
            mif.oil_ord_numero,
            mif.oil_ord_data_emissione,
            mif.oil_ord_data_firma,
            mif.oil_ord_trasm_oil_data,
            mif.oil_ricevuta_note,
            coalesce(sum(mif.oil_ricevuta_importo),0) importoRicevuta ,
		    (case  when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE
                   then coalesce(sum(mif.oil_ricevuta_importo),0)
                   else 0 end) importoQuiet,
            (case  when tipo.oil_ricevuta_tipo_code=STORNI_MIF_FLUSSO_TIPO_CODE
                   then coalesce(sum(mif.oil_ricevuta_importo),0)
                   else 0 end) importoStorno
     from mif_t_oil_ricevuta mif,siac_d_oil_ricevuta_tipo tipo
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.oil_ricevuta_errore_id is null
     and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id
     group by mif.oil_progr_ricevuta_id,
              mif.oil_ricevuta_tipo_id,
              mif.oil_ricevuta_data,
              mif.oil_ricevuta_tipo,
              tipo.oil_ricevuta_tipo_code,
              mif.oil_ricevuta_cro1,
              mif.oil_ricevuta_cro2,
              mif.oil_ord_bil_id,mif.oil_ord_anno_bil,mif.oil_ord_id,
              mif.oil_ord_numero,
              mif.oil_ord_data_emissione,
              mif.oil_ord_data_firma,
              mif.oil_ord_trasm_oil_data,
              mif.oil_ricevuta_note
     order by mif.oil_progr_ricevuta_id
    )
    loop
		codResult:=null;
        numeroRicevuta:=null;
        oilRicevutaId:=null;
        oilProgrDettRicevutaId:=0;
        importoOrdinativo:=0;
        importoQuiet:=0;
        importoStorno:=0;
		ordStatoId:=null;
        ordCambioStatoId:=null;
        ordStatoRId:=null;
        ordStatoRChiudiId:=null;
        ordStatoApriId:=null;
	    codErrore:=null;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';

        raise notice 'importo ricevuta=% RR.ID=%',ricevutaRec.importoRicevuta,ricevutaRec.oil_progr_ricevuta_id;

        -- importo ricevuta deve essere >0
        if ricevutaRec.importoRicevuta <=0 then
        	-- scarto
            codErrore:=MIF_DR_ORD_IMP_NEG_RIC_COD_ERR;
        end if;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
				       ||'.Lettura numero ricevuta.';
		if codErrore is null then
     	 -- lettura numero_ricevuta
         select mif.oil_ricevuta_numero, mif.oil_progr_dett_ricevuta_id
                into numeroRicevuta, oilProgrDettRicevutaId
         from mif_t_oil_ricevuta mif
         where mif.flusso_elab_mif_id=flussoElabMifId
         and   mif.oil_ricevuta_errore_id is null
         and   mif.oil_progr_ricevuta_id=ricevutaRec.oil_progr_ricevuta_id
         order by mif.oil_progr_dett_ricevuta_id desc
         limit 1;

         if numeroRicevuta is null then
        	-- scarto
            codErrore:=MIF_DR_ORD_NUM_ERR_RIC_COD_ERR;
         end if;
        end if;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
        			  ||'.Calcolo importo ordinativo.';
		if codErrore is null then

         -- lettura importo_ordinativo
         select coalesce(sum(det.ord_ts_det_importo),0) into importoOrdinativo
         from siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det
         where ts.ord_id=ricevutaRec.oil_ord_id
         and   det.ord_ts_id=ts.ord_ts_id
         and   det.ord_ts_det_tipo_id=ordTsDetTipoId
         and   ts.data_cancellazione is null
         and   ts.validita_fine is null
         and   det.data_cancellazione is null
         and   det.validita_fine is null;

		 if coalesce(importoOrdinativo,0)=0 then
        	-- scarto
            codErrore:=MIF_DR_ORD_IMP_ORD_Z_COD_ERR;
         end if;
       end if;

	  if codErrore is null then
      	raise notice ' RR.ID=% importoOrdinativo=%',ricevutaRec.oil_progr_ricevuta_id,importoOrdinativo;
      end if;

        -- controlli
        -- se storno , l'ordinativo deve essere quietanzato
        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                       ||'.Verifica esistenza quietanza per ordinativo in fase di storno.';
        if codErrore is null then
         if ricevutaRec.oil_ricevuta_tipo_code=STORNI_MIF_FLUSSO_TIPO_CODE then
            codResult:=null;
        	select distinct 1 into codResult
            from siac_r_ordinativo_quietanza q
            where q.ord_id=ricevutaRec.oil_ord_id
            and   q.data_cancellazione is null
            and   q.validita_fine is null;

            if codResult is null then
            	-- scarto
                codErrore:=MIF_DR_ORD_NON_QUIET_COD_ERR;
            end if;
         end if;
        end if;

		strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
        			  ||'.Verifica importi ordinativo.';
		if codErrore is null then
         strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                      ||'.Verifica importo quietanzato ordinativo.';
         -- calcolo totale quietanzato
         select  coalesce(sum(q.ord_quietanza_importo),0) into importoQuiet
         from siac_r_ordinativo_quietanza q
         where q.ord_id=ricevutaRec.oil_ord_id
         and   q.data_cancellazione is null
         and   q.validita_fine is null;
		 if importoQuiet is null then
         	importoQuiet:=0;
         end if;


      	 raise notice ' RR.ID=% importoQuiet=%',ricevutaRec.oil_progr_ricevuta_id,importoQuiet;
       -- end if;

         strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                       ||'.Verifica importo stornato ordinativo.';
         -- calcolo totale stornato
         select  coalesce(sum(q.ord_storno_importo),0) into importoStorno
         from siac_r_ordinativo_storno q
         where q.ord_id=ricevutaRec.oil_ord_id
         and   q.data_cancellazione is null
         and   q.validita_fine is null;
		 if importoStorno is null then
         	importoStorno:=0;
         end if;


		 raise notice ' RR.ID=% importoStorno=%',ricevutaRec.oil_progr_ricevuta_id,importoStorno;
         -- il totale Quietanzato  deve essere <= importo_ordinativo
         if importoQuiet+ricevutaRec.importoQuiet>importoOrdinativo then
          -- scarto
          codErrore:=MIF_DR_ORD_IMP_QUIET_ERR_COD_ERR;
         end if;

         -- il totale Stornato deve essere <=totale Quietanzato
         if codErrore is null
            and importoStorno+ricevutaRec.importoStorno>importoQuiet+ricevutaRec.importoQuiet then
        	-- scarto
			codErrore:=MIF_DR_ORD_IMP_QUIET_NEG_COD_ERR;
         end if;

        end if;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Lettura stato attuale ordinativo.';
        if codErrore is null then
  		 -- leggo lo stato attuale ordinativo
         if importoQuiet>0 then
        	  -- stato attuale
              ordStatoId:=ordStatoQuietId;

              -- stato verso cui cambiare
              if enteOilRec.ente_oil_firme_ord=true and
                 ricevutaRec.oil_ord_data_firma is not null
                 then
            	   ordCambioStatoId:=ordStatoFirmaId;
	          else ordCambioStatoId:=ordStatoTrasmId;
    	      end if;
         else
        	-- stato verso cui cambiare
        	ordCambioStatoId:=ordStatoQuietId;

            -- stato attuale
        	if enteOilRec.ente_oil_firme_ord=true and
               ricevutaRec.oil_ord_data_firma is not null
	           then
            	 ordStatoId:=ordStatoFirmaId;
            else ordStatoId:=ordStatoTrasmId;
            end if;
         end if;

         -- cerco lo stato attuale
         select stato.ord_stato_r_id into ordStatoRId
         from siac_r_ordinativo_stato stato
         where stato.ord_id=ricevutaRec.oil_ord_id
         and   stato.ord_stato_id=ordStatoId
         and   stato.data_cancellazione is null
         and   stato.validita_fine is null;

         if ordStatoRId is null then
        	-- scarto stato non congruente
            codErrore:=MIF_DR_ORD_STATO_ORD_ERR_COD_ERR;
         end if;

		end if;

        if codErrore is null then
        	raise notice 'IdStatoAttuale=% ordStatoRId=% ordCambioStatoId=% RR.ID=%',
            	ordStatoId,ordStatoRId,ordCambioStatoId,ricevutaRec.oil_progr_ricevuta_id;
        end if;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Verifica inserimento scarto.';
        if codErrore is not null  then
        	codResult:=null;
	        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                        ||'.Inserimento scarto ricevuta.';
            -- inserimento siac_t_oil_ricevuta
        	insert into siac_t_oil_ricevuta
       		( oil_ricevuta_anno,
			  oil_ricevuta_numero,
    	      oil_ricevuta_data,
	  		  oil_ricevuta_tipo,
			  oil_ricevuta_importo,
			  oil_ricevuta_cro1,
              oil_ricevuta_cro2,
		  --  oil_ricevuta_note_tes,
    	  --  oil_ricevuta_denominazione,
	      --  oil_ricevuta_errore_id,
    	      oil_ricevuta_tipo_id,
              oil_ricevuta_note,
              oil_ricevuta_errore_id,
	          oil_ord_bil_id,
    	      oil_ord_id,
	          flusso_elab_mif_id,
    	      oil_progr_ricevuta_id,
	          oil_progr_dett_ricevuta_id,
    	      oil_ord_anno_bil,
	          oil_ord_numero,
	          oil_ord_importo,
    	      oil_ord_data_emissione,
	          oil_ord_trasm_oil_data,
    	      oil_ord_data_firma,
	          oil_ord_importo_quiet,
    	      oil_ord_importo_storno,
	          oil_ord_importo_quiet_tot,
	          validita_inizio,
		      ente_proprietario_id,
			  login_operazione)
        	( select
              annoBilancio,
	          numeroRicevuta,
    	      ricevutaRec.oil_ricevuta_data,
        	  ricevutaRec.oil_ricevuta_tipo,
	          ricevutaRec.importoRicevuta,
    	      ricevutaRec.oil_ricevuta_cro1,
              ricevutaRec.oil_ricevuta_cro2,
	          ricevutaRec.oil_ricevuta_tipo_id,
              ricevutaRec.oil_ricevuta_note,
              errore.oil_ricevuta_errore_id,
	          ricevutaRec.oil_ord_bil_id,
	          ricevutaRec.oil_ord_id,
	          flussoElabMifId,
	          ricevutaRec.oil_progr_ricevuta_id,
	          oilProgrDettRicevutaId,
	          ricevutaRec.oil_ord_anno_bil,
	          ricevutaRec.oil_ord_numero,
	          importoOrdinativo,
	          ricevutaRec.oil_ord_data_emissione,
	          ricevutaRec.oil_ord_trasm_oil_data,
	          ricevutaRec.oil_ord_data_firma,
	          --importoQuiet-ricevutaRec.importoQuiet,
              importoQuiet,
	          --importoStorno-ricevutaRec.importoStorno,
              importoStorno,
	          --(importoQuiet-ricevutaRec.importoQuiet)-(importoStorno-ricevutaRec.importoStorno),
              importoQuiet-importoStorno,
	          now(),
			  enteProprietarioId,
	          loginOperazione
              from siac_d_oil_ricevuta_errore errore
              where errore.ente_proprietario_id=enteProprietarioId
              and   errore.oil_ricevuta_errore_code=codErrore
    	    )
        	returning oil_ricevuta_id into codResult;

            if codResult is null then
            	raise exception ' Errore in inserimento.';
            end if;

            continue;
        end if;

        raise notice 'Prima RR.ID=% importoQuiet=%',ricevutaRec.oil_progr_ricevuta_id,importoQuiet;
        raise notice 'Prima RR.ID=% importoStorno=%',ricevutaRec.oil_progr_ricevuta_id,importoStorno;
        -- se storno sommo importo_ricevuta al totale stornato
        importoStorno:=importoStorno+ricevutaRec.importoStorno;
        -- se quietanza sommo importo_ricevuta al totale quietanzato
        importoQuiet:=importoQuiet+ricevutaRec.importoQuiet;
		raise notice ' RR.ID=% importoQuiet=%',ricevutaRec.oil_progr_ricevuta_id,ricevutaRec.importoQuiet;
        raise notice ' RR.ID=% importoStorno=%',ricevutaRec.oil_progr_ricevuta_id,ricevutaRec.importoStorno;
        raise notice ' RR.ID=% importoRicevuta=%',ricevutaRec.oil_progr_ricevuta_id,ricevutaRec.importoRicevuta;
        raise notice 'Dopo RR.ID=% importoQuiet=%',ricevutaRec.oil_progr_ricevuta_id,importoQuiet;
        raise notice 'Dopo RR.ID=% importoStorno=%',ricevutaRec.oil_progr_ricevuta_id,importoStorno;



		strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Inserimento ricevuta elaborata.';
	 	-- inserimento siac_t_oil_ricevuta
        insert into siac_t_oil_ricevuta
        ( oil_ricevuta_anno,
		  oil_ricevuta_numero,
          oil_ricevuta_data,
  		  oil_ricevuta_tipo,
		  oil_ricevuta_importo,
		  oil_ricevuta_cro1,
          oil_ricevuta_cro2,
	  --  oil_ricevuta_note_tes,
      --  oil_ricevuta_denominazione,
      --  oil_ricevuta_errore_id,
          oil_ricevuta_tipo_id,
          oil_ricevuta_note,
          oil_ord_bil_id,
          oil_ord_id,
          flusso_elab_mif_id,
          oil_progr_ricevuta_id,
          oil_progr_dett_ricevuta_id,
          oil_ord_anno_bil,
          oil_ord_numero,
          oil_ord_importo,
          oil_ord_data_emissione,
          oil_ord_trasm_oil_data,
          oil_ord_data_firma,
          oil_ord_importo_quiet,
          oil_ord_importo_storno,
          oil_ord_importo_quiet_tot,
          validita_inizio,
	      ente_proprietario_id,
		  login_operazione)
        values
        ( annoBilancio,
          numeroRicevuta,
          ricevutaRec.oil_ricevuta_data,
          ricevutaRec.oil_ricevuta_tipo,
          ricevutaRec.importoRicevuta,
          ricevutaRec.oil_ricevuta_cro1,
          ricevutaRec.oil_ricevuta_cro2,
          ricevutaRec.oil_ricevuta_tipo_id,
          ricevutaRec.oil_ricevuta_note,
          ricevutaRec.oil_ord_bil_id,
          ricevutaRec.oil_ord_id,
          flussoElabMifId,
          ricevutaRec.oil_progr_ricevuta_id,
          oilProgrDettRicevutaId,
          ricevutaRec.oil_ord_anno_bil,
          ricevutaRec.oil_ord_numero,
          importoOrdinativo,
          ricevutaRec.oil_ord_data_emissione,
          ricevutaRec.oil_ord_trasm_oil_data,
          ricevutaRec.oil_ord_data_firma,
          importoQuiet-ricevutaRec.importoQuiet,
          importoStorno-ricevutaRec.importoStorno,
          (importoQuiet-ricevutaRec.importoQuiet)-(importoStorno-ricevutaRec.importoStorno),
          now(),
		  enteProprietarioId,
          loginOperazione
        )
        returning oil_ricevuta_id into oilRicevutaId;

        if oilRicevutaId is null then
        	raise exception ' Errore in inserimento.';
        end if;

        -- totale_quietanzato=quietanzato-stornato

        -- se totale_quietanzato=0 sgancio tutto
        -- se ente gestisce firme riporto ordinativo in stato FIRMATO
        -- se ente non gestisce firme riporto ordinativo in stato TRASMESSO
		strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Aggiornamento dati ordinativo.';
        if importoQuiet-importoStorno=0 then

            if ricevutaRec.oil_ricevuta_tipo_code=STORNI_MIF_FLUSSO_TIPO_CODE then
               codResult:=null;
               strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                           ||'.Aggiornamento dati ordinativo per totale quietanzato uguale a zero.Inserimento dati storno quietanza.';
       		   -- siac_r_ordinativo_storno
		       insert into siac_r_ordinativo_storno
	          ( ord_id,
 			    ord_storno_data,
			    ord_storno_numero,
			    ord_storno_importo,
			    oil_ricevuta_id,
			    validita_inizio,
                validita_fine,
		        ente_proprietario_id,
			    login_operazione
	          )
    	      values
        	  (
	           ricevutaRec.oil_ord_id,
    	       ricevutaRec.oil_ricevuta_data,
	       	   numeroRicevuta,
    	       ricevutaRec.importoRicevuta,
	           oilRicevutaId,
    	       now(),
               now(),
	           enteProprietarioId,
    	       loginOperazione
	          )
    	      returning ord_storno_id into codResult;
              if codResult is null  then
	        	-- errore
    	        raise exception ' Errore in inserimento.';
	  	      end if;
            end if;

        	strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                        ||'.Aggiornamento dati ordinativo per totale quietanzato zero.Chiusura quietanze.';
            update siac_r_ordinativo_quietanza set validita_fine=now(), login_operazione=loginOperazione
            where ord_id=ricevutaRec.oil_ord_id
            and   data_cancellazione is null
            and   validita_fine is null;

        	strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                         ||'.Aggiornamento dati ordinativo per totale quietanzato zero.Chiusura storni.';
            update siac_r_ordinativo_storno  set validita_fine=now(), login_operazione=loginOperazione
            where ord_id=ricevutaRec.oil_ord_id
            and   data_cancellazione is null
            and   validita_fine is null;

            -- chiudere lo stato attuale (quietanzato)
            ordStatoRChiudiId:=ordStatoRId;
            -- inserire il nuovo stato   ( firmato o trasmesso )
            ordStatoApriId:=ordCambioStatoId;

            -- aggiorno contatore ordinativi aggiornati
            --countOrdAgg:=countOrdAgg+1;
        end if;

		strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                      ||'.Aggiornamento dati ordinativo.';
        -- se totale_quietanzato>0 inserisco
        -- se ordinativo non ancora in stato QUIETANZATO
        --   inserisco lo stato QUIETANZATO
        --   chiudo lo stato FIRMATO ( se ente gestisce firme )
        --   chiudo lo stato TRASMESSO ( se ente non gestisce  firme )
        codResult:=null;
        if  importoQuiet>importoStorno  then
         strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                      ||'.Aggiornamento dati ordinativo per totale quietanzato positivo.';
         if ricevutaRec.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then
          strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                        ||'.Aggiornamento dati ordinativo per inserimento dati quietanza.';
          -- siac_r_ordinativo_quietanza
          insert into  siac_r_ordinativo_quietanza
          ( ord_id,
		    ord_quietanza_data,
		    ord_quietanza_numero,
		    ord_quietanza_importo,
		    ord_quietanza_cro,
		    oil_ricevuta_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione
          )
          values
          (
           ricevutaRec.oil_ord_id,
           ricevutaRec.oil_ricevuta_data,
           numeroRicevuta,
           ricevutaRec.importoRicevuta,
--           coalesce(ricevutaRec.oil_ricevuta_cro1,ricevutaRec.oil_ricevuta_cro2),
           (case when ricevutaRec.oil_ricevuta_cro1=''      then ricevutaRec.oil_ricevuta_cro2
       		     when ricevutaRec.oil_ricevuta_cro1 is null then ricevutaRec.oil_ricevuta_cro2
                 else ricevutaRec.oil_ricevuta_cro1 end),
           oilRicevutaId,
           now(),
           enteProprietarioId,
           loginOperazione
          )
          returning ord_quietanza_id into codResult;


          if codResult is not null then
          	if ordStatoId!=ordStatoQuietId then
	            -- chiudere lo stato attuale (firmato o trasmesso)
    	        ordStatoRChiudiId:=ordStatoRId;
        	    -- inserire il nuovo stato  (quietanzato)
            	ordStatoApriId:=ordCambioStatoId;
            end if;
          end if;

         /* raise notice 'Prima di chiamare fnc_mif_ordinativo_spesa_predisponi_invio_email';
          raise notice 'codResult=%',codResult;
          raise notice 'ricevutaRec.oil_ricevuta_tipo=%',ricevutaRec.oil_ricevuta_tipo;
          raise notice 'enteOilRec.ente_oil_invio_email_cb=%',enteOilRec.ente_oil_invio_email_cb;
          raise notice 'flussoElabEmailMifId=%',flussoElabEmailMifId;*/

          --- 20.04.2017 Sofia inivio email per bonifici su conto corrente
		  if codResult is not null  -- quietanza inserita
           and enteOilRec.ente_oil_invio_email_cb=true -- invio_emali_cb attivo
           and ricevutaRec.oil_ricevuta_tipo='U' then  -- ordinativo di spesa
           strMessaggio:='Predisposizione invio email per invio bonifico.';

           select * into emailRec
           from fnc_mif_ordinativo_spesa_predisponi_invio_email
		   ( enteProprietarioId,
 			 annoBilancio,
  			 nomeEnte,
  			 INVIO_EMAIL_TIPO_FLUSSO,
 			 flussoElabEmailMifId,
  			 flussoElabMifId, -- flussoElabQuietMifId
 			 ricevutaRec.oil_ord_id,
 			 oilRicevutaId,
 			 ricevutaRec.oil_ricevuta_data,
 			 loginOperazione,
  			 dataElaborazione
           );

           /*raise notice 'emailRec.codiceRisultato=%',emailRec.codiceRisultato;
           raise notice 'flussoElabEmailMifId=%',flussoElabEmailMifId;*/

           if emailRec.codiceRisultato=0 then
           	if flussoElabEmailMifId is null then
            	flussoElabEmailMifId:=emailRec.flussoElabMifRetId;
            end if;
           else
           	raise exception ' %',emailRec.messaggioRisultato;
           end if;

		   /*raise notice 'flussoElabEmailMifId=%',flussoElabEmailMifId;*/

          end if;


         else
          strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                       ||'.Aggiornamento dati ordinativo per inserimento dati storno quietanza.';
          -- siac_r_ordinativo_storno
          insert into siac_r_ordinativo_storno
          ( ord_id,
 		    ord_storno_data,
		    ord_storno_numero,
		    ord_storno_importo,
		    oil_ricevuta_id,
		    validita_inizio,
	        ente_proprietario_id,
		    login_operazione
          )
          values
          (
           ricevutaRec.oil_ord_id,
           ricevutaRec.oil_ricevuta_data,
           numeroRicevuta,
           ricevutaRec.importoRicevuta,
           oilRicevutaId,
           now(),
           enteProprietarioId,
           loginOperazione
          )
          returning ord_storno_id into codResult;
         end if;

         if codResult is null  then
        	-- errore
            raise exception ' Errore in inserimento.';
	     end if;
       end if;

       strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                    ||'.Aggiornamento dati ordinativo.';
       if ordStatoRChiudiId is not null then
       	strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                      ||'.Aggiornamento dati ordinativo per chiusura stato operativo attuale.';
       	update siac_r_ordinativo_stato stato set validita_fine=now(), login_operazione=loginOperazione
        where ord_stato_r_id=ordStatoRChiudiId;

        -- aggiorno contatore ordinativi aggiornati
        --countOrdAgg:=countOrdAgg+1;

       end if;

	   strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                    ||'.Aggiornamento dati ordinativo.';
       if ordStatoApriId is not null then
        codResult:=null;
        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Aggiornamento dati ordinativo per inserimento nuovo stato operativo attuale.';
       	insert into siac_r_ordinativo_stato
        ( ord_id,
          ord_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        values
        ( ricevutaRec.oil_ord_id,
          ordStatoApriId,
          now(),
          enteProprietarioId,
          loginOperazione
        )
        returning ord_stato_r_id into codResult;

        if codResult is null then
        	raise exception ' Errore in inserimento.';
        end if;

       end if;

       strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                       ||'.Aggiornamento dati ordinativo.';
       -- PCC
       if ricevutaRec.oil_ricevuta_tipo='U'
          and ricevutaRec.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE
          and ordStatoApriId=ordStatoQuietId then
        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                       ||'.Aggiornamento dati ordinativo per inserimento dati quietanza in registro PCC.';
        --codResult:=null;

        insert into siac_t_registro_pcc
        (doc_id,
 	     subdoc_id,
         pccop_tipo_id,
         ordinativo_data_emissione,
         ordinativo_numero,
         rpcc_quietanza_data,
         rpcc_quietanza_numero,
	     rpcc_quietanza_importo,
		 soggetto_id,
         validita_inizio,
         ente_proprietario_id,
         login_operazione
        )
        (
         with
         soggetto as
         (select soggetto_id
          from siac_r_ordinativo_soggetto s
          where s.ord_id=ricevutaRec.oil_ord_id
          and   s.data_cancellazione is null
          and   s.validita_fine is null),
          doc as
         (select distinct subdoc.doc_id, subdoc.subdoc_id, subdoc.subdoc_importo, doc.doc_tipo_id
	      from  siac_t_ordinativo_ts ts, siac_r_subdoc_ordinativo_ts rsubdoc,
                siac_t_subdoc subdoc, siac_t_doc doc
          where ts.ord_id=ricevutaRec.oil_ord_id
          and   rsubdoc.ord_ts_id=ts.ord_ts_id
          and   subdoc.subdoc_id=rsubdoc.subdoc_id
          and   doc.doc_id=subdoc.doc_id
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   rsubdoc.data_cancellazione is null
          and   rsubdoc.validita_fine is null
          and   subdoc.data_cancellazione is null
          and   subdoc.validita_fine is null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         ),
         tipodoc as -- 11.02.2016 Sofia aggiunto filtro sul attributo flagComunicaPCC
         (select tipo.doc_tipo_id
          from siac_d_doc_tipo tipo ,siac_r_doc_tipo_attr attr
          where attr.attr_id=comPccAttrId
          and   attr.boolean='S'
          and   tipo.doc_tipo_id=attr.doc_tipo_id
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
          and   tipo.data_cancellazione is null
          and   tipo.validita_fine is null
         ),
         quiet as
         (
            with
             ord as
             ( select ricevutaRec.oil_ord_id oil_ord_id )
         	 ( select ord.oil_ord_id ,coalesce(quietOrd.quietNum,0) quietNum
 			   from ord
               left outer join
               (select  r.ord_id, count(*) quietNum
                from siac_r_ordinativo_quietanza r
                where r.data_cancellazione is null
                and   r.oil_ricevuta_id!=oilRicevutaId
                group by r.ord_id
               ) quietOrd  on (quietOrd.ord_id=ord.oil_ord_id)
              )
         )
         select
          doc.doc_id,
          doc.subdoc_id,
          pccOperazTipoId,
          ricevutaRec.oil_ord_data_emissione,
          ricevutaRec.oil_ord_numero,
          ricevutaRec.oil_ricevuta_data,
          numeroRicevuta,
          doc.subdoc_importo,
          soggetto.soggetto_id,
          now(),
          enteProprietarioId,
          loginOperazione
         from soggetto, doc, quiet, tipodoc
         where quiet.quietNum=0
         and   doc.doc_tipo_id=tipodoc.doc_tipo_id -- 11.02.2016 Sofia aggiunto filtro sul attributo flagComunicaPCC
        );
--        returning rpcc_id into codResult;

--        if codResult is null then
--        	raise exception ' Errore in inserimento.';
--        end if;
       end if;

       -- aggiorno contatore ordinativi aggiornati
       countOrdAgg:=countOrdAgg+1;
	   raise notice 'countOrdAgg=%',countOrdAgg;
    end loop;

	strMessaggio:='Inserimento scarti ricevute [siac_oil_ricevute] dopo ciclo di elaborazione.';
    -- inserire in siac_t_oil_ricevuta i dati scartati presenti in mif_t_oil_ricevuta
    insert into siac_t_oil_ricevuta
    ( oil_ricevuta_anno,
      oil_ricevuta_numero,
      oil_ricevuta_data,
      oil_ricevuta_tipo,
      oil_ricevuta_importo,
      oil_ricevuta_cro1,
      oil_ricevuta_cro2,
--    oil_ricevuta_note_tes,
--    oil_ricevuta_denominazione,
      oil_ricevuta_errore_id,
      oil_ricevuta_tipo_id,
      oil_ricevuta_note,
      oil_ord_bil_id,
      oil_ord_id,
      flusso_elab_mif_id,
      oil_progr_ricevuta_id,
      oil_progr_dett_ricevuta_id,
      oil_ord_anno_bil,
      oil_ord_numero,
      oil_ord_importo,
      oil_ord_data_emissione,
      oil_ord_data_annullamento,
      oil_ord_trasm_oil_data,
      oil_ord_data_firma,
      oil_ord_importo_quiet,
      oil_ord_importo_storno,
      oil_ord_importo_quiet_tot,
      validita_inizio,
      ente_proprietario_id,
      login_operazione)
    ( select
       annoBilancio,
       m.oil_ricevuta_numero,
       m.oil_ricevuta_data,
       m.oil_ricevuta_tipo,
       m.oil_ricevuta_importo,
       m.oil_ricevuta_cro1,
       m.oil_ricevuta_cro2,
--     oil_ricevuta_note_tes,
--     oil_ricevuta_denominazione,
       m.oil_ricevuta_errore_id,
       m.oil_ricevuta_tipo_id,
       m.oil_ricevuta_note,
       m.oil_ord_bil_id,
       m.oil_ord_id,
       flussoElabMifId,
       m.oil_progr_ricevuta_id,
       m.oil_progr_dett_ricevuta_id,
       m.oil_ord_anno_bil,
       m.oil_ord_numero,
       m.oil_ord_importo,
       m.oil_ord_data_emissione,
       m.oil_ord_data_annullamento,
       m.oil_ord_trasm_oil_data,
       m.oil_ord_data_firma,
       m.oil_ord_importo_quiet,
       m.oil_ord_importo_storno,
       m.oil_ord_importo_quiet_tot,
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
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_hrer flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emap_hrer where flusso_elab_mif_id=flussoElabMifId;
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_rr flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emap_rr  where flusso_elab_mif_id=flussoElabMifId;
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_dr flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emap_dr  where flusso_elab_mif_id=flussoElabMifId;


    -- chiudere elaborazione
	-- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
    strMessaggio:='Elaborazione flusso quietanze.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId||'.'
                  ||'Aggiornati ordinativi num='||countOrdAgg||'.';
    update  mif_t_flusso_elaborato
    set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
   	   ('OK','ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '||QUIET_MIF_ELAB_FLUSSO_TIPO||'. AGGIORNATI NUM='||countOrdAgg||' ORDINATIVI.',countOrdAgg,now())
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
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_hrer flussoElabMifId='||flussoElabMifId||'.';
	   	delete from mif_t_elab_emap_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_rr  where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_dr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_dr  where flusso_elab_mif_id=flussoElabMifId;

   --     if codErrore is not null then
        	update  mif_t_flusso_elaborato
    		set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  		('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
		    where flusso_elab_mif_id=flussoElabMifId;

  --      end if;

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
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_rr  where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_dr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emap_dr  where flusso_elab_mif_id=flussoElabMifId;

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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_rr  where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_dr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emap_dr  where flusso_elab_mif_id=flussoElabMifId;


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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emap_hrer where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_rr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emap_rr  where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emap_dr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emap_dr  where flusso_elab_mif_id=flussoElabMifId;

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