/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac-6174 - Sofia - inizio
CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_firme
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

	PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';

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

	ordStatoFirmaId integer:=null;
    ordStatoTrasmId integer:=null;
    ordStatoQuietId integer:=null;

    enteOilRec record;
    ricevutaRec record;

	bilancioId integer:=null;
	periodoId integer:=null;

    codResult integer :=null;
    codErrore varchar(10) :=null;

    oilRicevutaId  integer :=null;
    ordStatoId integer :=null;
    ordStatoRId integer :=null;
    ordStatoApriId integer :=null;

	countOrdAgg numeric:=0;

    annoBilancioCurr integer; -- 29.12.2017 Sofia
BEGIN

	strMessaggioFinale:='Elaborazione flusso firme tipo flusso='||tipoFlussoMif||'.Identificativo flusso='||flussoElabMifId||'.';

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
    and   tipoFlussoMif=FIRME_MIF_ELAB_FLUSSO_TIPO;

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

	if enteOilRec.ente_oil_firme_ord=false then
    	raise exception ' Gestione firme ordinativi non attiva.';
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

	-- verifca esistenza mif_t_elab_emfe_hrer ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emfe_hrer].';
    select distinct 1  into codResult
    from  mif_t_elab_emfe_hrer m, mif_t_flusso_elaborato mif
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

	-- verifca esistenza mif_t_elab_emfe_rr ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_emfe_rr].';
    select distinct 1  into codResult
    from  mif_t_elab_emfe_rr m, mif_t_flusso_elaborato mif
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


	-- verifca esistenza mif_t_emfe_hrer
    strMessaggio:='Verifica esistenza record da elaborare [mif_t_emfe_hrer].';
    select distinct 1  into codResult
    from  mif_t_emfe_hrer m
    where m.flusso_elab_mif_id=flussoElabMifId
    and   m.ente_proprietario_id=enteProprietarioId;

    if codResult is null then
    	raise exception ' Nessun record da elaborare.';
    end if;

    -- 29.12.2017 Sofia - problema firme a cui non passano anno corretto
	select extract ( year from  now()::timestamp)::integer into annoBilancioCurr;

    if annoBilancio<annoBilancioCurr then
    	select extract ( year from  dataElaborazione)::integer into annoBilancio;
	end if;
    -- 29.12.2017 Sofia - problema firme a cui non passano anno corretto

    -- inserimento mif_t_elab_emap_hrer
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emfe_hrer da mif_t_emfe_hrer].';
    insert into mif_t_elab_emfe_hrer
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
     from mif_t_emfe_hrer mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );

    -- inserimento mif_t_elab_emfe_rr
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_emfe_rr da mif_t_emfe_rr].';
    insert into mif_t_elab_emfe_rr
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
      firma_data,
      firma_nome,
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
      firma_data,
      firma_nome,
      now(),
      loginOperazione,
      enteProprietarioId
     from mif_t_emfe_rr mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );


	-- lettura tipoRicevuta
    strMessaggio:='Lettura tipo ricevuta '||FIRME_MIF_FLUSSO_TIPO_CODE||'.';
	select tipo.oil_ricevuta_tipo_id, coalesce(tipo.oil_ricevuta_tipo_code_fl ,FIRME_MIF_FLUSSO_TIPO)
           into strict oilRicevutaTipoId, oilRicevutaTipoCodeFl
    from siac_d_oil_ricevuta_tipo tipo
    where tipo.oil_ricevuta_tipo_code=FIRME_MIF_FLUSSO_TIPO_CODE
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




	-- controlli di integrita flusso
    strMessaggio:='Verifica integrita'' flusso-esistenza record di testata ['||TIPO_REC_TESTA||'].';
    codResult:=null;
    select distinct 1  into codResult
    from mif_t_elab_emfe_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_TESTA;

    if codResult is null then
    	codErrore:=MIF_TESTATA_COD_ERR;
        raise exception ' COD.ERRORE=%',codErrore;
    end if;


	strMessaggio:='Verifica integrita'' flusso-esistenza record di coda ['||TIPO_REC_CODA||'].';
    codResult:=null;
    select distinct 1  into codResult
    from mif_t_elab_emfe_hrer  mif
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
    from mif_t_elab_emfe_hrer  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.tipo_record=TIPO_REC_TESTA;

    if codResult is null then
    	codErrore:=MIF_TESTATA_COD_ERR;
    end if;
    if codErrore is null and
       ( tipoFlusso is null or tipoFlusso='' or tipoFlusso!=oilRicevutaTipoCodeFl ) then
    	codErrore:=MIF_FLUSSO_FI_COD_ERR;
    end if;

    if codErrore is null and
       ( dataOraFlusso is null or dataOraFlusso='' ) then
    	codErrore:=MIF_DT_ORA_TESTA_COD_ERR;
    end if;

    if codErrore is null and
       ( numRicevute is null or numRicevute='' ) then
	    codErrore:=MIF_RICEVUTE_TESTA_COD_ERR;
    end if;

    raise notice 'codiceEnteBt=%',(coalesce(codiceEnteBt,'0')::integer)::varchar;
    raise notice 'enteOilRec.ente_oil_codice=%',enteOilRec.ente_oil_codice;
    raise notice 'codiceAbiBt=%',(coalesce(codiceAbiBt,'0')::integer)::varchar;
    raise notice 'enteOilRec.ente_oil_abi=%',enteOilRec.ente_oil_abi;

    if codErrore is null and
