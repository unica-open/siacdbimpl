/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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