--       ( codiceAbiBt is null or codiceAbiBt='' or codiceAbiBt!=enteOilRec.ente_oil_abi or
--         codiceEnteBt is null or codiceEnteBt='' or codiceEnteBt!=enteOilRec.ente_oil_codice ) then
--  23.05.2018 Sofia siac-6174
       ( codiceAbiBt is null or codiceAbiBt='' or coalesce(codiceAbiBt,'0')::integer!=enteOilRec.ente_oil_abi::integer or
         codiceEnteBt is null or codiceEnteBt='' or coalesce(codiceEnteBt,'0')::integer!=enteOilRec.ente_oil_codice::integer ) then
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
     from mif_t_elab_emfe_hrer  mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.tipo_record=TIPO_REC_CODA;


      if codResult is null then
    	codErrore:=MIF_CODA_COD_ERR;
      end if;
      if codErrore is null and
       ( tipoFlusso is null or tipoFlusso='' or tipoFlusso!=oilRicevutaTipoCodeFl ) then
    	codErrore:=MIF_FLUSSO_FI_C_COD_ERR;
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
--        ( codiceAbiBt is null or codiceAbiBt='' or codiceAbiBt!=enteOilRec.ente_oil_abi or
         --codiceEnteBt is null or codiceEnteBt='' or codiceEnteBt!=enteOilRec.ente_oil_codice ) then
	     --  23.05.2018 Sofia siac-6174
       ( codiceAbiBt is null or codiceAbiBt='' or coalesce(codiceAbiBt,'0')::integer!=enteOilRec.ente_oil_abi::integer or
         codiceEnteBt is null or codiceEnteBt='' or coalesce(codiceEnteBt,'0')::integer!=enteOilRec.ente_oil_codice::integer ) then

         codErrore:=MIF_DATI_ENTE_CODA_COD_ERR;
      end if;
    end if;

    -- verifica integrita'' flusso esistenza di un record RR
	if codErrore is null then
    	strMessaggio:='Verifica integrita'' flusso-esistenza record di ricevuta ['||TIPO_REC_RR||'].';
    	codResult:=null;
   		select distinct 1  into codResult
   		from mif_t_elab_emfe_rr  mif
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
        from mif_t_elab_emfe_rr mif
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
     from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
     from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
     from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
     from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   rr.esito_derivato is not null and  rr.esito_derivato !=''
     and   not exists (select distinct 1 from siac_d_oil_esito_derivato d
     				   where d.oil_esito_derivato_code=rr.esito_derivato
                       and   d.ente_proprietario_id=enteProprietarioId
                       and   d.oil_ricevuta_tipo_id=oilRicevutaTipoId
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
     from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
-- 23.05.2018 Sofia siac-6174
--     and   ( rr.codice_abi_bt is null or rr.codice_abi_bt='' or rr.codice_abi_bt!=enteOilRec.ente_oil_abi or
--             rr.codice_ente_bt is null or rr.codice_ente_bt='' or rr.codice_ente_bt!=enteOilRec.ente_oil_codice)
     and   ( rr.codice_abi_bt is null or rr.codice_abi_bt='' or coalesce(rr.codice_abi_bt,'0')::integer!=enteOilRec.ente_oil_abi::integer or
             rr.codice_ente_bt is null or rr.codice_ente_bt='' or coalesce(rr.codice_ente_bt,'0')::integer!=enteOilRec.ente_oil_codice::integer)

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
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.qualificatore is not null and rr.qualificatore!=''
      and   not exists ( select distinct 1
                         from siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e
                         where q.oil_qualificatore_code=rr.qualificatore
                         and   q.ente_proprietario_id=enteProprietarioId
                         and   e.oil_esito_derivato_id=q.oil_esito_derivato_id
                         and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      				   )
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


     -- MIF_RR_DATI_FIRMA_COD_ERR dati firma non indicati
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] dati firma non indicati.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   ( rr.firma_data is null or rr.firma_data='' or
	          rr.firma_nome is null or  rr.firma_nome='' )
      and errore.oil_ricevuta_errore_code=MIF_RR_DATI_FIRMA_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
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
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   ( rr.esercizio is null or rr.esercizio='' or
	          rr.numero_ordinativo is null or  rr.numero_ordinativo='' )
      and errore.oil_ricevuta_errore_code=MIF_RR_DATI_ORD_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- MIF_RR_ANNO_ORD_COD_ERR anno ordinativo non corretto
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||'] anno ordinativo non corretto rispetto all''anno di bilancio corrente.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
	  validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore
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
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
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
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
	  and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
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
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 ord.bil_id,ord.ord_id,rr.esercizio::integer,rr.numero_ordinativo::integer,stato.validita_inizio,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_stato stato
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_ANNULL_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoSpesaId
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
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 ord.bil_id,ord.ord_id,rr.esercizio::integer,rr.numero_ordinativo::integer,stato.validita_inizio,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_stato stato
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_ANNULL_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
--      and   ord.ord_tipo_id=ordTipoSpesaId 20.09.2016 Sofia HD-INC000001250308
      and   ord.ord_tipo_id=ordTipoEntrataId --  20.09.2016 Sofia HD-INC000001250308
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   stato.ord_id=ord.ord_id
      and   stato.ord_stato_id=ordStatoAnnullatoId
      and   stato.data_cancellazione is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- ordinativo non deve essere stato firmato
     -- MIF_RR_ORD_FIRMATO_COD_ERR
     -- [ordinativo spesa]
     /* 27.02.2018 Sofia jira siac-5849  firme multiple , si inserisce sempre l'ultima
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa firmato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_bil_id,oil_ord_id,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_firma,oil_ord_nome_firma,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 ord.bil_id,ord.ord_id,rr.esercizio::integer,rr.numero_ordinativo::integer,
             firma.ord_firma_data,firma.ord_firma,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_firma firma
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_FIRMATO_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   firma.ord_id=ord.ord_id
      and   firma.data_cancellazione is null
      and   firma.validita_fine is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

     -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata firmato.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_bil_id,oil_ord_id,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_firma,oil_ord_nome_firma,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 ord.bil_id,ord.ord_id,rr.esercizio::integer,rr.numero_ordinativo::integer,
             firma.ord_firma_data,firma.ord_firma,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_firma firma
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_FIRMATO_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   firma.ord_id=ord.ord_id
      and   firma.data_cancellazione is null
      and   firma.validita_fine is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));
     */


	 -- data_trasmissione ordinativo non valorizzata o  successiva data_firma
     -- MIF_RR_ORD_DT_TRASM_COD_ERR data_trasmissione ordinativo  successiva data_firma
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa non trasmesso o in data successiva alla data di firma.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       oil_ord_data_firma,
       oil_ord_nome_firma,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 rr.firma_data::timestamp,
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             ord.ord_trasm_oil_data,
             rr.firma_data::timestamp,
             rr.firma_nome,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   ( ord.ord_trasm_oil_data is null or
              date_trunc('DAY',ord.ord_trasm_oil_data)>date_trunc('DAY',rr.firma_data::timestamp) )
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_TRASM_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata non trasmesso o in data successiva alla data di firma.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       oil_ord_data_firma,
       oil_ord_nome_firma,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 rr.firma_data::timestamp,
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             ord.ord_trasm_oil_data,
             rr.firma_data::timestamp,
             rr.firma_nome,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
      and   ( ord.ord_trasm_oil_data is null or
              date_trunc('DAY',ord.ord_trasm_oil_data)>date_trunc('DAY',rr.firma_data::timestamp) )
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_TRASM_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));


     -- ordinativo non deve essere stato quietanzato in data antecedente alla data firma
     -- MIF_RR_ORD_QUIET_COD_ERR
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa quietanzato in data antecedente alla firma.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_bil_id,oil_ord_id,oil_ord_anno_bil,oil_ord_numero,
       oil_ricevuta_data,oil_ord_nome_firma, oil_ord_data_firma, oil_ord_data_quietanza,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
	 (with
	  quiet as
	  (select distinct
              rr.id id,
              ord.bil_id bil_id,
              ord.ord_id ord_id,
              rr.firma_nome ord_nome_firma,
              rr.firma_data::timestamp ord_data_firma,
              rr.esercizio::integer ord_esercizio,
              rr.numero_ordinativo::integer ord_numero_ordinativo,
              q.oil_qualificatore_segno oil_qualificatore_segno,
              max(r.ord_quietanza_data) ord_quietanza_data
	   from siac_r_ordinativo_quietanza r, siac_t_ordinativo ord,
            mif_t_elab_emfe_rr rr,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_bil bil, siac_t_periodo per
	   where  ord.ente_proprietario_id=enteProprietarioId
	   and    ord.ord_tipo_id=ordTipoSpesaId
	   and    ord.data_cancellazione is null
	   and    ord.validita_fine is null
	   and    r.ord_id=ord.ord_id
	   and    r.data_cancellazione is null
	   and    r.validita_fine is null
       and    rr.flusso_elab_mif_id=flussoElabMifId
       and    bil.bil_id=ord.bil_id
       and    per.periodo_id=bil.periodo_id
       and    rr.esercizio=per.anno
       and    rr.numero_ordinativo::integer=ord.ord_numero
       and    q.oil_qualificatore_code=rr.qualificatore
       and    q.ente_proprietario_id=enteProprietarioId
       and    q.oil_qualificatore_segno='U'
       and    e.oil_esito_derivato_code=rr.esito_derivato
       and    e.ente_proprietario_id=q.ente_proprietario_id
       and    q.oil_esito_derivato_id=e.oil_esito_derivato_id
       and    e.oil_ricevuta_tipo_id=oilRicevutaTipoId
       and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.id)
       group by rr.id,
                ord.bil_id,
                ord.ord_id,
                rr.firma_nome,
                rr.firma_data,
                rr.esercizio::integer,
                rr.numero_ordinativo::integer,
                q.oil_qualificatore_segno
      )
      (select errore.oil_ricevuta_errore_id,
              oilRicevutaTipoId,
              flussoElabMifId,
              quiet.id,
		      quiet.bil_id,
              quiet.ord_id,
			  quiet.ord_esercizio,
              quiet.ord_numero_ordinativo,
              quiet.ord_data_firma,
              quiet.ord_nome_firma,
              quiet.ord_data_firma,
              quiet.ord_quietanza_data,
              quiet.oil_qualificatore_segno,
	          now(),
              enteProprietarioId,
              loginOperazione
      from  quiet, siac_d_oil_ricevuta_errore errore
      where ( ( quiet.ord_quietanza_data<=quiet.ord_data_firma and enteOilRec.ente_oil_siope_plus=false ) or
              ( quiet.ord_quietanza_data<quiet.ord_data_firma and enteOilRec.ente_oil_siope_plus=true )
             ) -- 24.01.2018 Sofia siac-5765
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_QUIET_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      ));


      -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata quietenzato in data antecedente alla firma.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ord_bil_id,oil_ord_id,oil_ord_anno_bil,oil_ord_numero,
       oil_ricevuta_data,oil_ord_nome_firma, oil_ord_data_firma, oil_ord_data_quietanza,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
	 (with
	  quiet as
	  (select distinct
              rr.id id,
              ord.bil_id bil_id,
              ord.ord_id ord_id,
              rr.firma_nome ord_nome_firma,
              rr.firma_data::timestamp ord_data_firma,
              rr.esercizio::integer ord_esercizio,
              rr.numero_ordinativo::integer ord_numero_ordinativo,
              q.oil_qualificatore_segno oil_qualificatore_segno,
              max(r.ord_quietanza_data) ord_quietanza_data
	   from siac_r_ordinativo_quietanza r, siac_t_ordinativo ord,
            mif_t_elab_emfe_rr rr,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_bil bil, siac_t_periodo per
	   where  ord.ente_proprietario_id=enteProprietarioId
	   and    ord.ord_tipo_id=ordTipoEntrataId
	   and    ord.data_cancellazione is null
	   and    ord.validita_fine is null
	   and    r.ord_id=ord.ord_id
	   and    r.data_cancellazione is null
	   and    r.validita_fine is null
       and    rr.flusso_elab_mif_id=flussoElabMifId
       and    bil.bil_id=ord.bil_id
       and    per.periodo_id=bil.periodo_id
       and    rr.esercizio=per.anno
       and    rr.numero_ordinativo::integer=ord.ord_numero
       and    q.oil_qualificatore_code=rr.qualificatore
       and    q.ente_proprietario_id=enteProprietarioId
       and    q.oil_qualificatore_segno='E'
       and    e.oil_esito_derivato_code=rr.esito_derivato
       and    e.ente_proprietario_id=q.ente_proprietario_id
       and    q.oil_esito_derivato_id=e.oil_esito_derivato_id
       and    e.oil_ricevuta_tipo_id=oilRicevutaTipoId
       and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.id)
       group by rr.id,
                ord.bil_id,
                ord.ord_id,
                rr.firma_nome,
                rr.firma_data,
                rr.esercizio::integer,
                rr.numero_ordinativo::integer,
                q.oil_qualificatore_segno
      )
      (select errore.oil_ricevuta_errore_id,
              oilRicevutaTipoId,
              flussoElabMifId,
              quiet.id,
		      quiet.bil_id,
              quiet.ord_id,
              quiet.ord_esercizio,
              quiet.ord_numero_ordinativo,
              quiet.ord_data_firma,
              quiet.ord_nome_firma,
              quiet.ord_data_firma,
              quiet.ord_quietanza_data,
              quiet.oil_qualificatore_segno,
	          now(),
              enteProprietarioId,
              loginOperazione
      from  quiet, siac_d_oil_ricevuta_errore errore
      where ( ( quiet.ord_quietanza_data<=quiet.ord_data_firma and enteOilRec.ente_oil_siope_plus=false ) or
              ( quiet.ord_quietanza_data<quiet.ord_data_firma  and enteOilRec.ente_oil_siope_plus=true )
            ) -- 24.01.2018 Sofia siac-5765
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_QUIET_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      ));

     -- data_emissione ordinativo  successiva data_firma
     -- MIF_RR_ORD_DT_EMIS_COD_ERR data_emissione ordinativo  successiva data_firma
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di spesa emesso in data successiva alla data di firma.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ord_nome_firma, oil_ord_data_firma,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 rr.firma_data::timestamp,
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             rr.firma_nome,rr.firma_data::timestamp,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='U'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
--      and   ord.ord_emissione_data>rr.firma_data::timestamp
      and   date_trunc('DAY',ord.ord_emissione_data)>rr.firma_data::timestamp -- 24.01.2018 Sofia siac-5765
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_EMIS_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));

	 -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ['||TIPO_REC_RR||']  ordinativo di entrata emesso in data successiva alla data di firma.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_data,
       oil_ord_bil_id,oil_ord_id,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_data_emissione,
       oil_ord_nome_firma, oil_ord_data_firma,
       oil_ricevuta_tipo,
	   validita_inizio, ente_proprietario_id,login_operazione
     )
     (select errore.oil_ricevuta_errore_id,oilRicevutaTipoId,flussoElabMifId,rr.id,
     		 rr.firma_data::timestamp,
     		 ord.bil_id,ord.ord_id,
     		 rr.esercizio::integer,rr.numero_ordinativo::integer,
             ord.ord_emissione_data,
             rr.firma_nome,rr.firma_data::timestamp,
             q.oil_qualificatore_segno,
            now(),enteProprietarioId,loginOperazione
      from  mif_t_elab_emfe_rr rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   q.oil_qualificatore_code=rr.qualificatore
      and   q.ente_proprietario_id=enteProprietarioId
      and   q.oil_qualificatore_segno='E'
      and   e.oil_esito_derivato_code=rr.esito_derivato
      and   e.ente_proprietario_id=q.ente_proprietario_id
      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
      and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero=rr.numero_ordinativo::integer
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno=rr.esercizio
--      and   ord.ord_emissione_data>rr.firma_data::timestamp
      and   date_trunc('DAY',ord.ord_emissione_data)>rr.firma_data::timestamp  -- 24.01.2018 Sofia siac-5765
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_EMIS_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.id));





		-- inserimento record da elaborare
    	-- [ordinativo spesa]
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativato spesa da elaborare.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,
          flusso_elab_mif_id,
          oil_progr_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ord_data_firma,
          oil_ord_nome_firma,
	      oil_ord_id,
          oil_ord_bil_id,
	      oil_ord_anno_bil,
          oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_quietanza,
	      oil_ricevuta_tipo,
		  validita_inizio,
          ente_proprietario_id,
          login_operazione
	    )
    	(select oilRicevutaTipoId,
                flussoElabMifId,
        		rr.id,
     		    rr.firma_data::timestamp,
                rr.firma_data::timestamp,
                rr.firma_nome,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                quietOrd.ord_data_quietanza,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	     from  mif_t_elab_emfe_rr rr,
    	       siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
        	   siac_t_bil bil, siac_t_periodo per,
               siac_t_ordinativo ord
               left outer join
	          (select quiet.ord_id ord_id, max(quiet.ord_quietanza_data) ord_data_quietanza
    	       from siac_r_ordinativo_quietanza quiet
        	   where quiet.ente_proprietario_id=enteProprietarioId
               and   quiet.data_cancellazione is null
    	       and   quiet.validita_fine is null
               group by quiet.ord_id) quietOrd on (quietOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='U'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoSpesaId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.id));

    	-- [ordinativo entrata]
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativato entrata da elaborare.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_tipo_id,
          flusso_elab_mif_id,
          oil_progr_ricevuta_id,
    	  oil_ricevuta_data,
          oil_ord_data_firma,
          oil_ord_nome_firma,
	      oil_ord_id,
          oil_ord_bil_id,
	      oil_ord_anno_bil,
          oil_ord_numero,
	      oil_ord_data_emissione,
	      oil_ord_trasm_oil_data,
          oil_ord_data_quietanza,
	      oil_ricevuta_tipo,
		  validita_inizio,
          ente_proprietario_id,
          login_operazione
	    )
    	(select oilRicevutaTipoId,
                flussoElabMifId,
        		rr.id,
     		    rr.firma_data::timestamp,
                rr.firma_data::timestamp,
                rr.firma_nome,
     		 	ord.ord_id, ord.bil_id,
	     		rr.esercizio::integer,rr.numero_ordinativo::integer,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                quietOrd.ord_data_quietanza,
	            q.oil_qualificatore_segno,
    	        now(),enteProprietarioId,loginOperazione
	     from  mif_t_elab_emfe_rr rr,
    	       siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,
        	   siac_t_bil bil, siac_t_periodo per,
               siac_t_ordinativo ord
               left outer join
	          (select quiet.ord_id ord_id, max(quiet.ord_quietanza_data) ord_data_quietanza
    	       from siac_r_ordinativo_quietanza quiet
        	   where quiet.ente_proprietario_id=enteProprietarioId
               and   quiet.data_cancellazione is null
    	       and   quiet.validita_fine is null
               group by quiet.ord_id) quietOrd on (quietOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
    	  and   q.oil_qualificatore_code=rr.qualificatore
	      and   q.ente_proprietario_id=enteProprietarioId
    	  and   q.oil_qualificatore_segno='E'
	      and   e.oil_esito_derivato_code=rr.esito_derivato
    	  and   e.ente_proprietario_id=q.ente_proprietario_id
	      and   q.oil_esito_derivato_id=e.oil_esito_derivato_id
    	  and   e.oil_ricevuta_tipo_id=oilRicevutaTipoId
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero=rr.numero_ordinativo::integer
    	  and   ord.ord_tipo_id=ordTipoEntrataId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno=rr.esercizio
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
            mif.oil_ricevuta_tipo_id,
            mif.oil_ord_bil_id,
            mif.oil_ord_anno_bil,
            mif.oil_ord_id,
            mif.oil_ord_numero,
            mif.oil_ord_data_emissione,
            mif.oil_ord_data_firma,
            mif.oil_ord_trasm_oil_data,
            mif.oil_ord_data_quietanza,
            mif.oil_ord_nome_firma,
            (case when mif.oil_ord_data_quietanza is not null then errore.oil_ricevuta_errore_desc
				  else null end) oil_ricevuta_note
     from mif_t_oil_ricevuta mif, siac_d_oil_ricevuta_errore errore
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.oil_ricevuta_errore_id is null
     and   errore.ente_proprietario_id=enteProprietarioId
     and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_FIRMA_QU_COD_ERR
     order by mif.oil_progr_ricevuta_id
    )
    loop
		codResult:=null;
        oilRicevutaId:=null;
		ordStatoId:=null;
        ordStatoRId:=null;
        ordStatoApriId:=null;
	    codErrore:=null;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';

        -- controlli

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Lettura stato attuale ordinativo.';
 		-- leggo lo stato attuale ordinativo
        if ricevutaRec.oil_ord_data_quietanza is not null then
	      	-- stato attuale
            --ordStatoId:=ordStatoQuietId; -- 27.02.2018 Sofia jira siac-5969

            -- stato verso cui cambiare
        	ordStatoApriId:=null;
        else
        	-- stato attuale
        	ordStatoId:=ordStatoTrasmId;

            -- stato verso cui cambiare
           	ordStatoApriId:=ordStatoFirmaId;
        end if;


        -- 27.02.2018 Sofia jira siac-5969
        -- cerco lo stato attuale solo se F, se non quietanzato
        if ordStatoId is not null then
         select stato.ord_stato_r_id into ordStatoRId
         from siac_r_ordinativo_stato stato
         where stato.ord_id=ricevutaRec.oil_ord_id
         and   stato.ord_stato_id=ordStatoId
         and   stato.data_cancellazione is null
         and   stato.validita_fine is null;

		 -- 05.03.2018 Sofia jira siac-5969
         /*if ordStatoRId is null then
        	-- scarto stato non congruente
            codErrore:=MIF_DR_ORD_STATO_ORD_ERR_COD_ERR;
         end if;*/
        end if;

       if codErrore is null then
        	raise notice 'IdStatoAttuale=% ordStatoRId=%  RR.ID=%',
            	ordStatoId,ordStatoRId,ricevutaRec.oil_progr_ricevuta_id;
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
    	      oil_ricevuta_data,
	  		  oil_ricevuta_tipo,
    	      oil_ricevuta_tipo_id,
              oil_ricevuta_errore_id,
	          oil_ord_bil_id,
    	      oil_ord_id,
	          flusso_elab_mif_id,
    	      oil_progr_ricevuta_id,
    	      oil_ord_anno_bil,
	          oil_ord_numero,
    	      oil_ord_data_emissione,
	          oil_ord_trasm_oil_data,
              oil_ord_data_quietanza,
    	      oil_ord_data_firma,
              oil_ord_nome_firma,
	          validita_inizio,
		      ente_proprietario_id,
			  login_operazione)
        	( select
              annoBilancio,
    	      ricevutaRec.oil_ricevuta_data,
        	  ricevutaRec.oil_ricevuta_tipo,
	          ricevutaRec.oil_ricevuta_tipo_id,
              errore.oil_ricevuta_errore_id,
	          ricevutaRec.oil_ord_bil_id,
	          ricevutaRec.oil_ord_id,
	          flussoElabMifId,
	          ricevutaRec.oil_progr_ricevuta_id,
	          ricevutaRec.oil_ord_anno_bil,
	          ricevutaRec.oil_ord_numero,
	          ricevutaRec.oil_ord_data_emissione,
	          ricevutaRec.oil_ord_trasm_oil_data,
	          ricevutaRec.oil_ord_data_quietanza,
	          ricevutaRec.oil_ord_data_firma,
              ricevutaRec.oil_ord_nome_firma,
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



		strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Inserimento ricevuta elaborata.';
	 	-- inserimento siac_t_oil_ricevuta
        insert into siac_t_oil_ricevuta
        ( oil_ricevuta_anno,
          oil_ricevuta_data,
  		  oil_ricevuta_tipo,
          oil_ricevuta_tipo_id,
          oil_ord_bil_id,
          oil_ord_id,
          flusso_elab_mif_id,
          oil_progr_ricevuta_id,
          oil_ord_anno_bil,
          oil_ord_numero,
          oil_ord_data_emissione,
          oil_ord_trasm_oil_data,
          oil_ord_data_quietanza,
          oil_ord_data_firma,
          oil_ord_nome_firma,
          oil_ricevuta_note,
          validita_inizio,
	      ente_proprietario_id,
		  login_operazione)
        values
        ( annoBilancio,
          ricevutaRec.oil_ricevuta_data,
          ricevutaRec.oil_ricevuta_tipo,
          ricevutaRec.oil_ricevuta_tipo_id,
          ricevutaRec.oil_ord_bil_id,
          ricevutaRec.oil_ord_id,
          flussoElabMifId,
          ricevutaRec.oil_progr_ricevuta_id,
          ricevutaRec.oil_ord_anno_bil,
          ricevutaRec.oil_ord_numero,
          ricevutaRec.oil_ord_data_emissione,
          ricevutaRec.oil_ord_trasm_oil_data,
          ricevutaRec.oil_ord_data_quietanza,
          ricevutaRec.oil_ord_data_firma,
          ricevutaRec.oil_ord_nome_firma,
          ricevutaRec.oil_ricevuta_note,
          now(),
		  enteProprietarioId,
          loginOperazione
        )
        returning oil_ricevuta_id into oilRicevutaId;

        if oilRicevutaId is null then
        	raise exception ' Errore in inserimento.';
        end if;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Inserimento dati firma [siac_r_ordinativo_firma].';
        codResult:=null;
        insert into siac_r_ordinativo_firma
        (ord_id,oil_ricevuta_id,ord_firma_data,ord_firma,
         validita_inizio,login_operazione,ente_proprietario_id)
        values
        (ricevutaRec.oil_ord_id,oilRicevutaId,ricevutaRec.oil_ord_data_firma,ricevutaRec.oil_ord_nome_firma,
         now(),loginOperazione,enteProprietarioId)
        returning ord_firma_id into codResult;
        if codResult is null  then
        	-- errore
            raise exception ' Errore in inserimento.';
	    end if;

        -- 08.03.2018 Sofia siac-5969
        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Chiusura precedente dato di firma [siac_r_ordinativo_firma].';

   		update siac_r_ordinativo_firma	r
        set     data_cancellazione=clock_timestamp(),
               login_operazione=r.login_operazione||'-'||loginOperazione
        where r.ord_id=ricevutaRec.oil_ord_id
        and   r.ord_firma_id!=codResult
        and   r.data_cancellazione is null;


	   strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                    ||'.Aggiornamento dati ordinativo.';
       if ordStatoApriId is not null then
        codResult:=null;
        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Aggiornamento dati ordinativo per inserimento nuovo stato operativo attuale.';
       	/* -- 27.02.2018 Sofia jira siac-5969
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
        returning ord_stato_r_id into codResult;*/

        -- 27.02.2018 Sofia jira siac-5969
        -- apre stato F solo se non esiste

        insert into siac_r_ordinativo_stato
        ( ord_id,
          ord_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        select
          ricevutaRec.oil_ord_id,
          ordStatoApriId,
          now(),
          enteProprietarioId,
          loginOperazione
        where not exists
        (
         select 1
         from siac_r_ordinativo_stato r
         where r.ord_id=ricevutaRec.oil_ord_id
         and   r.ord_stato_id=ordStatoApriId
         and   r.data_cancellazione is null
         and   r.validita_fine is null
        )
        returning ord_stato_r_id into codResult;


        /* -- 27.02.2018 Sofia jira siac-5969
        if codResult is null then
        	raise exception ' Errore in inserimento.';
        end if;*/
        -- 27.02.2018 Sofia jira siac-5969 chiude lo stato solo se T e aperto
	    if ordStatoRId is not null then
         strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                     ||'.Aggiornamento dati ordinativo per chiusura stato operativo attuale.';

         update siac_r_ordinativo_stato set validita_fine=now(), login_operazione=loginOperazione
         where  ord_stato_r_id=ordStatoRId;
		end if;

       end if;


       -- aggiorno contatore ordinativi aggiornati
       countOrdAgg:=countOrdAgg+1;

    end loop;

	strMessaggio:='Inserimento scarti ricevute [siac_oil_ricevute] dopo ciclo di elaborazione.';
    -- inserire in siac_t_oil_ricevuta i dati scartati presenti in mif_t_oil_ricevuta
    insert into siac_t_oil_ricevuta
    ( oil_ricevuta_anno,
      oil_ricevuta_data,
      oil_ricevuta_tipo,
      oil_ricevuta_errore_id,
      oil_ricevuta_tipo_id,
      oil_ord_bil_id,
      oil_ord_id,
      flusso_elab_mif_id,
      oil_progr_ricevuta_id,
      oil_ord_anno_bil,
      oil_ord_numero,
      oil_ord_data_emissione,
      oil_ord_data_annullamento,
      oil_ord_trasm_oil_data,
      oil_ord_data_quietanza,
      oil_ord_data_firma,
      oil_ord_nome_firma,
      validita_inizio,
      ente_proprietario_id,
      login_operazione)
    ( select
       annoBilancio,
       m.oil_ricevuta_data,
       m.oil_ricevuta_tipo,
       m.oil_ricevuta_errore_id,
       m.oil_ricevuta_tipo_id,
       m.oil_ord_bil_id,
       m.oil_ord_id,
       flussoElabMifId,
       m.oil_progr_ricevuta_id,
       m.oil_ord_anno_bil,
       m.oil_ord_numero,
       m.oil_ord_data_emissione,
       m.oil_ord_data_annullamento,
       m.oil_ord_trasm_oil_data,
       m.oil_ord_data_quietanza,
       m.oil_ord_data_firma,
       m.oil_ord_nome_firma,
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
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_hrer flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emfe_hrer where flusso_elab_mif_id=flussoElabMifId;
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_rr flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_emfe_rr  where flusso_elab_mif_id=flussoElabMifId;

    -- chiudere elaborazione
	-- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
    strMessaggio:='Elaborazione flusso firme.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId||'.'
                  ||'Aggiornati ordinativi num='||countOrdAgg||'.';
    update  mif_t_flusso_elaborato
    set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
   	   ('OK','ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '||FIRME_MIF_ELAB_FLUSSO_TIPO||'. AGGIORNATI NUM='||countOrdAgg||' ORDINATIVI.',countOrdAgg,now())
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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emfe_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emfe_rr  where flusso_elab_mif_id=flussoElabMifId;

       	update  mif_t_flusso_elaborato
   		set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
  		('KO','ElABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_hrer flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emfe_hrer where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_rr flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_emfe_rr  where flusso_elab_mif_id=flussoElabMifId;

		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ElABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_hrer flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emfe_hrer where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_rr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emfe_rr  where flusso_elab_mif_id=flussoElabMifId;


		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ElABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_hrer flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emfe_hrer where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_emfe_rr flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_elab_emfe_rr  where flusso_elab_mif_id=flussoElabMifId;

        update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ElABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,now())
		where flusso_elab_mif_id=flussoElabMifId;

        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- siac-6174 - Sofia - fine

-- siac-6124 - Sofia inizio

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_spesa', 
    'data_ins_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_spesa', 
    'data_completa_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_spesa', 
    'data_convalida_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_spesa', 
    'data_sosp_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_spesa', 
    'data_riattiva_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_spesa', 
    'causale_sosp_atto_allegato',
    'varchar(250)'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_entrata', 
    'data_ins_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_entrata', 
    'data_completa_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_entrata', 
    'data_convalida_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_entrata', 
    'data_sosp_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_entrata', 
    'data_riattiva_atto_allegato',
    'TIMESTAMP WITHOUT TIME ZONE'
);

SELECT fnc_dba_add_column_params(
	'siac_dwh_documento_entrata', 
    'causale_sosp_atto_allegato',
    'varchar(250)'
);


CREATE OR REPLACE FUNCTION fnc_siac_attoal_getDataStato
(
  attoAlId integer,
  attoalStatoCode varchar
)
RETURNS timestamp
AS
$body$
DECLARE

attoalRMaxStatoRicId integer;
attoalRMaxStatoNonRicId integer;
attoalRStatoId integer;

attoalDataStatoRel timestamp;


v_messaggiorisultato varchar;
BEGIN


	select max(rs.attoal_r_stato_id) into attoalRMaxStatoRicId
    from  siac_r_atto_allegato_stato rs, siac_d_atto_allegato_stato stato
    where rs.attoal_id=attoAlId
    and   stato.attoal_stato_id=rs.attoal_stato_id
    and   stato.attoal_stato_code=attoalStatoCode;

	select max(rs.attoal_r_stato_id) into attoalRMaxStatoNonRicId
    from  siac_r_atto_allegato_stato rs, siac_d_atto_allegato_stato stato
    where rs.attoal_id=attoAlId
    and   rs.attoal_r_stato_id<attoalRMaxStatoRicId
    and   stato.attoal_stato_id=rs.attoal_stato_id
    and   stato.attoal_stato_code!=attoalStatoCode;

   	select min(rs.attoal_r_stato_id) into attoalRStatoId
    from  siac_r_atto_allegato_stato rs, siac_d_atto_allegato_stato stato
    where rs.attoal_id=attoAlId
    and   rs.attoal_r_stato_id>attoalRMaxStatoNonRicId
    and   stato.attoal_stato_id=rs.attoal_stato_id;

    select rs.validita_inizio into attoalDataStatoRel
	from  siac_r_atto_allegato_stato rs
    where  rs.attoal_r_stato_id>=attoalRStatoId;

	return attoalDataStatoRel;

exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice '%',v_messaggiorisultato;
    return attoalDataStatoRel;
	when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice '%',v_messaggiorisultato;
    return attoalDataStatoRel;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_spesa (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

v_user_table varchar;
params varchar;
fnc_eseguita integer;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_spesa' ;

if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


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
'fnc_siac_dwh_documento_spesa',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

DELETE FROM siac.siac_dwh_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

INSERT INTO
  siac.siac_dwh_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  -- 	SIAC-5229
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id, -- SIAC-5573,
  --- 15.05.2018 Sofia SIAC-6124
  data_ins_atto_allegato,
  data_sosp_atto_allegato,
  causale_sosp_atto_allegato,
  data_riattiva_atto_allegato,
  data_completa_atto_allegato,
  data_convalida_atto_allegato
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
--nuova sezione coge 26-09-2016
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
-- CR 854
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
---- SIAC-5229
tb.v_arrotondamento,
-------------
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id, -- SIAC-5573,
--- 15.05.2018 Sofia SIAC-6124
tb.data_ins_atto_allegato::timestamp,
tb.data_sosp_atto_allegato::timestamp,
tb.causale_sosp_atto_allegato,
tb.data_riattiva_atto_allegato::timestamp,
tb.data_completa_atto_allegato::timestamp,
tb.data_convalida_atto_allegato::timestamp
from (
with doc as (
  with doc1 as (
select distinct
  --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
  b.doc_gruppo_tipo_id,
  g.ente_proprietario_id, g.ente_denominazione,
  a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
  case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
  a.doc_data_emissione, a.doc_data_scadenza,
  case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
  f.doc_stato_code, f.doc_stato_desc,
  c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
  a.doc_id, a.pcccod_id, a.pccuff_id,
  case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
  h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
  h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
  case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
  h.subdoc_data_pagamento_cec,
  a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
  h.notetes_id,h.dist_id,h.contotes_id,
  a.doc_sdi_lotto_siope,
  n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
  o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
  i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
  l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
  m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
  from siac_t_doc a
  left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
  left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
  ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
  --siac_d_doc_gruppo d,
  siac_r_doc_stato e,
  siac_d_doc_stato f,
  siac_t_ente_proprietario g,
  siac_t_subdoc h
  left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                     and i.data_cancellazione is null
                                     and i.validita_fine is null
  left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                             and l.data_cancellazione is null
                                             and l.validita_fine is null
  left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
  where b.doc_tipo_id=a.doc_tipo_id
  and c.doc_fam_tipo_id=b.doc_fam_tipo_id
  --and b.doc_gruppo_tipo_id=d.doc_gruppo_tipo_id
  and e.doc_id=a.doc_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and f.doc_stato_id=e.doc_stato_id
  and g.ente_proprietario_id=a.ente_proprietario_id
  and g.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
  AND c.doc_fam_tipo_code in ('S','IS')
  and h.doc_id=a.doc_id
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  AND g.data_cancellazione IS NULL
  AND h.data_cancellazione IS NULL
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  --d.soggetto_tipo_desc,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
 /* and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,   -- 15.05.2018 Sofia siac-6124
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato, -- 22.05.2018 Sofia siac-6124
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato  -- 22.05.2018 Sofia siac-6124
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  /*d.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato, */
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
  b.soggetto_id soggetto_id_atto_allegato,
  -- 16.05.2018 Sofia siac-6124
  a.attoal_sog_data_sosp data_sosp_atto_allegato,
  a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
  a.attoal_sog_data_riatt data_riattiva_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  /*and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  -- 16.05.2018 Sofia siac-6124
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato,
  -- 15.05.2018 Sofia siac-6124
  attoal.data_ins_atto_allegato,
  attoal.data_sosp_atto_allegato,
  attoal.causale_sosp_atto_allegato,
  attoal.data_riattiva_atto_allegato,
  attoal.data_completa_atto_allegato,
  attoal.data_convalida_atto_allegato
  from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  --and d.liq_stato_code<>'A'
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr11 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr16 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_riattivazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_riattivazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
*/
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr20 as (*/
/*SELECT distinct a.subdoc_id,
a.testo v_causale_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causale_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select
	    a.subdoc_id
		,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione
		,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
        ,a.subdoc_sosp_causale v_causale_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    )
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
case when cdr.doc_cdr_cdr_code is not null then cdc.doc_cdc_cdr_code::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
-- 	SIAC-5229
docattr9.v_arrotondamento,
--
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione, --subdocattr20.v_data_sospensione,--subdocattr11.v_data_sospensione, JIRA 5764
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,--subdocattr20.v_data_riattivazione,--subdocattr16.v_data_riattivazione, JIRA 5764
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione, --subdocattr20.v_causale_sospensione,JIRA 5764
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id, -- SIAC-5573,
-- 15.05.2018 Sofia siac-6124
eldocattall.data_ins_atto_allegato,
eldocattall.data_sosp_atto_allegato,
eldocattall.causale_sosp_atto_allegato,
eldocattall.data_riattiva_atto_allegato,
eldocattall.data_completa_atto_allegato,
eldocattall.data_convalida_atto_allegato
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id --origina multipli
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
--left join subdocattr11 on doc.subdoc_id=subdocattr11.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
--left join subdocattr16 on doc.subdoc_id=subdocattr16.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
--left join subdocattr20 on doc.subdoc_id=subdocattr20.subdoc_id jira 5764
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
) as tb;


esito:= 'Fine funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_entrata (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_doc_id record;
rec_subdoc_id record;
rec_attr record;
rec_classif_id record;
rec_classif_id_attr record;
-- Variabili per campi estratti dal cursore rec_doc_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno_doc INTEGER := null;
v_num_doc VARCHAR := null;
v_desc_doc VARCHAR := null;
v_importo_doc NUMERIC := null;
v_beneficiario_multiplo_doc VARCHAR := null;
v_data_emissione_doc TIMESTAMP := null;
v_data_scadenza_doc TIMESTAMP := null;
v_codice_bollo_doc VARCHAR := null;
v_desc_codice_bollo_doc VARCHAR := null;
v_collegato_cec_doc VARCHAR := null;
v_cod_pcc_doc VARCHAR := null;
v_desc_pcc_doc VARCHAR := null;
v_cod_ufficio_doc VARCHAR := null;
v_desc_ufficio_doc VARCHAR := null;
v_cod_stato_doc VARCHAR := null;
v_desc_stato_doc VARCHAR := null;
v_cod_gruppo_doc VARCHAR := null;
v_desc_gruppo_doc VARCHAR := null;
v_cod_famiglia_doc VARCHAR := null;
v_desc_famiglia_doc VARCHAR := null;
v_cod_tipo_doc VARCHAR := null;
v_desc_tipo_doc VARCHAR := null;
v_sogg_id_doc INTEGER := null;
v_cod_sogg_doc VARCHAR := null;
v_tipo_sogg_doc VARCHAR := null;
v_stato_sogg_doc VARCHAR := null;
v_rag_sociale_sogg_doc VARCHAR := null;
v_p_iva_sogg_doc VARCHAR := null;
v_cf_sogg_doc VARCHAR := null;
v_cf_estero_sogg_doc VARCHAR := null;
v_nome_sogg_doc VARCHAR := null;
v_cognome_sogg_doc VARCHAR := null;
--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc VARCHAR := null;
-- Variabili per campi estratti dal cursore rec_subdoc_id
v_num_subdoc INTEGER := null;
v_desc_subdoc VARCHAR := null;
v_importo_subdoc NUMERIC := null;
v_num_reg_iva_subdoc VARCHAR := null;
v_data_scadenza_subdoc TIMESTAMP := null;
v_convalida_manuale_subdoc VARCHAR := null;
v_importo_da_dedurre_subdoc NUMERIC := null;
v_splitreverse_importo_subdoc NUMERIC := null;
v_pagato_cec_subdoc VARCHAR := null;
v_data_pagamento_cec_subdoc TIMESTAMP := null;
v_anno_atto_amministrativo VARCHAR := null;
v_num_atto_amministrativo VARCHAR := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_cod_tipo_atto_amministrativo VARCHAR := null;
v_desc_tipo_atto_amministrativo VARCHAR := null;
v_cod_stato_atto_amministrativo VARCHAR := null;
v_desc_stato_atto_amministrativo VARCHAR := null;
v_causale_atto_allegato VARCHAR := null;
v_altri_allegati_atto_allegato VARCHAR := null;
v_dati_sensibili_atto_allegato VARCHAR := null;
v_data_scadenza_atto_allegato TIMESTAMP := null;
v_note_atto_allegato VARCHAR := null;
v_annotazioni_atto_allegato VARCHAR := null;
v_pratica_atto_allegato VARCHAR := null;
v_resp_amm_atto_allegato VARCHAR := null;
v_resp_contabile_atto_allegato VARCHAR := null;
v_anno_titolario_atto_allegato INTEGER := null;
v_num_titolario_atto_allegato VARCHAR := null;
v_vers_invio_firma_atto_allegato INTEGER := null;
v_cod_stato_atto_allegato VARCHAR := null;
v_desc_stato_atto_allegato VARCHAR := null;
v_anno_elenco_doc INTEGER := null;
v_num_elenco_doc INTEGER := null;
v_data_trasmissione_elenco_doc TIMESTAMP := null;
v_tot_quote_entrate_elenco_doc NUMERIC := null;
v_tot_quote_spese_elenco_doc NUMERIC := null;
v_tot_da_pagare_elenco_doc NUMERIC := null;
v_tot_da_incassare_elenco_doc NUMERIC := null;
v_cod_stato_elenco_doc VARCHAR := null;
v_desc_stato_elenco_doc VARCHAR := null;
v_note_tesoriere_subdoc VARCHAR := null;
v_cod_distinta_subdoc VARCHAR := null;
v_desc_distinta_subdoc VARCHAR := null;
v_tipo_commissione_subdoc VARCHAR := null;
v_conto_tesoreria_subdoc VARCHAR := null;
-- Variabili per i soggetti legati all'atto allegato
v_sogg_id_atto_allegato INTEGER := null;
v_cod_sogg_atto_allegato VARCHAR := null;
v_tipo_sogg_atto_allegato VARCHAR := null;
v_stato_sogg_atto_allegato VARCHAR := null;
v_rag_sociale_sogg_atto_allegato VARCHAR := null;
v_p_iva_sogg_atto_allegato VARCHAR := null;
v_cf_sogg_atto_allegato VARCHAR := null;
v_cf_estero_sogg_atto_allegato VARCHAR := null;
v_nome_sogg_atto_allegato VARCHAR := null;
v_cognome_sogg_atto_allegato VARCHAR := null;
-- Variabili per i classificatori
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
v_cod_tipo_avviso VARCHAR := null;
v_desc_tipo_avviso VARCHAR := null;
-- Variabili per gli attributi
v_rilevante_iva VARCHAR := null;
v_ordinativo_singolo VARCHAR := null;
v_ordinativo_manuale VARCHAR := null;
v_esproprio VARCHAR := null;
v_note VARCHAR := null;
v_avviso VARCHAR := null;
-- Variabili per i soggetti legati al subdoc
v_cod_sogg_subdoc VARCHAR := null;
v_tipo_sogg_subdoc VARCHAR := null;
v_stato_sogg_subdoc VARCHAR := null;
v_rag_sociale_sogg_subdoc VARCHAR := null;
v_p_iva_sogg_subdoc VARCHAR := null;
v_cf_sogg_subdoc VARCHAR := null;
v_cf_estero_sogg_subdoc VARCHAR := null;
v_nome_sogg_subdoc VARCHAR := null;
v_cognome_sogg_subdoc VARCHAR := null;
-- Variabili per gli ordinamenti legati ai documenti
v_bil_anno_ord VARCHAR := null;
v_anno_ord INTEGER := null;
v_num_ord NUMERIC := null;
v_num_subord VARCHAR := null;
-- Variabile per la sede secondaria
v_sede_secondaria_subdoc VARCHAR := null;
-- Variabili per gli accertamenti
v_bil_anno VARCHAR := null;
v_anno_accertamento INTEGER := null;
v_num_accertamento NUMERIC := null;
v_cod_accertamento VARCHAR := null;
v_desc_accertamento VARCHAR := null;
v_cod_subaccertamento VARCHAR := null;
v_desc_subaccertamento VARCHAR := null;
-- Variabili per la modalita' di pagamento
v_quietanziante VARCHAR := null;
v_data_nascita_quietanziante TIMESTAMP := null;
v_luogo_nascita_quietanziante VARCHAR := null;
v_stato_nascita_quietanziante VARCHAR := null;
v_bic VARCHAR := null;
v_contocorrente VARCHAR := null;
v_intestazione_contocorrente VARCHAR := null;
v_iban VARCHAR := null;
v_mod_pag_id INTEGER := null;
v_note_mod_pag VARCHAR := null;
v_data_scadenza_mod_pag TIMESTAMP := null;
v_cod_tipo_accredito VARCHAR := null;
v_desc_tipo_accredito VARCHAR := null;
-- Variabili per i soggetti legati alla modalita' pagamento
v_cod_sogg_mod_pag VARCHAR := null;
v_tipo_sogg_mod_pag VARCHAR := null;
v_stato_sogg_mod_pag VARCHAR := null;
v_rag_sociale_sogg_mod_pag VARCHAR := null;
v_p_iva_sogg_mod_pag VARCHAR := null;
v_cf_sogg_mod_pag VARCHAR := null;
v_cf_estero_sogg_mod_pag VARCHAR := null;
v_nome_sogg_mod_pag VARCHAR := null;
v_cognome_sogg_mod_pag VARCHAR := null;
-- Variabili utili per il caricamento
v_doc_id INTEGER := null;
v_subdoc_id INTEGER := null;
v_attoal_id INTEGER := null;
v_attoamm_id INTEGER := null;
v_soggetto_id INTEGER := null;
v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_flag_attributo VARCHAR := null;
v_soggetto_id_principale INTEGER := null;
v_movgest_ts_tipo_code VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_soggetto_id_modpag_nocess INTEGER := null;
v_soggetto_id_modpag_cess INTEGER := null;
v_soggetto_id_modpag INTEGER := null;
v_soggrelmpag_id INTEGER := null;
v_pcccod_id INTEGER := null;
v_pccuff_id INTEGER := null;
v_attoamm_tipo_id INTEGER := null;
v_comm_tipo_id INTEGER := null;
--nuova sezione coge 26-09-2016
v_registro_repertorio VARCHAR := null;
v_anno_repertorio VARCHAR := null;
v_num_repertorio VARCHAR := null;
v_data_repertorio VARCHAR := null;
v_arrotondamento VARCHAR := null;
v_data_ricezione_portale VARCHAR := null;
rec_doc_attr record;

v_user_table varchar;
params varchar;
fnc_eseguita integer;


-- 22.05.2018 Sofia siac-6124
v_data_ins_atto_allegato TIMESTAMP := null;
v_data_completa_atto_allegato TIMESTAMP := null;
v_data_convalida_atto_allegato TIMESTAMP := null;
v_data_sosp_atto_allegato TIMESTAMP := null;
v_causale_sosp_atto_allegato varchar := null;
v_data_riattiva_atto_allegato TIMESTAMP := null;

BEGIN


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_entrata' ;

if fnc_eseguita> 0 then

return;

else

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


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
'fnc_siac_dwh_documento_entrata',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_documento_entrata
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

-- Ciclo per estrarre doc_id (documenti)
FOR rec_doc_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       td.doc_anno, td.doc_numero, td.doc_desc, td.doc_importo, td.doc_beneficiariomult,
       td.doc_data_emissione, td.doc_data_scadenza, dc.codbollo_code, dc.codbollo_desc,
       td.doc_collegato_cec,
       dds.doc_stato_code, dds.doc_stato_desc, ddg.doc_gruppo_tipo_code, ddg.doc_gruppo_tipo_desc,
       ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc, ddt.doc_tipo_code, ddt.doc_tipo_desc,
       ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
       ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero, tpf.nome, tpf.cognome,
       td.doc_id, td.pcccod_id, td.pccuff_id, ts.soggetto_id,
       td.doc_contabilizza_genpcc
FROM siac.siac_t_doc td
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = td.ente_proprietario_id
                                             AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
                                             AND tep.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_tipo ddt ON ddt.doc_tipo_id = td.doc_tipo_id
                                    AND p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
                                    AND ddt.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_fam_tipo ddft ON ddft.doc_fam_tipo_id = ddt.doc_fam_tipo_id
                                         AND p_data BETWEEN ddft.validita_inizio AND COALESCE(ddft.validita_fine, p_data)
                                         AND ddft.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_gruppo ddg ON ddg.doc_gruppo_tipo_id = ddt.doc_gruppo_tipo_id
                                     AND p_data BETWEEN ddg.validita_inizio AND COALESCE(ddg.validita_fine, p_data)
                                     AND ddg.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_codicebollo dc ON dc.codbollo_id = td.codbollo_id
LEFT JOIN siac.siac_r_doc_stato rds ON rds.doc_id = td.doc_id
                                    AND p_data BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine, p_data)
                                    AND rds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_stato dds ON dds.doc_stato_id = rds.doc_stato_id
                                    AND p_data BETWEEN dds.validita_inizio AND COALESCE(dds.validita_fine, p_data)
                                    AND dds.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_doc_sog srds ON srds.doc_id = td.doc_id
                                   AND p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
                                   AND srds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = srds.soggetto_id
                                  AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
                                  AND ts.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                        AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                        AND rst.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                        AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                        AND dst.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                         AND rss.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                         AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                         AND dss.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                            AND tpg.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                         AND tpf.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND ddft.doc_fam_tipo_code in ('E','IE')
AND p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
AND td.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id  := null;
v_ente_denominazione  := null;
v_anno_doc  := null;
v_num_doc  := null;
v_desc_doc  := null;
v_importo_doc  := null;
v_beneficiario_multiplo_doc  := null;
v_data_emissione_doc  := null;
v_data_scadenza_doc  := null;
v_codice_bollo_doc  := null;
v_desc_codice_bollo_doc  := null;
v_collegato_cec_doc  := null;
v_cod_pcc_doc  := null;
v_desc_pcc_doc  := null;
v_cod_ufficio_doc  := null;
v_desc_ufficio_doc  := null;
v_cod_stato_doc  := null;
v_desc_stato_doc  := null;
v_cod_gruppo_doc  := null;
v_desc_gruppo_doc  := null;
v_cod_famiglia_doc  := null;
v_desc_famiglia_doc  := null;
v_cod_tipo_doc  := null;
v_desc_tipo_doc  := null;
v_sogg_id_doc  := null;
v_cod_sogg_doc  := null;
v_tipo_sogg_doc  := null;
v_stato_sogg_doc  := null;
v_rag_sociale_sogg_doc  := null;
v_p_iva_sogg_doc  := null;
v_cf_sogg_doc  := null;
v_cf_estero_sogg_doc  := null;
v_nome_sogg_doc  := null;
v_cognome_sogg_doc  := null;
v_bil_anno_ord := null;
v_anno_ord := null;
v_num_ord := null;
v_num_subord  := null;


v_doc_id  := null;
v_pcccod_id  := null;
v_pccuff_id  := null;

--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc := null;

v_ente_proprietario_id := rec_doc_id.ente_proprietario_id;
v_ente_denominazione := rec_doc_id.ente_denominazione;
v_anno_doc := rec_doc_id.doc_anno;
v_num_doc := rec_doc_id.doc_numero;
v_desc_doc := rec_doc_id.doc_desc;
v_importo_doc := rec_doc_id.doc_importo;
IF rec_doc_id.doc_beneficiariomult = 'FALSE' THEN
   v_beneficiario_multiplo_doc := 'F';
ELSE
   v_beneficiario_multiplo_doc := 'T';
END IF;
v_data_emissione_doc := rec_doc_id.doc_data_emissione;
v_data_scadenza_doc := rec_doc_id.doc_data_scadenza;
v_codice_bollo_doc := rec_doc_id.codbollo_code;
v_desc_codice_bollo_doc := rec_doc_id.codbollo_desc;
v_collegato_cec_doc := rec_doc_id.doc_collegato_cec;
v_cod_stato_doc := rec_doc_id.doc_stato_code;
v_desc_stato_doc := rec_doc_id.doc_stato_desc;
v_cod_gruppo_doc := rec_doc_id.doc_gruppo_tipo_code;
v_desc_gruppo_doc := rec_doc_id.doc_gruppo_tipo_desc;
v_cod_famiglia_doc := rec_doc_id.doc_fam_tipo_code;
v_desc_famiglia_doc := rec_doc_id.doc_fam_tipo_desc;
v_cod_tipo_doc := rec_doc_id.doc_tipo_code;
v_desc_tipo_doc := rec_doc_id.doc_tipo_desc;
v_sogg_id_doc := rec_doc_id.soggetto_id;
v_cod_sogg_doc := rec_doc_id.soggetto_code;
v_tipo_sogg_doc := rec_doc_id.soggetto_tipo_desc;
v_stato_sogg_doc := rec_doc_id.soggetto_stato_desc;
v_rag_sociale_sogg_doc := rec_doc_id.ragione_sociale;
v_p_iva_sogg_doc := rec_doc_id.partita_iva;
v_cf_sogg_doc := rec_doc_id.codice_fiscale;
v_cf_estero_sogg_doc := rec_doc_id.codice_fiscale_estero;
v_nome_sogg_doc := rec_doc_id.nome;
v_cognome_sogg_doc := rec_doc_id.cognome;

v_doc_id  := rec_doc_id.doc_id;
v_pcccod_id := rec_doc_id.pcccod_id;
v_pccuff_id := rec_doc_id.pccuff_id;

--nuova sezione coge 26-09-2016
IF rec_doc_id.doc_contabilizza_genpcc = 'FALSE' THEN
   v_doc_contabilizza_genpcc := 'F';
ELSE
   v_doc_contabilizza_genpcc := 'T';
END IF;

SELECT dpc.pcccod_code, dpc.pcccod_desc
INTO   v_cod_pcc_doc, v_desc_pcc_doc
FROM   siac.siac_d_pcc_codice dpc
WHERE  dpc.pcccod_id = v_pcccod_id
AND p_data BETWEEN dpc.validita_inizio AND COALESCE(dpc.validita_fine, p_data)
AND dpc.data_cancellazione IS NULL;

SELECT dpu.pccuff_code, dpu.pccuff_desc
INTO   v_cod_ufficio_doc, v_desc_ufficio_doc
FROM   siac.siac_d_pcc_ufficio dpu
WHERE  dpu.pccuff_id = v_pccuff_id
AND p_data BETWEEN dpu.validita_inizio AND COALESCE(dpu.validita_fine, p_data)
AND dpu.data_cancellazione IS NULL;

-- Ciclo per estrarre subdoc_id (subdocumenti)
FOR rec_subdoc_id IN
SELECT ts.subdoc_numero, ts.subdoc_desc, ts.subdoc_importo, ts.subdoc_nreg_iva, ts.subdoc_data_scadenza,
       ts.subdoc_convalida_manuale, ts.subdoc_importo_da_dedurre, ts.subdoc_splitreverse_importo,
       ts.subdoc_pagato_cec, ts.subdoc_data_pagamento_cec,
       taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daas.attoamm_stato_code, daas.attoamm_stato_desc,
       staa.attoal_causale, staa.attoal_altriallegati, staa.attoal_dati_sensibili,
       staa.attoal_data_scadenza, staa.attoal_note, staa.attoal_annotazioni, staa.attoal_pratica,
       staa.attoal_responsabile_amm, staa.attoal_responsabile_con, staa.attoal_titolario_anno,
       staa.attoal_titolario_numero, staa.attoal_versione_invio_firma,
       sdaas.attoal_stato_code, sdaas.attoal_stato_desc,
       ted.eldoc_anno, ted.eldoc_numero, ted.eldoc_data_trasmissione, ted.eldoc_tot_quoteentrate,
       ted.eldoc_tot_quotespese, ted.eldoc_tot_dapagare, ted.eldoc_tot_daincassare,
       deds.eldoc_stato_code, deds.eldoc_stato_desc, dnt.notetes_desc, dd.dist_code, dd.dist_desc, dc.contotes_desc,
       ts.subdoc_id, staa.attoal_id, taa.attoamm_id, taa.attoamm_tipo_id, ts.comm_tipo_id,
       staa.data_creazione data_ins_atto_allegato -- 22.05.2018 Sofia siac-6124
FROM siac.siac_t_subdoc ts
LEFT JOIN siac.siac_r_subdoc_atto_amm rsaa ON rsaa.subdoc_id = ts.subdoc_id
                                           AND p_data BETWEEN rsaa.validita_inizio AND COALESCE(rsaa.validita_fine, p_data)
                                           AND rsaa.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_amm taa ON taa.attoamm_id = rsaa.attoamm_id
                                   AND p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
                                   AND taa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_amm_stato raas ON raas.attoamm_id = taa.attoamm_id
                                          AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
                                          AND raas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_amm_stato daas ON daas.attoamm_stato_id = raas.attoamm_stato_id
                                          AND p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
                                          AND daas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_subdoc reds ON reds.subdoc_id = ts.subdoc_id
                                             AND p_data BETWEEN reds.validita_inizio AND COALESCE(reds.validita_fine, p_data)
                                             AND reds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_elenco_doc ted ON ted.eldoc_id = reds.eldoc_id
                                     AND p_data BETWEEN ted.validita_inizio AND COALESCE(ted.validita_fine, p_data)
                                     AND ted.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_elenco_doc raaed ON raaed.eldoc_id = ted.eldoc_id
                                                     AND p_data BETWEEN raaed.validita_inizio AND COALESCE(raaed.validita_fine, p_data)
                                                     AND raaed.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_allegato staa ON staa.attoal_id = raaed.attoal_id
                                         AND p_data BETWEEN staa.validita_inizio AND COALESCE(staa.validita_fine, p_data)
                                         AND staa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_stato sraas ON sraas.attoal_id = staa.attoal_id
                                                AND p_data BETWEEN sraas.validita_inizio AND COALESCE(sraas.validita_fine, p_data)
                                                AND sraas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_allegato_stato sdaas ON sdaas.attoal_stato_id = sraas.attoal_stato_id
                                                AND p_data BETWEEN sdaas.validita_inizio AND COALESCE(sdaas.validita_fine, p_data)
                                                AND sdaas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_stato  sreds ON sreds.eldoc_id = ted.eldoc_id
                                              AND p_data BETWEEN sreds.validita_inizio AND COALESCE(sreds.validita_fine, p_data)
                                              AND sreds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_elenco_doc_stato  deds ON deds.eldoc_stato_id = sreds.eldoc_stato_id
                                             AND p_data BETWEEN deds.validita_inizio AND COALESCE(deds.validita_fine, p_data)
                                             AND deds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_note_tesoriere  dnt ON dnt.notetes_id = ts.notetes_id
LEFT JOIN siac.siac_d_distinta  dd ON dd.dist_id = ts.dist_id
LEFT JOIN siac.siac_d_contotesoreria dc ON dc.contotes_id = ts.contotes_id
WHERE ts.doc_id = v_doc_id
AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND ts.data_cancellazione IS NULL

	LOOP

    v_num_subdoc  := null;
    v_desc_subdoc  := null;
    v_importo_subdoc  := null;
    v_num_reg_iva_subdoc  := null;
    v_data_scadenza_subdoc  := null;
    v_convalida_manuale_subdoc  := null;
    v_importo_da_dedurre_subdoc  := null;
    v_splitreverse_importo_subdoc  := null;
    v_pagato_cec_subdoc  := null;
    v_data_pagamento_cec_subdoc  := null;
    v_anno_atto_amministrativo  := null;
    v_num_atto_amministrativo  := null;
    v_oggetto_atto_amministrativo  := null;
    v_note_atto_amministrativo  := null;
    v_cod_tipo_atto_amministrativo  := null;
    v_desc_tipo_atto_amministrativo  := null;
    v_cod_stato_atto_amministrativo  := null;
    v_desc_stato_atto_amministrativo  := null;
    v_causale_atto_allegato  := null;
    v_altri_allegati_atto_allegato  := null;
    v_dati_sensibili_atto_allegato  := null;
    v_data_scadenza_atto_allegato  := null;
    v_note_atto_allegato  := null;
    v_annotazioni_atto_allegato  := null;
    v_pratica_atto_allegato  := null;
    v_resp_amm_atto_allegato  := null;
    v_resp_contabile_atto_allegato  := null;
    v_anno_titolario_atto_allegato  := null;
    v_num_titolario_atto_allegato  := null;
    v_vers_invio_firma_atto_allegato  := null;
    v_cod_stato_atto_allegato  := null;
    v_desc_stato_atto_allegato  := null;
    v_anno_elenco_doc  := null;
    v_num_elenco_doc  := null;
    v_data_trasmissione_elenco_doc  := null;
    v_tot_quote_entrate_elenco_doc  := null;
    v_tot_quote_spese_elenco_doc  := null;
    v_tot_da_pagare_elenco_doc  := null;
    v_tot_da_incassare_elenco_doc  := null;
    v_cod_stato_elenco_doc  := null;
    v_desc_stato_elenco_doc  := null;
    v_note_tesoriere_subdoc  := null;
    v_cod_distinta_subdoc  := null;
    v_desc_distinta_subdoc  := null;
    v_tipo_commissione_subdoc  := null;
    v_conto_tesoreria_subdoc  := null;

    v_sogg_id_atto_allegato  := null;
    v_cod_sogg_atto_allegato  := null;
    v_tipo_sogg_atto_allegato  := null;
    v_stato_sogg_atto_allegato  := null;
    v_rag_sociale_sogg_atto_allegato  := null;
    v_p_iva_sogg_atto_allegato  := null;
    v_cf_sogg_atto_allegato  := null;
    v_cf_estero_sogg_atto_allegato  := null;
    v_nome_sogg_atto_allegato  := null;
    v_cognome_sogg_atto_allegato  := null;

    v_cod_cdr_atto_amministrativo  := null;
    v_desc_cdr_atto_amministrativo  := null;
    v_cod_cdc_atto_amministrativo  := null;
    v_desc_cdc_atto_amministrativo  := null;
    v_cod_tipo_avviso  := null;
    v_desc_tipo_avviso  := null;

    v_cod_sogg_subdoc  := null;
    v_tipo_sogg_subdoc  := null;
    v_stato_sogg_subdoc  := null;
    v_rag_sociale_sogg_subdoc  := null;
    v_p_iva_sogg_subdoc  := null;
    v_cf_sogg_subdoc  := null;
    v_cf_estero_sogg_subdoc  := null;
    v_nome_sogg_subdoc  := null;
    v_cognome_sogg_subdoc  := null;

    v_sede_secondaria_subdoc := null;

    v_bil_anno := null;
    v_anno_accertamento := null;
    v_num_accertamento := null;
    v_cod_accertamento  := null;
    v_desc_accertamento  := null;
    v_cod_subaccertamento  := null;
    v_desc_subaccertamento  := null;

    v_quietanziante := null;
    v_data_nascita_quietanziante := null;
    v_luogo_nascita_quietanziante := null;
    v_stato_nascita_quietanziante := null;
    v_bic := null;
    v_contocorrente := null;
    v_intestazione_contocorrente := null;
    v_iban := null;
    v_mod_pag_id := null;
    v_note_mod_pag := null;
    v_data_scadenza_mod_pag := null;
    v_cod_tipo_accredito := null;
    v_desc_tipo_accredito := null;

    v_cod_sogg_mod_pag := null;
    v_tipo_sogg_mod_pag := null;
    v_stato_sogg_mod_pag := null;
    v_rag_sociale_sogg_mod_pag := null;
    v_p_iva_sogg_mod_pag := null;
    v_cf_sogg_mod_pag := null;
    v_cf_estero_sogg_mod_pag := null;
    v_nome_sogg_mod_pag := null;
    v_cognome_sogg_mod_pag := null;

    v_attoal_id  := null;
    v_subdoc_id  := null;
    v_attoamm_id  := null;
    v_classif_tipo_id := null;
    v_soggetto_id := null;
    v_soggetto_id_principale := null;
    v_movgest_ts_tipo_code := null;
    v_movgest_ts_code := null;
    v_soggetto_id_modpag_nocess := null;
    v_soggetto_id_modpag_cess := null;
    v_soggetto_id_modpag := null;
    v_soggrelmpag_id := null;
    v_attoamm_tipo_id := null;
    v_comm_tipo_id := null;


	-- 22.05.2018 Sofia siac-6124
    v_data_ins_atto_allegato:= null;
    v_data_completa_atto_allegato:= null;
    v_data_convalida_atto_allegato:= null;
    v_data_sosp_atto_allegato:=null;
    v_causale_sosp_atto_allegato:= null;
    v_data_riattiva_atto_allegato:= null;

    v_num_subdoc  := rec_subdoc_id.subdoc_numero;
    v_desc_subdoc  := rec_subdoc_id.subdoc_desc;
    v_importo_subdoc  := rec_subdoc_id.subdoc_importo;
    v_num_reg_iva_subdoc  := rec_subdoc_id.subdoc_nreg_iva;
    v_data_scadenza_subdoc  := rec_subdoc_id.subdoc_data_scadenza;
    v_convalida_manuale_subdoc  := rec_subdoc_id.subdoc_convalida_manuale;
    v_importo_da_dedurre_subdoc  := rec_subdoc_id.subdoc_importo_da_dedurre;
    v_splitreverse_importo_subdoc  := rec_subdoc_id.subdoc_splitreverse_importo;
    v_pagato_cec_subdoc  := rec_subdoc_id.subdoc_pagato_cec;
    v_data_pagamento_cec_subdoc  := rec_subdoc_id.subdoc_data_pagamento_cec;
    v_anno_atto_amministrativo  := rec_subdoc_id.attoamm_anno;
    v_num_atto_amministrativo  := rec_subdoc_id.attoamm_numero;
    v_oggetto_atto_amministrativo  := rec_subdoc_id.attoamm_oggetto;
    v_note_atto_amministrativo  := rec_subdoc_id.attoamm_note;
    v_cod_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_code;
    v_desc_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_desc;
    v_causale_atto_allegato  := rec_subdoc_id.attoal_causale;
    v_altri_allegati_atto_allegato  := rec_subdoc_id.attoal_altriallegati;
    v_dati_sensibili_atto_allegato  := rec_subdoc_id.attoal_dati_sensibili;
    v_data_scadenza_atto_allegato  := rec_subdoc_id.attoal_data_scadenza;
    v_note_atto_allegato  := rec_subdoc_id.attoal_note;
    v_annotazioni_atto_allegato  := rec_subdoc_id.attoal_annotazioni;
    v_pratica_atto_allegato  := rec_subdoc_id.attoal_pratica;
    v_resp_amm_atto_allegato  := rec_subdoc_id.attoal_responsabile_amm;
    v_resp_contabile_atto_allegato  := rec_subdoc_id.attoal_responsabile_con;
    v_anno_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_anno;
    v_num_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_numero;
    v_vers_invio_firma_atto_allegato  := rec_subdoc_id.attoal_versione_invio_firma;
    v_cod_stato_atto_allegato  := rec_subdoc_id.attoal_stato_code;
    v_desc_stato_atto_allegato  := rec_subdoc_id.attoal_stato_desc;
    v_anno_elenco_doc  := rec_subdoc_id.eldoc_anno;
    v_num_elenco_doc  := rec_subdoc_id.eldoc_numero;
    v_data_trasmissione_elenco_doc  := rec_subdoc_id.eldoc_data_trasmissione;
    v_tot_quote_entrate_elenco_doc  := rec_subdoc_id.eldoc_tot_quoteentrate;
    v_tot_quote_spese_elenco_doc  := rec_subdoc_id.eldoc_tot_quotespese;
    v_tot_da_pagare_elenco_doc  := rec_subdoc_id.eldoc_tot_dapagare;
    v_tot_da_incassare_elenco_doc  := rec_subdoc_id.eldoc_tot_daincassare;
    v_cod_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_code;
    v_desc_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_desc;
    v_note_tesoriere_subdoc  := rec_subdoc_id.notetes_desc;
    v_cod_distinta_subdoc  := rec_subdoc_id.dist_code;
    v_desc_distinta_subdoc  := rec_subdoc_id.dist_desc;
    v_conto_tesoreria_subdoc  := rec_subdoc_id.contotes_desc;

    v_attoal_id  := rec_subdoc_id.attoal_id;
    v_subdoc_id  := rec_subdoc_id.subdoc_id;
    v_attoamm_id  := rec_subdoc_id.attoamm_id;
    v_attoamm_tipo_id  := rec_subdoc_id.attoamm_tipo_id;
    v_comm_tipo_id  := rec_subdoc_id.comm_tipo_id;

    -- 22.05.2018 Sofia siac-6124
    v_data_ins_atto_allegato:=rec_subdoc_id.data_ins_atto_allegato;

    -- Sezione per estrarre il tipo di atto amministrativo
    SELECT daat.attoamm_tipo_code, daat.attoamm_tipo_desc
    INTO   v_cod_tipo_atto_amministrativo, v_desc_tipo_atto_amministrativo
    FROM  siac.siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = v_attoamm_tipo_id
    AND p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data)
    AND daat.data_cancellazione IS NULL;
    -- Sezione per estrarre il tipo commissione
    SELECT dct.comm_tipo_desc
    INTO  v_tipo_commissione_subdoc
    FROM siac.siac_d_commissione_tipo dct
    WHERE dct.comm_tipo_id = v_comm_tipo_id
    AND p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)
    AND dct.data_cancellazione IS NULL;

   -- esito:= '    Inizio step per i soggetti legati all''atto allegato @@@@@@@@@@@@@@@@@@ - '||clock_timestamp();
   -- return next;
    --  Sezione per i soggetti legati all'atto allegato
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, ts.soggetto_id,
           raas.attoal_sog_data_sosp, raas.attoal_sog_causale_sosp, raas.attoal_sog_data_riatt  -- 22.05.2018 Sofia siac-6124
    INTO   v_cod_sogg_atto_allegato, v_tipo_sogg_atto_allegato, v_stato_sogg_atto_allegato, v_rag_sociale_sogg_atto_allegato,
           v_p_iva_sogg_atto_allegato, v_cf_sogg_atto_allegato, v_cf_estero_sogg_atto_allegato,
           v_nome_sogg_atto_allegato, v_cognome_sogg_atto_allegato, v_sogg_id_atto_allegato,
           v_data_sosp_atto_allegato,v_causale_sosp_atto_allegato, v_data_riattiva_atto_allegato -- 22.05.2018 Sofia siac-6124
    FROM siac.siac_r_atto_allegato_sog raas
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = raas.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                             AND rss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE raas.attoal_id = v_attoal_id
    AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
    AND raas.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

   -- esito:= '    Fine step per i soggetti legati all''atto allegato v_data_sosp_atto_allegato='||coalesce(to_char(v_data_sosp_atto_allegato,'dd/mm/yyyy'),'****' )||' - '||clock_timestamp();
   -- return next;

    esito:= '    Inizio step data completamento, convalida atto_allegato - '||clock_timestamp();
    return next;
	-- 22.05.2018 Sofia siac-6124
    v_data_completa_atto_allegato:=fnc_siac_attoal_getDataStato(v_attoal_id,'C');
    v_data_convalida_atto_allegato:=fnc_siac_attoal_getDataStato(v_attoal_id,'CV');
    esito:= '    Fine step data completamento, convalida atto_allegato - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati ai subdocumenti
    esito:= '    Inizio step classificatori per subdocumenti - '||clock_timestamp();
    return next;
    FOR rec_classif_id IN
    SELECT tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_subdoc_class rsc, siac.siac_t_class tc
    WHERE tc.classif_id = rsc.classif_id
    AND   rsc.subdoc_id = v_subdoc_id
    AND   rsc.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN rsc.validita_inizio AND COALESCE(rsc.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
      v_classif_code := rec_classif_id.classif_code;
      v_classif_desc := rec_classif_id.classif_desc;

      v_classif_tipo_code := null;

      SELECT dct.classif_tipo_code
      INTO   v_classif_tipo_code
      FROM   siac.siac_d_class_tipo dct
      WHERE  dct.classif_tipo_id = v_classif_tipo_id
      AND    dct.data_cancellazione IS NULL
      AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'TIPO_AVVISO' THEN
         v_cod_tipo_avviso  := v_classif_code;
         v_desc_tipo_avviso :=  v_classif_desc;
      END IF;

    END LOOP;
    esito:= '    Fine step classificatori per subdocumenti - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati agli atti amministrativi
    esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;
    FOR rec_classif_id_attr IN
    SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_atto_amm_class raac, siac.siac_t_class tc
    WHERE tc.classif_id = raac.classif_id
    AND   raac.attoamm_id = v_attoamm_id
    AND   raac.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_conta_ciclo_classif :=0;
      v_classif_id_padre := null;

      -- Loop per RISALIRE la gerarchia di un dato classificatore
      LOOP

          v_classif_code := null;
          v_classif_desc := null;
          v_classif_id_part := null;
          v_classif_tipo_code := null;

          IF v_conta_ciclo_classif = 0 THEN
             v_classif_id_part := rec_classif_id_attr.classif_id;
          ELSE
             v_classif_id_part := v_classif_id_padre;
          END IF;

          SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code
          INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code
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

          IF v_classif_tipo_code = 'CDR' THEN
             v_cod_cdr_atto_amministrativo := v_classif_code;
             v_desc_cdr_atto_amministrativo := v_classif_desc;
          ELSIF v_classif_tipo_code = 'CDC' THEN
             v_cod_cdc_atto_amministrativo := v_classif_code;
             v_desc_cdc_atto_amministrativo := v_classif_desc;
          END IF;

          v_conta_ciclo_classif := v_conta_ciclo_classif +1;
          EXIT WHEN v_classif_id_padre IS NULL;

      END LOOP;
    END LOOP;
    esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;

    -- Sezione pe gli attributi
    v_rilevante_iva := null;
    v_ordinativo_singolo := null;
    v_ordinativo_manuale := null;
    v_esproprio := null;
    v_note := null;
    v_avviso := null;

    v_flag_attributo := null;

--nuova sezione coge 26-09-2016
    v_registro_repertorio := null;
    v_anno_repertorio := null;
    v_num_repertorio := null;
    v_data_repertorio := null;

FOR rec_doc_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_doc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat, siac_t_subdoc z
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    and z.doc_id=rsa.doc_id
    and z.subdoc_id = v_subdoc_id
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
    AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
    AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
    and ta.attr_code in ( 'registro_repertorio','anno_repertorio','num_repertorio',
    'data_repertorio' ,'dataRicezionePortale','arrotondamento')

LOOP

      IF rec_doc_attr.attr_tipo_code = 'X' THEN
         v_flag_attributo := rec_doc_attr.testo::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'N' THEN
         v_flag_attributo := rec_doc_attr.numerico::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'P' THEN
         v_flag_attributo := rec_doc_attr.percentuale::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'B' THEN
         v_flag_attributo := rec_doc_attr.true_false::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'T' THEN
         v_flag_attributo := rec_doc_attr.tabella_id::varchar;
      END IF;

      --nuova sezione coge 26-09-2016
      IF rec_doc_attr.attr_code = 'registro_repertorio' THEN
         v_registro_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'anno_repertorio' THEN
         v_anno_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'num_repertorio' THEN
         v_num_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'data_repertorio' THEN
         v_data_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'dataRicezionePortale' THEN
         v_data_ricezione_portale := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'arrotondamento' THEN
         v_arrotondamento := v_flag_attributo;
      END IF;

    END LOOP;


    FOR rec_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_subdoc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.subdoc_id = v_subdoc_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
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

      IF rec_attr.attr_code = 'flagRilevanteIVA' THEN
         v_rilevante_iva := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoManuale' THEN
         v_ordinativo_manuale := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoSingolo' THEN
         v_ordinativo_singolo := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagEsproprio' THEN
         v_esproprio := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'Note' THEN
         v_note := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagAvviso' THEN
         v_avviso := v_flag_attributo;
      END IF;

    END LOOP;

    --  Sezione per i soggetti legati al subdoc
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, rss.soggetto_id
    INTO v_cod_sogg_subdoc, v_tipo_sogg_subdoc, v_stato_sogg_subdoc, v_rag_sociale_sogg_subdoc,
         v_p_iva_sogg_subdoc, v_cf_sogg_subdoc, v_cf_estero_sogg_subdoc,
         v_nome_sogg_subdoc, v_cognome_sogg_subdoc, v_soggetto_id
    FROM siac.siac_r_subdoc_sog rss
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = rss.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE rss.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
    AND rss.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    -- Sezione per valorizzare la sede secondaria
    SELECT rsr.soggetto_id_da
    INTO v_soggetto_id_principale
    FROM siac.siac_r_soggetto_relaz rsr, siac.siac_d_relaz_tipo drt
    WHERE rsr.relaz_tipo_id = drt.relaz_tipo_id
    AND   drt.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   rsr.soggetto_id_a = v_soggetto_id
    AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
    AND   p_data BETWEEN drt.validita_inizio AND COALESCE(drt.validita_fine, p_data)
    AND   rsr.data_cancellazione IS NULL
    AND   drt.data_cancellazione IS NULL;

    IF  v_soggetto_id_principale IS NOT NULL THEN
        v_sede_secondaria_subdoc := 'S';
    END IF;

    -- Sezione per gli accertamenti
    SELECT tp.anno, tm.movgest_anno, tm.movgest_numero, dmtt.movgest_ts_tipo_code,
           tmt.movgest_ts_code, tmt.movgest_ts_desc, tm.movgest_desc
    INTO v_bil_anno, v_anno_accertamento, v_num_accertamento, v_movgest_ts_tipo_code,
         v_movgest_ts_code, v_desc_subaccertamento, v_desc_accertamento
    FROM siac.siac_r_subdoc_movgest_ts rsmt
    INNER JOIN siac.siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rsmt.movgest_ts_id
    INNER JOIN siac.siac_t_movgest tm ON tm.movgest_id = tmt.movgest_id
    LEFT JOIN siac.siac_t_bil tb ON tb.bil_id = tm.bil_id
                                 AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
                                 AND tb.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_periodo tp ON  tp.periodo_id = tb.periodo_id
                                     AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
                                     AND tp.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_movgest_tipo dmt ON dmt.movgest_tipo_id = tm.movgest_tipo_id
    INNER JOIN siac.siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
    WHERE rsmt.subdoc_id = v_subdoc_id
    AND dmt.movgest_tipo_code = 'A'
    AND p_data BETWEEN rsmt.validita_inizio AND COALESCE(rsmt.validita_fine, p_data)
    AND rsmt.data_cancellazione IS NULL
    AND p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
    AND tmt.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL
    AND p_data BETWEEN dmt.validita_inizio AND COALESCE(dmt.validita_fine, p_data)
    AND dmt.data_cancellazione IS NULL
    AND p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
    AND dmtt.data_cancellazione IS NULL;

    IF v_movgest_ts_tipo_code = 'T' THEN
       v_cod_accertamento := v_movgest_ts_code;
       v_desc_subaccertamento := NULL;
    ELSIF v_movgest_ts_tipo_code = 'S' THEN
          v_cod_subaccertamento := v_movgest_ts_code;
          v_desc_accertamento := NULL;
    END IF;

    -- Sezione per la modalita' di pagamento
    SELECT tm.quietanziante, tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo, tm.quietanziante_nascita_stato,
           tm.bic, tm.contocorrente, tm.contocorrente_intestazione, tm.iban, tm.note, tm.data_scadenza,
           dat.accredito_tipo_code, dat.accredito_tipo_desc, tm.soggetto_id, rsm.soggrelmpag_id, tm.modpag_id
    INTO   v_quietanziante, v_data_nascita_quietanziante, v_luogo_nascita_quietanziante, v_stato_nascita_quietanziante,
           v_bic, v_contocorrente, v_intestazione_contocorrente, v_iban, v_note_mod_pag, v_data_scadenza_mod_pag,
           v_cod_tipo_accredito, v_desc_tipo_accredito, v_soggetto_id_modpag_nocess, v_soggrelmpag_id, v_mod_pag_id
    FROM siac.siac_r_subdoc_modpag rsm
    INNER JOIN siac.siac_t_modpag tm ON tm.modpag_id = rsm.modpag_id
    LEFT JOIN siac.siac_d_accredito_tipo dat ON dat.accredito_tipo_id = tm.accredito_tipo_id
                                             AND p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
                                             AND dat.data_cancellazione IS NULL
    WHERE rsm.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
    AND rsm.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL;

    IF v_soggrelmpag_id IS NULL THEN
       v_soggetto_id_modpag := v_soggetto_id_modpag_nocess;
    ELSE
       SELECT rsr.soggetto_id_a
       INTO  v_soggetto_id_modpag_cess
       FROM  siac.siac_r_soggrel_modpag rsm, siac.siac_r_soggetto_relaz rsr
       WHERE rsm.soggrelmpag_id = v_soggrelmpag_id
       AND   rsm.soggetto_relaz_id = rsr.soggetto_relaz_id
       AND   p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
       AND   rsm.data_cancellazione IS NULL
       AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
       AND   rsr.data_cancellazione IS NULL;

       v_soggetto_id_modpag := v_soggetto_id_modpag_cess;
    END IF;

    --  Sezione per i soggetti legati alla modalita' pagamento
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome
    INTO   v_cod_sogg_mod_pag, v_tipo_sogg_mod_pag, v_stato_sogg_mod_pag, v_rag_sociale_sogg_mod_pag,
           v_p_iva_sogg_mod_pag, v_cf_sogg_mod_pag, v_cf_estero_sogg_mod_pag,
           v_nome_sogg_mod_pag, v_cognome_sogg_mod_pag
    FROM siac.siac_t_soggetto ts
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE ts.soggetto_id = v_soggetto_id_modpag
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    SELECT sto.ord_anno, sto.ord_numero, tt.ord_ts_code, tp.anno
    INTO  v_anno_ord, v_num_ord, v_num_subord, v_bil_anno_ord
    FROM  siac_r_subdoc_ordinativo_ts rsot, siac_t_ordinativo_ts tt, siac_t_ordinativo sto,
          siac_r_ordinativo_stato ros, siac_d_ordinativo_stato dos,
          siac.siac_t_bil tb, siac.siac_t_periodo tp
    WHERE tt.ord_ts_id = rsot.ord_ts_id
    AND   sto.ord_id = tt.ord_id
    AND   ros.ord_id = sto.ord_id
    AND   ros.ord_stato_id = dos.ord_stato_id
    AND   sto.bil_id = tb.bil_id
    AND   tp.periodo_id = tb.periodo_id
    AND   rsot.subdoc_id = v_subdoc_id
    AND   dos.ord_stato_code <> 'A'
    AND   rsot.data_cancellazione IS NULL
    AND   tt.data_cancellazione IS NULL
    AND   sto.data_cancellazione IS NULL
    AND   ros.data_cancellazione IS NULL
    AND   dos.data_cancellazione IS NULL
    AND   tb.data_cancellazione IS NULL
    AND   tp.data_cancellazione IS NULL
    AND   p_data between rsot.validita_inizio and COALESCE(rsot.validita_fine,p_data)
    AND   p_data between tt.validita_inizio and COALESCE(tt.validita_fine,p_data)
    AND   p_data between sto.validita_inizio and COALESCE(sto.validita_fine,p_data)
    AND   p_data between ros.validita_inizio and COALESCE(ros.validita_fine,p_data)
    AND   p_data between dos.validita_inizio and COALESCE(dos.validita_fine,p_data)
    AND   p_data between tb.validita_inizio and COALESCE(tb.validita_fine,p_data)
    AND   p_data between tp.validita_inizio and COALESCE(tp.validita_fine,p_data);

      INSERT INTO siac.siac_dwh_documento_entrata
      ( ente_proprietario_id,
        ente_denominazione,
        anno_atto_amministrativo,
        num_atto_amministrativo,
        oggetto_atto_amministrativo,
        cod_tipo_atto_amministrativo,
        desc_tipo_atto_amministrativo,
        cod_cdr_atto_amministrativo,
        desc_cdr_atto_amministrativo,
        cod_cdc_atto_amministrativo,
        desc_cdc_atto_amministrativo,
        note_atto_amministrativo,
        cod_stato_atto_amministrativo,
        desc_stato_atto_amministrativo,
        causale_atto_allegato,
        altri_allegati_atto_allegato,
        dati_sensibili_atto_allegato,
        data_scadenza_atto_allegato,
        note_atto_allegato,
        annotazioni_atto_allegato,
        pratica_atto_allegato,
        resp_amm_atto_allegato,
        resp_contabile_atto_allegato,
        anno_titolario_atto_allegato,
        num_titolario_atto_allegato,
        vers_invio_firma_atto_allegato,
        cod_stato_atto_allegato,
        desc_stato_atto_allegato,
        sogg_id_atto_allegato,
        cod_sogg_atto_allegato,
        tipo_sogg_atto_allegato,
        stato_sogg_atto_allegato,
        rag_sociale_sogg_atto_allegato,
        p_iva_sogg_atto_allegato,
        cf_sogg_atto_allegato,
        cf_estero_sogg_atto_allegato,
        nome_sogg_atto_allegato,
        cognome_sogg_atto_allegato,
        anno_doc,
        num_doc,
        desc_doc,
        importo_doc,
        beneficiario_multiplo_doc,
        data_emissione_doc,
        data_scadenza_doc,
        codice_bollo_doc,
        desc_codice_bollo_doc,
        collegato_cec_doc,
        cod_pcc_doc,
        desc_pcc_doc,
        cod_ufficio_doc,
        desc_ufficio_doc,
        cod_stato_doc,
        desc_stato_doc,
        anno_elenco_doc,
        num_elenco_doc,
        data_trasmissione_elenco_doc,
        tot_quote_entrate_elenco_doc,
        tot_quote_spese_elenco_doc,
        tot_da_pagare_elenco_doc,
        tot_da_incassare_elenco_doc,
        cod_stato_elenco_doc,
        desc_stato_elenco_doc,
        cod_gruppo_doc,
        desc_gruppo_doc,
        cod_famiglia_doc,
        desc_famiglia_doc,
        cod_tipo_doc,
        desc_tipo_doc,
        sogg_id_doc,
        cod_sogg_doc,
        tipo_sogg_doc,
        stato_sogg_doc,
        rag_sociale_sogg_doc,
        p_iva_sogg_doc,
        cf_sogg_doc,
        cf_estero_sogg_doc,
        nome_sogg_doc,
        cognome_sogg_doc,
        num_subdoc,
        desc_subdoc,
        importo_subdoc,
        num_reg_iva_subdoc,
        data_scadenza_subdoc,
        convalida_manuale_subdoc,
        importo_da_dedurre_subdoc,
        splitreverse_importo_subdoc,
        pagato_cec_subdoc,
        data_pagamento_cec_subdoc,
        note_tesoriere_subdoc,
        cod_distinta_subdoc,
        desc_distinta_subdoc,
        tipo_commissione_subdoc,
        conto_tesoreria_subdoc,
        rilevante_iva,
        ordinativo_singolo,
        ordinativo_manuale,
        esproprio,
        note,
        avviso,
        cod_tipo_avviso,
        desc_tipo_avviso,
        sogg_id_subdoc,
        cod_sogg_subdoc,
        tipo_sogg_subdoc,
        stato_sogg_subdoc,
        rag_sociale_sogg_subdoc,
        p_iva_sogg_subdoc,
        cf_sogg_subdoc,
        cf_estero_sogg_subdoc,
        nome_sogg_subdoc,
        cognome_sogg_subdoc,
        sede_secondaria_subdoc,
        bil_anno,
        anno_accertamento,
        num_accertamento,
        cod_accertamento,
        desc_accertamento,
        cod_subaccertamento,
        desc_subaccertamento,
        cod_tipo_accredito,
        desc_tipo_accredito,
        mod_pag_id,
        quietanziante,
        data_nascita_quietanziante,
        luogo_nascita_quietanziante,
        stato_nascita_quietanziante,
        bic,
        contocorrente,
        intestazione_contocorrente,
        iban,
        note_mod_pag,
        data_scadenza_mod_pag,
        sogg_id_mod_pag,
        cod_sogg_mod_pag,
        tipo_sogg_mod_pag,
        stato_sogg_mod_pag,
        rag_sociale_sogg_mod_pag,
        p_iva_sogg_mod_pag,
        cf_sogg_mod_pag,
        cf_estero_sogg_mod_pag,
        nome_sogg_mod_pag,
        cognome_sogg_mod_pag,
        bil_anno_ord,
        anno_ord,
        num_ord,
        num_subord,
        --nuova sezione coge 26-09-2016
        registro_repertorio,
		anno_repertorio,
		num_repertorio,
		data_repertorio,
        data_ricezione_portale,
        arrotondamento,
		doc_contabilizza_genpcc,
        doc_id, -- SIAC-5573 ,
        -- 22.05.2018 Sofia siac-6124
        data_ins_atto_allegato,
        data_completa_atto_allegato,
        data_convalida_atto_allegato,
        data_sosp_atto_allegato,
        causale_sosp_atto_allegato,
        data_riattiva_atto_allegato
      )
      VALUES (v_ente_proprietario_id,
              v_ente_denominazione,
              v_anno_atto_amministrativo,
              v_num_atto_amministrativo,
              v_oggetto_atto_amministrativo,
              v_cod_tipo_atto_amministrativo,
              v_desc_tipo_atto_amministrativo,
              v_cod_cdr_atto_amministrativo,
              v_desc_cdr_atto_amministrativo,
              v_cod_cdc_atto_amministrativo,
              v_desc_cdc_atto_amministrativo,
              v_note_atto_amministrativo,
              v_cod_stato_atto_amministrativo,
              v_desc_stato_atto_amministrativo,
              v_causale_atto_allegato,
              v_altri_allegati_atto_allegato,
              v_dati_sensibili_atto_allegato,
              v_data_scadenza_atto_allegato,
              v_note_atto_allegato,
              v_annotazioni_atto_allegato,
              v_pratica_atto_allegato,
              v_resp_amm_atto_allegato,
              v_resp_contabile_atto_allegato,
              v_anno_titolario_atto_allegato,
              v_num_titolario_atto_allegato,
              v_vers_invio_firma_atto_allegato,
              v_cod_stato_atto_allegato,
              v_desc_stato_atto_allegato,
              v_sogg_id_atto_allegato,
              v_cod_sogg_atto_allegato,
              v_tipo_sogg_atto_allegato,
              v_stato_sogg_atto_allegato,
              v_rag_sociale_sogg_atto_allegato,
              v_p_iva_sogg_atto_allegato,
              v_cf_sogg_atto_allegato,
              v_cf_estero_sogg_atto_allegato,
              v_nome_sogg_atto_allegato,
              v_cognome_sogg_atto_allegato,
              v_anno_doc,
              v_num_doc,
              v_desc_doc,
              v_importo_doc,
              v_beneficiario_multiplo_doc,
              v_data_emissione_doc,
              v_data_scadenza_doc,
              v_codice_bollo_doc,
              v_desc_codice_bollo_doc,
              v_collegato_cec_doc,
              v_cod_pcc_doc,
              v_desc_pcc_doc,
              v_cod_ufficio_doc,
              v_desc_ufficio_doc,
              v_cod_stato_doc,
              v_desc_stato_doc,
              v_anno_elenco_doc,
              v_num_elenco_doc,
              v_data_trasmissione_elenco_doc,
              v_tot_quote_entrate_elenco_doc,
              v_tot_quote_spese_elenco_doc,
              v_tot_da_pagare_elenco_doc,
              v_tot_da_incassare_elenco_doc,
              v_cod_stato_elenco_doc,
              v_desc_stato_elenco_doc,
              v_cod_gruppo_doc,
              v_desc_gruppo_doc,
              v_cod_famiglia_doc,
              v_desc_famiglia_doc,
              v_cod_tipo_doc,
              v_desc_tipo_doc,
              v_sogg_id_doc,
              v_cod_sogg_doc,
              v_tipo_sogg_doc,
              v_stato_sogg_doc,
              v_rag_sociale_sogg_doc,
              v_p_iva_sogg_doc,
              v_cf_sogg_doc,
              v_cf_estero_sogg_doc,
              v_nome_sogg_doc,
              v_cognome_sogg_doc,
              v_num_subdoc,
              v_desc_subdoc,
              v_importo_subdoc,
              v_num_reg_iva_subdoc,
              v_data_scadenza_subdoc,
              v_convalida_manuale_subdoc,
              v_importo_da_dedurre_subdoc,
              v_splitreverse_importo_subdoc,
              v_pagato_cec_subdoc,
              v_data_pagamento_cec_subdoc,
              v_note_tesoriere_subdoc,
              v_cod_distinta_subdoc,
              v_desc_distinta_subdoc,
              v_tipo_commissione_subdoc,
              v_conto_tesoreria_subdoc,
              v_rilevante_iva,
              v_ordinativo_singolo,
              v_ordinativo_manuale,
              v_esproprio,
              v_note,
              v_avviso,
              v_cod_tipo_avviso,
              v_desc_tipo_avviso,
              v_soggetto_id,
              v_cod_sogg_subdoc,
              v_tipo_sogg_subdoc,
              v_stato_sogg_subdoc,
              v_rag_sociale_sogg_subdoc,
              v_p_iva_sogg_subdoc,
              v_cf_sogg_subdoc,
              v_cf_estero_sogg_subdoc,
              v_nome_sogg_subdoc,
              v_cognome_sogg_subdoc,
              v_sede_secondaria_subdoc,
              v_bil_anno,
              v_anno_accertamento,
              v_num_accertamento,
              v_cod_accertamento,
              v_desc_accertamento,
              v_cod_subaccertamento,
              v_desc_subaccertamento,
              v_cod_tipo_accredito,
              v_desc_tipo_accredito,
              v_mod_pag_id,
              v_quietanziante,
              v_data_nascita_quietanziante,
              v_luogo_nascita_quietanziante,
              v_stato_nascita_quietanziante,
              v_bic,
              v_contocorrente,
              v_intestazione_contocorrente,
              v_iban,
              v_note_mod_pag,
              v_data_scadenza_mod_pag,
              v_soggetto_id_modpag,
              v_cod_sogg_mod_pag,
              v_tipo_sogg_mod_pag,
              v_stato_sogg_mod_pag,
              v_rag_sociale_sogg_mod_pag,
              v_p_iva_sogg_mod_pag,
              v_cf_sogg_mod_pag,
              v_cf_estero_sogg_mod_pag,
              v_nome_sogg_mod_pag,
              v_cognome_sogg_mod_pag,
              v_bil_anno_ord,
              v_anno_ord,
              v_num_ord,
              v_num_subord,
              --nuova sezione coge 26-09-2016
              v_registro_repertorio,
			  v_anno_repertorio,
			  v_num_repertorio,
			  v_data_repertorio,
              v_data_ricezione_portale,
              v_arrotondamento::numeric,
			  v_doc_contabilizza_genpcc,
              v_doc_id, -- SIAC-5573  ,
              -- 22.05.2018 Sofia siac-6124
	          v_data_ins_atto_allegato,
	          v_data_completa_atto_allegato,
		      v_data_convalida_atto_allegato,
	  	      v_data_sosp_atto_allegato,
        	  v_causale_sosp_atto_allegato,
	          v_data_riattiva_atto_allegato
             );

	END LOOP;

END LOOP;
esito:= 'Fine funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp() - fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- siac-6124 - Sofia fine

--SIAC-6163 - Maurizio - INIZIO

DROP FUNCTION IF EXISTS siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR024_Allegato_7_Allegato_delibera_variazione_variabili"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR119_Allegato_7_Allegato_delibera_variazione_su_entrate_bozz"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR119_Allegato_7_Allegato_delibera_variazione_su_spese_bozza"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR119_Allegato_7_Allegato_delibera_variazione_variabili_bozza"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar);
DROP FUNCTION IF EXISTS siac."BILR139_Allegato_8_Allegato_delibera_variazione_su_spese_fpv"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR140_Allegato_8_Allegato_delibera_variazione_su_spese_bozza"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar);
DROP FUNCTION IF EXISTS siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_data_protocollo varchar);
DROP FUNCTION IF EXISTS siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_data_protocollo varchar);

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  display_error varchar
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
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

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
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  
raise notice '1 - %' , clock_timestamp()::text;
/*insert into  siac_rep_tit_tip_cat_riga_anni
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
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
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
order by titolo_code, tipologia_code,categoria_code;*/

-- 30/08/2016: cambiata la query che carica la struttura di bilancio
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
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code
 ;
 

raise notice '2 - %' , clock_timestamp()::text;
 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
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
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  
 
 /* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
strQuery:='
	with cap as (
select 		capitolo_importi.elem_id,
              capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
              capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
              capitolo_importi.ente_proprietario_id,
              capitolo_imp_tipo.elem_det_tipo_id,
              '''||user_table||''' utente,   
              sum(capitolo_importi.elem_det_importo)    importo_cap 
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
      where 	capitolo_importi.ente_proprietario_id = '||p_ente_prop_id ||' 
          and	anno_eserc.anno						= 	'''||p_anno ||'''												
          and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
          and	capitolo.bil_id						=	bilancio.bil_id 			 
          and	capitolo.elem_id					=	capitolo_importi.elem_id 
          and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
          and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
          and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
          and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
          and	capitolo_imp_periodo.anno = '''||annoCapImp||'''
          and	capitolo.elem_id					=	r_capitolo_stato.elem_id
          and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
          and	stato_capitolo.elem_stato_code		=	''VA''
          and	capitolo.elem_id					=	r_cat_capitolo.elem_id
          and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
          and	cat_del_capitolo.elem_cat_code		=	''STD''
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
      group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
      capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente,
      capitolo_imp_tipo.elem_det_tipo_id),
      importi_variaz as (      
          select               
                dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
                sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
                from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
                siac_t_variazione avar, siac_r_variazione_stato bvar,
                siac_d_variazione_stato cvarsucc,
                siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
                siac_d_bil_elem_det_tipo tipoimp
                where bvarsucc.validita_inizio > bvar.validita_inizio
                and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
                and avarsucc.variazione_id= bvarsucc.variazione_id
                and avar.variazione_id=bvar.variazione_id
                and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
                and cvarsucc.variazione_stato_tipo_code=''D''
                and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
                and cvar.variazione_stato_tipo_code=''D''
                and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
                and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
                and bvarsucc.data_cancellazione is null
                and bvar.variazione_stato_id in (';
                --raise notice 'query1: %', strQuery; 
          if p_numero_delibera IS NOT NULL THEN
             strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_atto_amm             atto,
                  siac_d_atto_amm_tipo        tipo_atto,
                  siac_r_atto_amm_stato         r_atto_stato,
                  siac_d_atto_amm_stato         stato_atto,
                  siac_r_variazione_stato     var_stato
                where
                  (var_stato.attoamm_id = atto.attoamm_id 
                     or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
                  and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
                  and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
                  and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
                  and     atto.attoamm_numero=  '||p_numero_delibera||'
                  and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                  
                  and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
                  and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') 
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
          else 
          strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
          end if;
          strQuery:=strQuery||' 
                INSERT INTO siac_rep_cap_eg_imp
                select 	cap.elem_id, 
                          cap.BIL_ELE_IMP_ANNO, 
                          cap.TIPO_IMP,
                          cap.ente_proprietario_id, 
                          '''||user_table||''' utente,        
                          (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                from cap LEFT  JOIN importi_variaz 
                ON (cap.elem_id = importi_variaz.elem_id_var
                  and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';
          
          raise notice 'query2: %', strQuery;      

			execute  strQuery;   
     

RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			tb1.periodo_anno 	= annoCapImp		AND	tb1.tipo_imp =	tipoImpComp		and
        			tb2.periodo_anno	= tb1.periodo_anno	AND	tb2.tipo_imp = 	tipoImpCassa	and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	tb4.tipo_imp = 	tipoImpRes		and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  

--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id	      	
    from 	siac_t_atto_amm 			atto,
            siac_d_atto_amm_tipo		tipo_atto,
            siac_r_atto_amm_stato 		r_atto_stato,
            siac_d_atto_amm_stato 		stato_atto,
            siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_bil					t_bil,
            siac_t_periodo 				anno_importi
    where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
                r_variazione_stato.attoamm_id_varbil   				=	atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
        -- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
        --and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
    and		anno_importi.anno									= 	annoCapImp
    and		anno_eserc.anno	= 	p_anno										
     -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
    -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
    and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
    and		atto.data_cancellazione						is null
    and		tipo_atto.data_cancellazione				is null
    and		r_atto_stato.data_cancellazione				is null
    and		stato_atto.data_cancellazione				is null
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id;
else 
	strQuery:='
    insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id		
	-- 27/04:2017 l''anno di esercizio deve essere collegato a siac_t_bil									
	--and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
and 	testata_variazione.ente_proprietario_id	=	'||p_ente_prop_id||'
and		anno_eserc.anno	= 	'''||p_anno||''' 										
and 	testata_variazione.variazione_num in('||p_ele_variazioni||')
and		anno_importi.anno									= 	'''||annoCapImp||'''
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	testata_variazione.ente_proprietario_id';

raise notice 'query: %', strQuery;      

execute  strQuery;       
     
end if;                

           
RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	)
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	)
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0	);


/* ---- vecchia query
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		variazione_aumento_stanziato,
        coalesce (tb2.importo,0)   as 		variazione_diminuzione_stanziato,
        coalesce (tb3.importo,0)   as 		variazione_aumento_cassa,
        coalesce (tb4.importo,0)   as 		variazione_diminuzione_cassa,
        coalesce (tb5.importo,0)   as 		variazione_aumento_residuo,
        coalesce (tb6.importo,0)   as 		variazione_diminuzione_residuo,
        user_table utente,
         tb1.ente_proprietario
from   
	siac_rep_var_entrate tb1, siac_rep_var_entrate tb2, siac_rep_var_entrate tb3,
	siac_rep_var_entrate tb4,siac_rep_var_entrate tb5,siac_rep_var_entrate tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
                    tb4.elem_id	=	tb5.elem_id								and
                    tb5.elem_id	=	tb6.elem_id								and
        			tb1.tipologia  = 'STA'	AND	tb1.importo > 0				AND
                    tb2.tipologia = tb1.tipologia 	and tb2.importo < 0 	AND
                    tb3.tipologia  = 'SCA'	AND	tb3.importo > 0				AND
                    tb4.tipologia = tb3.tipologia 	and tb4.importo < 0		and
                    tb5.tipologia  = 'STR'	AND	tb5.importo > 0				AND
                    tb6.tipologia = tb5.tipologia 	and tb6.importo < 0		and
                    tb1.utente	  = user_table	AND
                    tb2.utente		=	tb1.utente	and
                    tb3.utente		=	tb1.utente	and
                    tb4.utente		=	tb1.utente	and
                    tb5.utente		=	tb1.utente	and
                    tb6.utente		=	tb1.utente;   */
        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
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
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo
from  	siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where v1.utente = user_table
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id
            /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	

			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
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
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;

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
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  display_error varchar
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
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;


raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;
/*
 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  
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

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;
-- 30/08/2016: cambiata la query che carica la struttura di bilancio
--da 6 secondi a 105 ms
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
    /* 30/08/2016: start filtro per mis-prog-macro*/
    , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 /* 30/08/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
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
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
strQuery:='
with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo	             			            
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||' 
        and	anno_eserc.anno						= 	'''||p_anno ||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  ='''||annoCapImp||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')						
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
    importi_variaz as (      
		select               
              dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
              from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp
              where bvarsucc.validita_inizio > bvar.validita_inizio
              and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and cvarsucc.variazione_stato_tipo_code=''D''
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and cvar.variazione_stato_tipo_code=''D''
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and bvarsucc.data_cancellazione is null
              and bvar.variazione_stato_id in ( ';
                             
if p_numero_delibera IS NOT NULL THEN
	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_atto_amm             atto,
                  siac_d_atto_amm_tipo        tipo_atto,
                  siac_r_atto_amm_stato         r_atto_stato,
                  siac_d_atto_amm_stato         stato_atto,
                  siac_r_variazione_stato     var_stato
                where
                  (var_stato.attoamm_id = atto.attoamm_id 
                     or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
                  and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
                  and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
                  and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
                  and     atto.attoamm_numero=  '||p_numero_delibera||'
                  and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                  
                  and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
                  and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') 
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
else 
	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
end if;

strQuery:=strQuery||'
              INSERT INTO siac_rep_cap_ug_imp
              select 	cap.elem_id, 
              			cap.BIL_ELE_IMP_ANNO, 
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id, 
                        '''||user_table||''' utente,               
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz 
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';
 
raise notice 'query: %', strQuery;      

execute  strQuery; 
            
RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente 
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= annoCapImp		AND	 tb1.tipo_imp 	=	tipoImpComp		AND
        		tb2.periodo_anno		= tb1.periodo_anno	AND	tb2.tipo_imp 	= 	tipoImpCassa	and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	tb4.tipo_imp 	= 	TipoImpRes		and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.            
--Parametro specificato: atto di variazione.
if p_numero_delibera is not null THEN        
insert into siac_rep_var_spese    
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
       		r_variazione_stato.attoamm_id_varbil   				=	atto.attoamm_id )
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
and		anno_eserc.anno										= 	p_anno				 	
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
	-- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
	--and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
and		anno_importi.anno									= 	annoCapImp 									
 -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	atto.ente_proprietario_id   ;
ELSE
	strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
and		anno_eserc.anno										= 	'''||p_anno||''' 
and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
and		anno_importi.anno									= 	'''||annoCapImp||'''									
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	testata_variazione.ente_proprietario_id';
            
raise notice 'Query variazioni: %', strQuery;

execute strQuery;
            
end if;            
                     

            
        
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	)
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	)
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0	); 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table)     
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;



return next;
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

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_variabili" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;


BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';


-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

--SIAC-6163: 16/05/2018.
-- Introdotti i paramentri p_ele_variazioni e p_anno_variazione con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
           	--------capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
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
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
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
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
    -----group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente

     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera is not null THEN
  insert into siac_rep_var_entrate
  select	dettaglio_variazione.elem_id,
          dettaglio_variazione.elem_det_importo,
          cat_del_capitolo.elem_cat_code,
          user_table utente,
          atto.ente_proprietario_id	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc ,
          -- 21-12 anna inizio
          siac_t_bil					t_bil,
          -- 21-12 anna fine
          siac_t_periodo 				anno_importi
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil 				= 	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  -- 21-12 anna commentato and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
  -- 21-12 anna inizio
  and		anno_eserc.periodo_id 								=   t_bil.periodo_id
  and 	t_bil.bil_id 										=	testata_variazione.bil_id								
  -- 21-12 anna fine
  and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id											
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		atto.ente_proprietario_id 							=  p_ente_prop_id	
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		anno_eserc.anno										= 	p_anno 
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera	
  and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
      -- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
      --and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
  and		anno_importi.anno									= 	annoCapImp 
  and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  and		tipo_elemento.elem_det_tipo_code					= 'STA'
  and		cat_del_capitolo.elem_cat_code						in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null;
else
	strQuery:= '
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
		dettaglio_variazione.elem_det_importo,
        cat_del_capitolo.elem_cat_code,
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	 siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_d_bil_elem_categoria 	cat_del_capitolo, 
        siac_r_bil_elem_categoria 	r_cat_capitolo,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_eserc.periodo_id 								=   t_bil.periodo_id
and 	t_bil.bil_id 										=	testata_variazione.bil_id								
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id											
and		capitolo.elem_id									=	r_cat_capitolo.elem_id
and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
and		testata_variazione.ente_proprietario_id 			= '||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
and		anno_importi.anno									= 	 '''||annoCapImp||'''
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
and		tipo_elemento.elem_det_tipo_code					= ''STA''
and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')	
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		cat_del_capitolo.data_cancellazione			is null 
and     r_cat_capitolo.data_cancellazione			is null ';

raise notice 'sqlQuery = %', strQuery;

execute strQuery;

end if;
    
RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		sum(tb1.importo)   as 		variazione_aumento_stanziato,
        sum(tb2.importo)   as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_eg_imp tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and 	tb1.importo > 0	) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	AND	tb2.importo < 0	)
    group by 	tb0.elem_id,
    			tb0.utente,
        		tb1.ente_proprietario;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;
variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;

return next;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR119_Allegato_7_Allegato_delibera_variazione_su_entrate_bozz" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  anno_riferimento varchar,
  display_error varchar
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
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione


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
display_error:='';


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  

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

--06/09/2016: cambiata la query che carica la struttura di bilancio
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

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
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
-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
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
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

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
       -- and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
		and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	
                    tb4.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  

/*
insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
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
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
---------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera-----------   deve essere un parametro di input 
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
          or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
-- 13/02/2017: aggiunto filtro su anno competenza  
and     anno_importo.anno                                   =   p_anno_competenza 					
-- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
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
        	atto.ente_proprietario_id,
            anno_importo.anno	  ;*/

--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
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
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  -- 13/02/2017: aggiunto filtro su anno competenza  
  and     anno_importo.anno                                   =   p_anno_competenza--anno competenza			
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P')
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
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
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_entrate 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
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
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''	--anno variazione				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
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
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                   


    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
insert into siac_rep_var_entrate_riga
select  tb0.elem_id,
/* 
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/       
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_competenza
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno=p_anno_competenza
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno=p_anno_competenza
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno=p_anno_competenza
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno=p_anno_competenza
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno=p_anno_competenza
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno=p_anno_competenza
        and tb6.utente = tb0.utente 	)
 /* union 
     select  tb0.elem_id,
/* 
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/       
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb6.utente = tb0.utente 	)
    union 
    select  tb0.elem_id,
/* 
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/       
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
	from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb6.utente = tb0.utente 	)*/;


/* ---- vecchia query
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		variazione_aumento_stanziato,
        coalesce (tb2.importo,0)   as 		variazione_diminuzione_stanziato,
        coalesce (tb3.importo,0)   as 		variazione_aumento_cassa,
        coalesce (tb4.importo,0)   as 		variazione_diminuzione_cassa,
        coalesce (tb5.importo,0)   as 		variazione_aumento_residuo,
        coalesce (tb6.importo,0)   as 		variazione_diminuzione_residuo,
        user_table utente,
         tb1.ente_proprietario
from   
	siac_rep_var_entrate tb1, siac_rep_var_entrate tb2, siac_rep_var_entrate tb3,
	siac_rep_var_entrate tb4,siac_rep_var_entrate tb5,siac_rep_var_entrate tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
                    tb4.elem_id	=	tb5.elem_id								and
                    tb5.elem_id	=	tb6.elem_id								and
        			tb1.tipologia  = 'STA'	AND	tb1.importo > 0				AND
                    tb2.tipologia = tb1.tipologia 	and tb2.importo < 0 	AND
                    tb3.tipologia  = 'SCA'	AND	tb3.importo > 0				AND
                    tb4.tipologia = tb3.tipologia 	and tb4.importo < 0		and
                    tb5.tipologia  = 'STR'	AND	tb5.importo > 0				AND
                    tb6.tipologia = tb5.tipologia 	and tb6.importo < 0		and
                    tb1.utente	  = user_table	AND
                    tb2.utente		=	tb1.utente	and
                    tb3.utente		=	tb1.utente	and
                    tb4.utente		=	tb1.utente	and
                    tb5.utente		=	tb1.utente	and
                    tb6.utente		=	tb1.utente;   */
        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
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
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_tit_tip_cat_riga_anni v1
			  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
    where v1.utente = user_table
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id
            /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	

			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
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
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;


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
end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR119_Allegato_7_Allegato_delibera_variazione_su_spese_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
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
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;


BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
display_error:='';

---------------------------------------------------------------------------------------------------------------------

--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  
/* insert into siac_rep_mis_pro_tit_mac_riga_anni
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


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
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
	-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and			
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

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
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPVC
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi					
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
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
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
 
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		--tb1.periodo_anno 		= annoCapImp		AND	 
                tb1.tipo_imp 	=	tipoImpComp		        AND      
        		tb2.periodo_anno		= tb1.periodo_anno	AND	
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	
                tb4.tipo_imp 	= 	TipoImpRes		        and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  
     /*
insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
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
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
---------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera-----------   deve essere un parametro di input 
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil    			=	atto.attoamm_id )
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
-- 13/02/2017: aggiunto filtro su anno competenza 
and     anno_importo.anno                                   =   p_anno_competenza 					
 -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and 	tipologiacavoli_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
--and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
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
        	atto.ente_proprietario_id,
            anno_importo.anno	    ;*/

--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
insert into siac_rep_var_spese            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
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
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  -- 13/02/2017: aggiunto filtro su anno competenza  
  and     anno_importo.anno                                   =   p_anno_competenza		
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P')
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
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
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
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
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
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
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                               
        

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_competenza 
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno_competenza
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_competenza
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_competenza
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
 /*  union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp3
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp3
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp3
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp3
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp3
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp3
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp3
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table   */ ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
			join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)     
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;


return next;
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
end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR119_Allegato_7_Allegato_delibera_variazione_variabili_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;


BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';


-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where --ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and
 e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
/*and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
           	--------capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
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
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
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
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
    -----group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente

     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

/*
insert into siac_rep_var_entrate
(
  elem_id,
  importo,
  utente,
  ente_proprietario,
  periodo_anno
)
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
        --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
        --------tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_d_bil_elem_categoria 	cat_del_capitolo, 
        siac_r_bil_elem_categoria 	r_cat_capitolo,
        siac_t_periodo 				anno_eserc,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
-- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
--and     anno_importo.anno                                   =   p_anno 					
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					= 'STA'
and		capitolo.elem_id									=	r_cat_capitolo.elem_id
and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
and		cat_del_capitolo.elem_cat_code						in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		cat_del_capitolo.data_cancellazione			is null 
and     r_cat_capitolo.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
        	utente,
            atto.ente_proprietario_id,
            anno_importo.anno;*/
            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  and		tipo_elemento.elem_det_tipo_code					= 'STA'
  and		cat_del_capitolo.elem_cat_code					in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
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
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
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
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  and		tipo_elemento.elem_det_tipo_code					= ''STA''
  and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')	
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;              
    	              
            

    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  




insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
--tipologia_capitolo := 'DAM';
stanziato := classifBilRec.stanziato;
--stanziato := 250;
variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;
return next;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR139_Allegato_8_Allegato_delibera_variazione_su_spese_fpv" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  display_error varchar
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
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;


raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
display_error:='';

---------------------------------------------------------------------------------------------------------------------

--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;


RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;
-- caricamento della struttura di bilancio
--da 6 secondi a 105 ms
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
    /* 30/08/2016: start filtro per mis-prog-macro*/
    , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 /* 30/08/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
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
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
    -- per questo report devono essere estratti solo i capitoli FPV
	cat_del_capitolo.elem_cat_code	in ('FPV')
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

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
strQuery:='
with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||' 
        and	anno_eserc.anno						= 	'''||p_anno ||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  ='''||annoCapImp||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        -- per questo report devono essere estratti solo i capitoli FPV
        and cat_del_capitolo.elem_cat_code	in (''FPV'')
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
    importi_variaz as (      
		select               
              dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
              from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp
              where bvarsucc.validita_inizio > bvar.validita_inizio
              and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and cvarsucc.variazione_stato_tipo_code=''D''
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and cvar.variazione_stato_tipo_code=''D''
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and bvarsucc.data_cancellazione is null
              and bvar.variazione_stato_id in ( ';
if p_numero_delibera IS NOT NULL THEN
	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_atto_amm             atto,
                  siac_d_atto_amm_tipo        tipo_atto,
                  siac_r_atto_amm_stato         r_atto_stato,
                  siac_d_atto_amm_stato         stato_atto,
                  siac_r_variazione_stato     var_stato
                where
                  (var_stato.attoamm_id = atto.attoamm_id 
                     or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
                  and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
                  and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
                  and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
                  and     atto.attoamm_numero=  '||p_numero_delibera||'
                  and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                  
                  and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
                  and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') 
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
else 
	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
end if;
strQuery:=strQuery||'
              INSERT INTO siac_rep_cap_ug_imp
              select 	cap.elem_id, 
              			cap.BIL_ELE_IMP_ANNO, 
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id, 
                        '''||user_table||''' utente,               
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz 
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';
 
raise notice 'query2: %', strQuery;      

execute  strQuery; 
/*
with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	'VA'								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        -- per questo report devono essere estratti solo i capitoli FPV
        and cat_del_capitolo.elem_cat_code	in ('FPV')						
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
    importi_variaz as (      
		select 
              --avar.variazione_num, avarsucc.variazione_num, dvarsucc.elem_det_importo,
             -- dvarsucc.elem_id, tipoimp.elem_det_tipo_code ,  --avarsucc.variazione_num,
             -- cvarsucc.variazione_stato_tipo_code, bvarsucc.validita_inizio,
              dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
              from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp
              where bvarsucc.validita_inizio > bvar.validita_inizio
              and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and cvarsucc.variazione_stato_tipo_code='D'
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and cvar.variazione_stato_tipo_code='D'
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and bvarsucc.data_cancellazione is null
              and bvar.variazione_stato_id in (
              select max(var_stato.variazione_stato_id)
              from siac_t_atto_amm             atto,
                siac_d_atto_amm_tipo        tipo_atto,
                siac_r_atto_amm_stato         r_atto_stato,
                siac_d_atto_amm_stato         stato_atto,
                siac_r_variazione_stato     var_stato
              where
                ( var_stato.attoamm_id = atto.attoamm_id or
                  var_stato.attoamm_id_varbil = atto.attoamm_id )
                and     atto.ente_proprietario_id   =   p_ente_prop_id
                and     atto.attoamm_numero=  p_numero_delibera
                and     atto.attoamm_anno  =  p_anno_delibera
                and     atto.attoamm_tipo_id  =   tipo_atto.attoamm_tipo_id
                and     tipo_atto.attoamm_tipo_code  = p_tipo_delibera
                and     r_atto_stato.attoamm_id   =   atto.attoamm_id
                and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
                and     stato_atto.attoamm_stato_code   =   'DEFINITIVO') 
              group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) 
              INSERT INTO siac_rep_cap_ug_imp
              select 	cap.elem_id, 
              			cap.BIL_ELE_IMP_ANNO, 
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id, 
                        user_table utente,
               -- cap.importo_cap,COALESCE(importi_variaz.totale_var_succ,0) variaz, 
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz 
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id);
 */
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente 
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= annoCapImp		AND	 tb1.tipo_imp 	=	tipoImpComp		AND
        		tb2.periodo_anno		= tb1.periodo_anno	AND	tb2.tipo_imp 	= 	tipoImpCassa	and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	tb4.tipo_imp 	= 	TipoImpRes		and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
RTN_MESSAGGIO:='preparazione tabella variazioni''.';  


--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_spese
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_t_periodo 				anno_eserc ,
          siac_t_periodo 				anno_importi
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
  and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id			
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 				
  and		atto.attoamm_numero 								= 	p_numero_delibera 
  and		atto.attoamm_anno									=	p_anno_delibera		
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera		
  and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'									
  and		anno_importi.anno									= 	annoCapImp 												
  and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
   -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
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
              atto.ente_proprietario_id;
else
	strQuery:='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id			
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''													
and		anno_importi.anno									= 	'''||annoCapImp||''' 												
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')
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
        	testata_variazione.ente_proprietario_id';
            
raise notice 'query: %', strQuery;      

execute  strQuery;  

end if;
                    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	)
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	)
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0	); 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table)     
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;



return next;
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

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR140_Allegato_8_Allegato_delibera_variazione_su_spese_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
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
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
display_error:='';

---------------------------------------------------------------------------------------------------------------------

raise notice'INIZIO';


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	--devo valorizzare anche anno_riferimento, perche' nei dataset del report
    --c'e' un filtro su questo campo e quindi se non e' valorizzato non viene
    --visto nemmeno il display_error
    anno_riferimento:=p_anno_competenza;
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	--devo valorizzare anche anno_riferimento, perche' nei dataset del report
    --c'e' un filtro su questo campo e quindi se non e' valorizzato non viene
    --visto nemmeno il display_error
    anno_riferimento:=p_anno_competenza;
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN   
	--devo valorizzare anche anno_riferimento, perche' nei dataset del report
    --c'e'' un filtro su questo campo e quindi se non e' valorizzato non viene
    --visto nemmeno il display_error
    anno_riferimento:=p_anno_competenza; 
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  
/* insert into siac_rep_mis_pro_tit_mac_riga_anni
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


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 06/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;

raise notice 'insert su siac_rep_mis_pro_tit_mac_riga_anni';

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
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
	-- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
-- per questo report prendo solo i capitoli FPV
	cat_del_capitolo.elem_cat_code	in ('FPV')
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

  raise notice 'insert su siac_rep_cap_ug';

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

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
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'
        and	stato_capitolo.elem_stato_code		in	('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        -- per questo report prendo solo FPV
        and cat_del_capitolo.elem_cat_code	in ('FPV')	
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi					
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 					
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
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
 
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		--tb1.periodo_anno 		= annoCapImp		AND	 
                tb1.tipo_imp 	=	tipoImpComp		        AND      
        		tb2.periodo_anno		= tb1.periodo_anno	AND	
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	
                tb4.tipo_imp 	= 	TipoImpRes		        and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.'; 
     
/*      
insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        ------dettaglio_variazione.elem_det_importo,
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato     r_variazione_stato,
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
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
---------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera-----------   deve essere un parametro di input 
--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and     (r_variazione_stato.attoamm_id						=	atto.attoamm_id or
		r_variazione_stato.attoamm_id_varbil				=   atto.attoamm_id )
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
-- 13/02/2017: aggiunto filtro su anno competenza 
and     anno_importo.anno                                   =   p_anno_competenza 	 					
 -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
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
        	atto.ente_proprietario_id,
            anno_importo.anno	    ;*/
            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
	insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id,
            anno_importo.anno	      	
    from 	siac_t_atto_amm 			atto,
            siac_d_atto_amm_tipo		tipo_atto,
            siac_r_atto_amm_stato 		r_atto_stato,
            siac_d_atto_amm_stato 		stato_atto,
            siac_r_variazione_stato		r_variazione_stato,
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
    where 	r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
              r_variazione_stato.attoamm_id_varbil				=   atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
    and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id 
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		atto.ente_proprietario_id 							= 	p_ente_prop_id
    and		anno_eserc.anno										= 	p_anno 						
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    --and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'					
    -- 13/02/2017: aggiunto filtro su anno competenza 
    and     anno_importo.anno                                   =   p_anno_competenza 	 					
     -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
    -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
    and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
    and		atto.data_cancellazione						is null
    and		tipo_atto.data_cancellazione				is null
    and		r_atto_stato.data_cancellazione				is null
    and		stato_atto.data_cancellazione				is null
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
                atto.ente_proprietario_id,
                anno_importo.anno	    ;            
else 
	strQuery:='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
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
      and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
      and		testata_variazione.ente_proprietario_id 			= '||p_ente_prop_id||'
      and		anno_eserc.anno										= 	'''||p_anno ||'''						
      and 	testata_variazione.variazione_num 						in ('||p_ele_variazioni||')
      and     anno_importo.anno                                   =   '''||p_anno_competenza||''' 	 					       
      and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')
      and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
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
                anno_importo.anno' ;
                
	raise notice 'query: %', strQuery;      

	execute  strQuery;                 
end if;        
RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
     
--/13/02/2017 : e' rimasto solo il filtro su anno_competenza     
insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_competenza
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno_competenza
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_competenza
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_competenza
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
/*   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp3
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp3
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp3
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp3
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp3
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp3
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp3
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table   */ ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)     
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;


return next;
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
end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
			--devo valorizzare l'anno di riferimento anche in caso di errore
        	--perche' nel report c'e' un filtro su questo campo
        	-- ed il messaggio di errore non verrebbe visualizzato
		anno_riferimento:=p_anno_competenza;    
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
			--devo valorizzare l'anno di riferimento anche in caso di errore
        	--perche' nel report c'e' un filtro su questo campo
        	-- ed il messaggio di errore non verrebbe visualizzato
		anno_riferimento:=p_anno_competenza;    
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_data_protocollo varchar,
  p_ele_variazioni varchar,
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
  stanziamento numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
tipoImpComp varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
v_data date;

strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

	BEGIN
		v_data = to_date(p_data_protocollo, 'dd/MM/yyyy');        
    EXCEPTION
	when others  THEN
     display_error := 'CAMPO DATA PROTOCOLLO FORMALMENTE NON CORRETTO';
     return next;
     return;                         
    END;    

IF p_data_protocollo != '' AND p_data_protocollo IS NOT NULL THEN
  IF to_char(v_data,'dd/MM/yyyy') != p_data_protocollo THEN
     display_error := 'CAMPO DATA PROTOCOLLO FORMALMENTE NON CORRETTO';
     return next;
     return;
  END IF; 
END IF;
/*
IF p_numero_delibera IS NOT NULL 
   OR
   (p_anno_delibera IS NOT NULL AND p_anno_delibera != '')
   OR
   (p_tipo_delibera IS NOT NULL AND  p_tipo_delibera != '')
   THEN
   IF p_numero_delibera IS NULL THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;
   END IF;
   IF p_anno_delibera IS NULL OR p_anno_delibera = '' THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;      
   END IF; 
   IF p_tipo_delibera IS NULL OR  p_tipo_delibera = '' THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;      
   END IF;  
END IF;        */
 
display_error:='';

--SIAC-6163: 16/05/2018.
-- Introdotti i paramentri p_ele_variazioni e p_anno_variazione con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN   
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

TipoImpComp='STA';  -- competenza

elemTipoCode:='CAP-EG';

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
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
anno_riferimento='';

select fnc_siac_random_user()
into	user_table;

RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni ''.';  

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

RTN_MESSAGGIO:='insert tabella siac_rep_cap_eg ''.';  

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
  cat_del_capitolo.elem_cat_code
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
-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
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
and	cat_del_capitolo.data_cancellazione	is null;


RTN_MESSAGGIO:='insert tabella siac_rep_cap_eg_imp ''.';  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

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
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
		and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi
        and capitolo_imp_periodo.anno =	p_anno					
        -- and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 
        and	capitolo_imp_tipo.elem_det_tipo_code = 'STA' 		
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

RTN_MESSAGGIO:='insert tabella siac_rep_cap_eg_imp_riga ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		0,
        tb1.importo 	as 		previsioni_definitive_comp,
        0,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1
	where tb1.ente_proprietario =	p_ente_prop_id			
    and tb1.utente				=	user_table;
                  
     RTN_MESSAGGIO:='insert tabella siac_rep_var_entrate ''.';  

IF p_numero_delibera IS NOT NULL AND p_anno_delibera IS NOT NULL AND p_tipo_delibera IS NOT NULL THEN

insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
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
where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id													
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		atto.ente_proprietario_id 							= 	p_ente_prop_id
and		anno_eserc.anno										= 	p_anno
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
-- 13/02/2017: aggiunto filtro su anno competenza  
and     anno_importo.anno                                   =   p_anno_competenza 					
and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P')
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		tipo_elemento.elem_det_tipo_code					= 'STA'
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
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
        	atto.ente_proprietario_id,
            anno_importo.anno	  ;
else
	strQuery:= '
    insert into siac_rep_var_entrate
	select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
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
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and		testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					= ''STA''
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

raise notice 'Query: %',strQuery;

execute strQuery;
            
                        
/*select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
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
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
--and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
-- 13/02/2017: aggiunto filtro su anno competenza  
and     anno_importo.anno                                   =   p_anno 					
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		 in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					= 'STA'
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
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
        	atto.ente_proprietario_id,
            anno_importo.anno	  ;*/

END IF; 

RTN_MESSAGGIO:='insert tabella siac_rep_var_entrate_riga ''.';  

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno=p_anno
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno=p_anno
        and tb2.utente = tb0.utente )
  where  tb0.utente = user_table;
                 
RTN_MESSAGGIO:='preparazione file output ''.';

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
   il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/

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
        COALESCE (tb1.previsioni_definitive_comp,0)				stanziamento,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_tit_tip_cat_riga_anni v1
			  left join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
    where v1.utente = user_table
   /*and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id                        
    )	*/

			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop

--titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
--categoria_tipo_code := classifBilRec.categoria_tipo_code;
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
stanziamento:=classifBilRec.stanziamento;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
anno_riferimento:=classifBilRec.anno_riferimento;

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
stanziamento=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
anno_riferimento='';
end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_eg where utente=user_table;
delete from siac_rep_cap_eg_imp where utente=user_table;
delete from siac_rep_cap_eg_imp_riga where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;
delete from siac_rep_var_entrate_riga where utente=user_table; 

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when syntax_error THEN    
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN 
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_data_protocollo varchar,
  p_ele_variazioni varchar,
  p_anno_competenza varchar
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
  stanziamento_prev_anno numeric,
  stanziamento_fpv_anno numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_fpv numeric,
  variazione_diminuzione_fpv numeric,
  impegnato_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImpInt integer;
tipoImpComp varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
v_data date;

strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN
	display_error:='';
    
	BEGIN
		v_data = to_date(p_data_protocollo, 'dd/MM/yyyy');        
    EXCEPTION
	when others  THEN
     display_error := 'CAMPO DATA PROTOCOLLO FORMALMENTE NON CORRETTO';
     return next;
     return;                         
    END;    

IF p_data_protocollo != '' AND p_data_protocollo IS NOT NULL THEN
  IF to_char(v_data,'dd/MM/yyyy') != p_data_protocollo THEN
     display_error := 'CAMPO DATA PROTOCOLLO FORMALMENTE NON CORRETTO';
     return next;
     return;
  END IF; 
END IF;
/*
IF p_numero_delibera IS NOT NULL 
   OR
   (p_anno_delibera IS NOT NULL AND p_anno_delibera != '')
   OR
   (p_tipo_delibera IS NOT NULL AND  p_tipo_delibera != '')
   THEN
   IF p_numero_delibera IS NULL THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;
   END IF;
   IF p_anno_delibera IS NULL OR p_anno_delibera = '' THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;      
   END IF; 
   IF p_tipo_delibera IS NULL OR  p_tipo_delibera = '' THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;      
   END IF;  
END IF;  */


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN   
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


annoCapImp:= p_anno; 
annoCapImpInt:= p_anno::integer;

TipoImpComp='STA';  -- competenza

elemTipoCode:='CAP-UG';

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
stanziamento_prev_anno=0;
stanziamento_fpv_anno=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_fpv=0;
variazione_diminuzione_fpv=0;
impegnato_anno=0;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  

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
from missione, programma, titusc, macroag, 
     siac_r_class progmacro
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
and programma.programma_id = progmacro.classif_a_id
and titusc.titusc_id = progmacro.classif_b_id
and titusc.ente_proprietario_id=missione.ente_proprietario_id;

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.'; 


insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        cat_del_capitolo.elem_cat_code,
        --' ',
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
	-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and			
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    -- 06/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp''.'; 
 
/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	--capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            cat_del_capitolo.elem_cat_code          TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPVC
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi					
        --and capitolo_imp_periodo.anno = p_anno_competenza
        and capitolo_imp_periodo.anno =	p_anno							
        and	capitolo_imp_tipo.elem_det_tipo_code = 'STA'
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
    group by	capitolo_importi.elem_id,
    --capitolo_imp_tipo.elem_det_tipo_code,
    cat_del_capitolo.elem_cat_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
     
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp_riga STD''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
        from 
        siac_rep_cap_ug_imp tb1
        where tb1.periodo_anno = annoCapImp	
        and	tb1.tipo_imp in ('STD','FSC')
        -- and	tb1.tipo_imp =	TipoImpComp	
        -- and	tb1.tipo_capitolo in ('STD','FSC')
        and	tb1.utente	=	user_table;

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp_riga FPV''.'; 
      
insert into siac_rep_cap_ug_imp_riga
select  tb2.elem_id,      
    	0,
    	tb2.importo		as		stanziamento_fpv_anno,
    	0,
        tb2.ente_proprietario,
        user_table utente,
        tb2.periodo_anno 
        from siac_rep_cap_ug_imp tb2
        where tb2.periodo_anno = annoCapImp 
        and	tb2.tipo_imp in ('FPV','FPVC') 
        -- and	tb2.tipo_imp = 	TipoImpComp	
        -- and	tb2.tipo_capitolo	in ('FPV','FPVC')
        and	tb2.utente	=	user_table;
      
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.';  

insert into siac_rep_impegni_riga
select n.elem_id,
sum(c.movgest_ts_det_importo) importo,
  0,
  0,
  p_ente_prop_id,
  user_table utente
from 
siac_t_bil l, 
siac_t_periodo m, 
siac_t_bil_elem n,
siac_d_bil_elem_tipo t,
siac_r_movgest_bil_elem o, 
siac_t_movgest a, 
siac_t_movgest_ts b, 
siac_t_movgest_ts_det c, 
siac_d_movgest_ts_det_tipo d, 
siac_d_movgest_tipo e, 
siac_r_movgest_ts_atto_amm f,
siac_t_atto_amm g, 
siac_d_movgest_stato h, 
siac_r_movgest_ts_stato i
where l.periodo_id = m.periodo_id 
and m.anno = p_anno
and l.bil_id = n.bil_id
and t.elem_tipo_id = n.elem_tipo_id
and t.elem_tipo_code = elemTipoCode
and o.elem_id = n.elem_id
and o.movgest_id = a.movgest_id
and a.movgest_id = b.movgest_id
and b.movgest_ts_id_padre is null
and b.movgest_ts_id = c.movgest_ts_id
and c.movgest_ts_det_tipo_id = d.movgest_ts_det_tipo_id
and d.movgest_ts_det_tipo_code = 'I'
and a.movgest_anno = annoCapImpInt
and e.movgest_tipo_id = a.movgest_tipo_id
and e.movgest_tipo_code = 'I'
and f.movgest_ts_id = b.movgest_ts_id
and f.attoamm_id = g.attoamm_id
and g.attoamm_anno < p_anno
and h.movgest_stato_id = i.movgest_stato_id
and i.movgest_ts_id = b.movgest_ts_id
and i.data_cancellazione is null
and i.validita_fine is null
and h.movgest_stato_code in ('N', 'D')
and a.ente_proprietario_id = p_ente_prop_id
and a.parere_finanziario is true
and a.data_cancellazione is null
and b.validita_inizio <= to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
and (a.parere_finanziario_data_modifica < to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') or a.parere_finanziario_data_modifica is null)
and c.data_cancellazione is null
and c.validita_fine is null
and a.data_cancellazione is null
and a.validita_fine is null
and b.data_cancellazione is null
and b.validita_fine is null
and f.data_cancellazione is null
and f.validita_fine is null
and g.data_cancellazione is null
and g.validita_fine is null
and i.data_cancellazione is null
and i.validita_fine is null
group by  n.elem_id;
         
IF p_numero_delibera IS NOT NULL AND p_anno_delibera IS NOT NULL AND p_tipo_delibera IS NOT NULL THEN                

    RTN_MESSAGGIO:='insert tabella siac_rep_var_spese''.'; 
     
    insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id,
            anno_importo.anno	      	
    from 	siac_t_atto_amm 			atto,
            siac_d_atto_amm_tipo		tipo_atto,
            siac_r_atto_amm_stato 		r_atto_stato,
            siac_d_atto_amm_stato 		stato_atto,
            siac_r_variazione_stato		r_variazione_stato,
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
    where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
              r_variazione_stato.attoamm_id_varbil 				=	atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id  
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		anno_eserc.anno										= 	p_anno 																	
    and     anno_importo.anno                                   =   p_anno_competenza
    and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					= 'STA'
    and		atto.data_cancellazione						is null
    and		tipo_atto.data_cancellazione				is null
    and		r_atto_stato.data_cancellazione				is null
    and		stato_atto.data_cancellazione				is null
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
                atto.ente_proprietario_id,
                anno_importo.anno;
else 
	strQuery := '
    insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
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
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		testata_variazione.ente_proprietario_id				= '||p_ente_prop_id||'
and		anno_eserc.anno										=  '''||p_anno ||'''
and 	testata_variazione.variazione_num					in ('|| p_ele_variazioni||')											
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''
and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					= ''STA''
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
            
raise notice 'Query: %',strQuery;

execute strQuery;
              
/*
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
        anno_importo.anno	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
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
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil 				=	atto.attoamm_id )
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  					
and     anno_importo.anno                                   =   p_anno
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					= 'STA'
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
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
        	atto.ente_proprietario_id,
            anno_importo.anno;*/
     
END IF;     
     
RTN_MESSAGGIO:='insert tabella siac_rep_var_spese_riga''.';  

insert into siac_rep_var_spese_riga
select  tb0.elem_id,       
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as        variazione_aumento_fpv,
        tb4.importo   as        variazione_diminuzione_fpv,        
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('STD','FSC')
        -- and tb1.tipologia  	= 'STA'	
        and	tb1.importo >= 0	
        --and tb1.periodo_anno=p_anno_competenza        
        and tb1.utente = tb0.utente
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('STD','FSC')
     	--and tb2.tipologia  	= 'STA'	
        and	tb2.importo < 0	
        --and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
    on (tb3.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('FPV','FPVC')
     	-- and tb3.tipologia  	= 'STA'	
        and	tb3.importo >= 0	
        --and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('FPV','FPVC')
     	-- and tb4.tipologia  	= 'STA'	
        and	tb4.importo < 0	
        --and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente 
        )                          
where  tb0.utente = user_table;
  
     RTN_MESSAGGIO:='preparazione file output ''.'; 
      
for classifBilRec in
select v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.residui_passivi,0)                 stanziamento_prev_anno,
        COALESCE (tb1.previsioni_definitive_comp,0)     stanziamento_fpv_anno,
        COALESCE (tb2.variazione_aumento_stanziato,0)    variazione_aumento_stanziato, 
        COALESCE (tb2.variazione_diminuzione_stanziato* -1,0) variazione_diminuzione_stanziato,
        COALESCE (tb2.variazione_aumento_cassa,0)         variazione_aumento_fpv,
        COALESCE (tb2.variazione_diminuzione_cassa* -1,0)     variazione_diminuzione_fpv,
        COALESCE (tb3.impegnato_anno,0)                   impegnato_anno        
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
    left join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND tb.utente=v1.utente
                    and v1.utente=user_table)  
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		and tb.utente=tb1.utente
                    and tb.utente=user_table
                    )  
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb.elem_id
            		and tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    --and tb2.periodo_anno=tb1.periodo_anno
                    ) 
            left join siac_rep_impegni_riga tb3
            on (tb3.elem_id = tb.elem_id 
                and tb3.utente=tb2.utente
                and tb2.utente=user_table)                                       
where v1.utente = user_table 
    /*and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id                        
    )	*/
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop

missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_fpv:=classifBilRec.variazione_aumento_fpv;
variazione_diminuzione_fpv:=classifBilRec.variazione_diminuzione_fpv;
impegnato_anno:=classifBilRec.impegnato_anno;

return next;
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
stanziamento_prev_anno=0;
stanziamento_fpv_anno=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_fpv=0;
variazione_diminuzione_fpv=0;
impegnato_anno=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;
delete from siac_rep_cap_ug_imp where utente=user_table;
delete from siac_rep_cap_ug_imp_riga where utente=user_table;
delete from siac_rep_impegni_riga where utente=user_table;
delete from	siac_rep_var_spese	where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when syntax_error THEN    
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN 
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;

--SIAC-6163 - Maurizio - FINE

-- siac-6125 - Sofia - INIZIO

drop VIEW if exists siac_v_dwh_fattura_sirfel;

CREATE OR REPLACE VIEW siac_v_dwh_fattura_sirfel (
    ente_proprietario_id,
    fornitore_cod,
    fornitore_desc,
    data_emissione,
    data_ricezione,
    numero_documento,
    documento_fel_tipo_cod,
    documento_fel_tipo_desc,
    data_acquisizione,
    stato_acquisizione,
    importo_lordo,
    arrotondamento_fel,
    importo_netto,
    codice_destinatario,
    tipo_ritenuta,
    aliquota_ritenuta,
    importo_ritenuta,
    anno_protocollo,
    numero_protocollo,
    registro_protocollo,
    data_reg_protocollo,
    modpag_cod,
    modpag_desc,
    aliquota_iva,
    imponibile,
    imposta,
    arrotondamento_onere,
    spese_accessorie,
    doc_id,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    data_scadenza_pagamento_pcc) -- siac-6125 Sofia 23.05.2018
AS
SELECT tab.ente_proprietario_id, tab.fornitore_cod, tab.fornitore_desc,
    tab.data_emissione, tab.data_ricezione, tab.numero_documento,
    tab.documento_fel_tipo_cod, tab.documento_fel_tipo_desc,
    tab.data_acquisizione, tab.stato_acquisizione, tab.importo_lordo,
    tab.arrotondamento_fel, tab.importo_netto, tab.codice_destinatario,
    tab.tipo_ritenuta, tab.aliquota_ritenuta, tab.importo_ritenuta,
    tab.anno_protocollo, tab.numero_protocollo, tab.registro_protocollo,
    tab.data_reg_protocollo, tab.modpag_cod, tab.modpag_desc, tab.aliquota_iva,
    tab.imponibile, tab.imposta, tab.arrotondamento_onere, tab.spese_accessorie,
    tab.doc_id, tab.anno_doc, tab.num_doc, tab.data_emissione_doc,
    tab.cod_tipo_doc, tab.cod_sogg_doc,
    tab.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    tab.data_scadenza_pagamento_pcc -- siac-6125 Sofia 23.05.2018
FROM ( WITH dati_sirfel AS (
    SELECT tf.ente_proprietario_id,
                    tp.codice_prestatore AS fornitore_cod,
                        CASE
                            WHEN tp.denominazione_prestatore IS NULL THEN
                                ((tp.nome_prestatore::text || ' '::text) || tp.cognome_prestatore::text)::character varying
                            ELSE tp.denominazione_prestatore
                        END AS fornitore_desc,
                    tf.data AS data_emissione, tpf.data_ricezione,
                    tf.numero AS numero_documento,
                    dtd.codice AS documento_fel_tipo_cod,
                    dtd.descrizione AS documento_fel_tipo_desc,
                    tf.data_caricamento AS data_acquisizione,
                        CASE
                            WHEN tf.stato_fattura = 'S'::bpchar THEN 'IMPORTATA'::text
                            ELSE
                            CASE
                                WHEN tf.stato_fattura = 'N'::bpchar THEN
                                    'DA ACQUISIRE'::text
                                ELSE 'SOSPESA'::text
                            END
                        END AS stato_acquisizione,
                    tf.importo_totale_documento AS importo_lordo,
                    tf.arrotondamento AS arrotondamento_fel,
                    tf.importo_totale_netto AS importo_netto,
                    tf.codice_destinatario, tf.tipo_ritenuta,
                    tf.aliquota_ritenuta, tf.importo_ritenuta,
                    tpro.anno_protocollo, tpro.numero_protocollo,
                    tpro.registro_protocollo, tpro.data_reg_protocollo,
                    tpagdett.modalita_pagamento AS modpag_cod,
                    dmodpag.descrizione AS modpag_desc, trb.aliquota_iva,
                    trb.imponibile_importo AS imponibile, trb.imposta,
                    trb.arrotondamento AS arrotondamento_onere,
                    trb.spese_accessorie, tf.id_fattura,
                    tpf.esito_stato_fattura esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
                    tpagdett.data_scadenza_pagamento data_scadenza_pagamento_pcc -- siac-6125 Sofia 23.05.2018
    FROM sirfel_t_fattura tf
              JOIN sirfel_t_prestatore tp ON tf.id_prestatore =
                  tp.id_prestatore AND tf.ente_proprietario_id = tp.ente_proprietario_id
         LEFT JOIN sirfel_t_portale_fatture tpf ON tf.id_fattura =
             tpf.id_fattura AND tf.ente_proprietario_id = tpf.ente_proprietario_id
    LEFT JOIN sirfel_d_tipo_documento dtd ON tf.tipo_documento::text =
        dtd.codice::text AND tf.ente_proprietario_id = dtd.ente_proprietario_id
   LEFT JOIN sirfel_t_riepilogo_beni trb ON tf.id_fattura = trb.id_fattura AND
       tf.ente_proprietario_id = trb.ente_proprietario_id
   LEFT JOIN sirfel_t_protocollo tpro ON tf.id_fattura = tpro.id_fattura AND
       tf.ente_proprietario_id = tpro.ente_proprietario_id
   LEFT JOIN sirfel_t_pagamento tpag ON tf.id_fattura = tpag.id_fattura AND
       tf.ente_proprietario_id = tpag.ente_proprietario_id
   LEFT JOIN sirfel_t_dettaglio_pagamento tpagdett ON tpag.id_fattura =
       tpagdett.id_fattura AND tpag.progressivo = tpagdett.progressivo_pagamento AND tpag.ente_proprietario_id = tpagdett.ente_proprietario_id
   LEFT JOIN sirfel_d_modalita_pagamento dmodpag ON
       tpagdett.modalita_pagamento::text = dmodpag.codice::text AND tpagdett.ente_proprietario_id = dmodpag.ente_proprietario_id
    ), dati_fattura AS (
    SELECT rdoc.ente_proprietario_id, rdoc.id_fattura, tdoc.doc_id,
                    tdoc.doc_anno AS anno_doc, tdoc.doc_numero AS num_doc,
                    tdoc.doc_data_emissione AS data_emissione_doc,
                    ddoctipo.doc_tipo_code AS cod_tipo_doc,
                    tsogg.soggetto_code AS cod_sogg_doc
    FROM siac_r_doc_sirfel rdoc
              JOIN siac_t_doc tdoc ON tdoc.doc_id = rdoc.doc_id
         JOIN siac_d_doc_tipo ddoctipo ON tdoc.doc_tipo_id = ddoctipo.doc_tipo_id
    LEFT JOIN siac_r_doc_sog rdocsog ON tdoc.doc_id = rdocsog.doc_id AND
        rdocsog.data_cancellazione IS NULL AND now() >= rdocsog.validita_inizio AND now() <= COALESCE(rdocsog.validita_fine::timestamp with time zone, now())
   LEFT JOIN siac_t_soggetto tsogg ON rdocsog.soggetto_id = tsogg.soggetto_id
       AND tsogg.data_cancellazione IS NULL
    WHERE rdoc.data_cancellazione IS NULL AND tdoc.data_cancellazione IS NULL
        AND now() >= rdoc.validita_inizio AND now() <= COALESCE(rdoc.validita_fine::timestamp with time zone, now())
    )
    SELECT dati_sirfel.ente_proprietario_id, dati_sirfel.fornitore_cod,
            dati_sirfel.fornitore_desc, dati_sirfel.data_emissione,
            dati_sirfel.data_ricezione, dati_sirfel.numero_documento,
            dati_sirfel.documento_fel_tipo_cod,
            dati_sirfel.documento_fel_tipo_desc, dati_sirfel.data_acquisizione,
            dati_sirfel.stato_acquisizione, dati_sirfel.importo_lordo,
            dati_sirfel.arrotondamento_fel, dati_sirfel.importo_netto,
            dati_sirfel.codice_destinatario, dati_sirfel.tipo_ritenuta,
            dati_sirfel.aliquota_ritenuta, dati_sirfel.importo_ritenuta,
            dati_sirfel.anno_protocollo, dati_sirfel.numero_protocollo,
            dati_sirfel.registro_protocollo, dati_sirfel.data_reg_protocollo,
            dati_sirfel.modpag_cod, dati_sirfel.modpag_desc,
            dati_sirfel.aliquota_iva, dati_sirfel.imponibile,
            dati_sirfel.imposta, dati_sirfel.arrotondamento_onere,
            dati_sirfel.spese_accessorie, dati_sirfel.id_fattura,
            dati_fattura.doc_id, dati_fattura.anno_doc, dati_fattura.num_doc,
            dati_fattura.data_emissione_doc, dati_fattura.cod_tipo_doc,
            dati_fattura.cod_sogg_doc,
            dati_sirfel.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
            dati_sirfel.data_scadenza_pagamento_pcc -- siac-6125 Sofia 23.05.2018
    FROM dati_sirfel
      LEFT JOIN dati_fattura ON dati_sirfel.id_fattura =
          dati_fattura.id_fattura AND dati_sirfel.ente_proprietario_id = dati_fattura.ente_proprietario_id
    ) tab;
	

-- siac-6125 - Sofia - FINE

-- siac-6137 - Sofia INIZIO

CREATE OR REPLACE FUNCTION fnc_mif_tipo_pagamento_splus( ordinativoId integer,
												   codicePaese varchar,
                                                   codiceItalia varchar,
                                                   codiceAreaSepa varchar,
                                                   codiceAreaExtraSepa varchar,
                                                   accreditoCodeCB varchar,
                                                   accreditoCodeREG varchar,
                                                   tipoPagamCompensa varchar,
 												   accreditoTipoId INTEGER,
                                                   accreditoGruppoCode varchar,
                                                   importoOrd       numeric,
                                                   pagamentoGFB     boolean,
                                                   dataElaborazione timestamp,
                                                   dataFineVal timestamp,
                                                   enteProprietarioId integer,
												   out codeTipoPagamento varchar,
                                                   out descTipoPagamento varchar,
                                                   out defRifDocEsterno boolean)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

isSepa boolean:=false;
isProvvisori boolean :=false;
isAllegatoCartaceo boolean :=false;
isCompensa boolean:=false;
codAreaSepa VARCHAR(50):=null;
accreditoTipoCode varchar(50):=null;
checkDati integer:=null;
accreditoCodeTes varchar(50):=null;
accreditoTipoOilId integer :=null;
accreditoCodePag varchar(50):=null;
accreditoDescPag varchar(200):=null;

ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

BEGIN

 codeTipoPagamento:=null;
 descTipoPagamento:=null;
 defRifDocEsterno:=false;



 -- codiceItalia valore presente in param
 -- codicePaese valorizzato se presente Iban
 -- codiceAreaSepa letto in param
 -- codiceAreaExtraSepa letto in param

-- raise notice 'ordinativoId=% ',ordinativoId;
-- raise notice 'codicePaese=% ',codicePaese;
-- raise notice 'codiceItalia=% ',codiceItalia;
-- raise notice 'codiceAreaSepa=% ',codiceAreaSepa;
-- raise notice 'codiceAreaExtraSepa=% ',codiceAreaExtraSepa;

 checkDati:=null;
 strMessaggio:='Lettura tipo pagamento ordinativo [siac_r_ordinativo_prov_cassa].';
 select distinct 1 into checkDati
 from siac_r_ordinativo_prov_cassa prov
 where prov.ord_id=ordinativoId
 and   prov.data_cancellazione is null
 and   prov.validita_fine is null;

 if checkDati is not null then
    	isProvvisori  :=true;
 end if;

 if isProvvisori = false then
  checkDati:=null;
  strMessaggio:='Verifica ordinativo compensazione.';
  select 1 into checkDati
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel
  where rord.ord_id_da=ordinativoId
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
--  group by ord.ord_id
  group by rord.ord_id_da -- 20.12.2017 Sofia jira siac-5665
  having coalesce(sum(det.ord_ts_det_importo),0)=importoOrd
  limit 1;

  if checkDati is not null then
    strMessaggio:='Lettura tipo pamento compensazione.';
  	select oil.accredito_tipo_oil_code ,oil.accredito_tipo_oil_desc
           into accreditoCodePag,accreditoDescPag
    from siac_d_accredito_tipo_oil oil
    where oil.ente_proprietario_id=enteProprietarioId
    and   oil.accredito_tipo_oil_desc=tipoPagamCompensa
    and   oil.data_cancellazione is null
    and   oil.validita_fine is null;
    if accreditoCodePag is not null  then
    	isCompensa:=true;
    end if;
  end if;
 end if;

 if isProvvisori = false and isCompensa=false then
 	if codicePaese='' or codicePaese is null then
     -- 14.02.2018 Sofia siac-5874
     checkDati:=null;
     strMessaggio:='Lettura gruppo tipo pagamento '||accreditoCodeCB||'.';
	 select 1 into checkDati
     from siac_d_accredito_gruppo gruppo, siac_d_accredito_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.accredito_tipo_code=accreditoCodeCB
     and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
     and   gruppo.accredito_gruppo_code=accreditoGruppoCode
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

 	 -- se il codice paese='' or codicepaese is null
 	 -- cerco il gruppo da accredito_tipo_id
	 -- se e' CB allora forzo paese=' '
--     if accreditoGruppoCode=accreditoCodeCB then
     -- 14.02.2018 Sofia siac-5874
     if checkDati is not null then
     	codicePaese=' '; -- forzato per cercare CB extrasepa
     end if;

    end if;
 end if;


 if isProvvisori=false and  isCompensa=false and
    codicePaese is not null and codicePaese!=codiceItalia then
    strMessaggio:='Lettura tipo pagamento ordinativo [siac_t_sepa].';
    checkDati:=null; -- 14.02.2018 Sofia siac-5874
 	select distinct 1 into checkDati
    from siac_t_sepa sepa
    where sepa.sepa_iso_code=codicePaese
    and   sepa.ente_proprietario_id=enteProprietarioId
    and   sepa.data_cancellazione is null
 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));

    if checkDati is not null then
    	isSepa:=true;
    end if;
 end if;

 if isProvvisori=true THEN
 	-- lettura tabella di decodifica REG ( valore presente in param )
    accreditoCodeTes:=accreditoCodeREG;
 end if;


 checkDati:=null;
 strMessaggio:='Lettura tipo pagamento ordinativo [siac_r_ordinativo_attr].';
 select 1 into checkDati
 from siac_r_ordinativo_attr rattr, siac_t_attr attr
 where rattr.ord_id=ordinativoId
 and   rattr.boolean='S'
 and   rattr.data_cancellazione is null
 and   rattr.validita_fine is null
 and   attr.attr_id=rattr.attr_id
 and   attr.attr_code=ALLEG_CART_ATTR
 and   attr.data_cancellazione is null
 and   attr.validita_fine is null;

 if checkDati is not null then
  	isAllegatoCartaceo  :=true;
 end if;

 strMessaggio:='Lettura tipo pagamento ordinativo.';
 -- raise notice 'isProvvisori=% ',isProvvisori;
 -- raise notice 'isSepa=% ',isSepa;


 if isProvvisori=false and isCompensa=false  and
    codicePaese is not  null and  codicePaese!=codiceItalia  then
    accreditoCodeTes:=accreditoCodeCB;
 	if isSepa=true then
	 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=SEPA
    	codAreaSepa:=codiceAreaSepa;
    else
	 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=EXTRASEPA
	    codAreaSepa:=codiceAreaExtraSepa;
        isAllegatoCartaceo  :=true; -- bonifico estero extra-sepa forzato a true
    end if;

 end if;

 if  isCompensa=false  then

  if isProvvisori=false and -- 13.12.2017 Sofia siac-5654
     (accreditoCodeTes is null or  pagamentoGFB = true ) then
     accreditoTipoOilId:=accreditoTipoId;
     if pagamentoGFB=true then
    	codAreaSepa:=null;
     end if;
  else -- caso ordinativo a copertura==con provvisori  di cassa collegati

     -- 08.05.2018 Sofia siac-6137 - leggo l'accredito tipo di ordinativo che sia del tipo REGOLARIZZAZIONE - se si lo uso
     -- diversamente imposto REGOLARIZZAZIONE COME PRIMA
     -- lettura di accredito_tipo_id per lettura in accredito_tipo
	 strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo] accredito_tipo_desc like '||accreditoCodeTes||'.';


     select tipo.accredito_tipo_id into accreditoTipoOilId
 	 from siac_d_accredito_tipo tipo
	 where tipo.accredito_tipo_id=accreditoTipoId
     and   tipo.accredito_tipo_desc like accreditoCodeTes||'%'
	 and   tipo.data_cancellazione is null
	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

     -- 08.05.2018 Sofia siac-6137
     if accreditoTipoOilId is null then
        -- lettura di accredito_tipo_id per lettura in accredito_tipo x REG
		strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo] accredito_tipo_code='||accreditoCodeTes||'.';
		select tipo.accredito_tipo_id into accreditoTipoOilId
		from siac_d_accredito_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.accredito_tipo_code=accreditoCodeTes
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
     end if;

	 if accreditoTipoOilId is null then
 		RAISE EXCEPTION ' Accredito tipo non trovato.';
	 end if;
  end if;

 end if;

 if  isCompensa=false  then

  -- lettura di accredito_tipo_id per lettura in accredito_tipo_oil
  strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo_oil].';
  select oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc into accreditoCodePag,accreditoDescPag
  from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil raccre
  where raccre.accredito_tipo_id=accreditoTipoOilId
  and   raccre.data_cancellazione is null
  and   raccre.validita_fine is null
  and   oil.accredito_tipo_oil_id=raccre.accredito_tipo_oil_id
  and   coalesce(oil.accredito_tipo_oil_area,'IT')=coalesce(codAreaSepa,'IT')
  and   oil.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',oil.validita_inizio)
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(oil.validita_fine,dataElaborazione));
 end if;



 codeTipoPagamento:=accreditoCodePag;
 descTipoPagamento:=accreditoDescPag;
 defRifDocEsterno:= isAllegatoCartaceo;
--  raise notice 'accreditoCodePag=% ',accreditoCodePag;
--  raise notice 'descTipoPagamento=% ',accreditoDescPag;


 return;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- siac-6137 - Sofia Fine

-- SIAC-6076 - INIZIO

INSERT INTO siac_t_attr (attr_code, attr_desc, attr_tipo_id, tabella_nome, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.attr_tipo_id, null, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_attr_tipo dat ON dat.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES('firma1', 'firma1')) AS tmp(code, descr)
WHERE tep.data_cancellazione IS NULL
AND dat.attr_tipo_code = 'X'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_attr ta
	WHERE ta.attr_tipo_id = dat.attr_tipo_id
	AND ta.ente_proprietario_id = tep.ente_proprietario_id
	AND ta.attr_code = tmp.code
);


INSERT INTO siac_t_attr (attr_code, attr_desc, attr_tipo_id, tabella_nome, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.attr_tipo_id, null, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_attr_tipo dat ON dat.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES('firma2', 'firma2')) AS tmp(code, descr)
WHERE tep.data_cancellazione IS NULL
AND dat.attr_tipo_code = 'X'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_attr ta
	WHERE ta.attr_tipo_id = dat.attr_tipo_id
	AND ta.ente_proprietario_id = tep.ente_proprietario_id
	AND ta.attr_code = tmp.code
);

INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('FIRMA_CARTA_1', 'Intestazione firma uno')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('Il dirigente del settore ragioneria', 'Il dirigente del settore ragioneria', 'FIRMA_CARTA_1')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgl.gestione_livello_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('FIRMA_CARTA_2', 'Intestazione firma due')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('Il responsabile della direzione', 'Il responsabile della direzione', 'FIRMA_CARTA_2')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgl.gestione_livello_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

-- SIAC-6076 - FINE