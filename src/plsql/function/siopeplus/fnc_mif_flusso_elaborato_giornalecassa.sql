/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_giornalecassa
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

	-- costante tipo flusso presenti nella mif_d_flusso_elaborato_tipo
    -- valori di parametro tipoFlussoMif devono essere presenti in mif_d_flusso_elaborato_tipo
    GIOCASSA_ELAB_FLUSSO_TIPO    CONSTANT  varchar :='GIOCASSA';    -- giornale di cassa

    -- costante tipo flusso presenti nei flussi e in siac_d_ricevuta_tipo
    QUIET_MIF_FLUSSO_TIPO   CONSTANT  varchar :='R';    -- quietanze e storni
    FIRME_MIF_FLUSSO_TIPO   CONSTANT  varchar :='S';    -- firme
    PROVC_MIF_FLUSSO_TIPO   CONSTANT  varchar :='P';    -- provvisori

    -- costante tipo ricevuta presente in siac_d_ricevuta_tipo
    QUIET_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='Q';    -- quietanze
    STORNI_MIF_FLUSSO_TIPO_CODE  CONSTANT  varchar :='S';    -- storni
    PROVC_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='P';    -- provvisori
    PROVC_ST_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='PS';    -- storno provvisori



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

	-- scarto di dettaglio
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


	flussoMifTipoId integer:=null;
    tipoFlusso VARCHAR(200):=null;
    dataOraFlusso VARCHAR(200):=null;
    codiceAbiBt VARCHAR(200):=null;
    codiceEnteBt VARCHAR(200):=null;

    oilRicevutaTipoId integer:=null;

    enteOilRec record;
    ricevutaRec record;
	recQuiet record;
  	recProv record;

    codResult integer :=null;
    codErrore varchar(10) :=null;


	countOrdAgg numeric:=0;
  	countProvAgg numeric:=0;
BEGIN

	strMessaggioFinale:='Elaborazione flusso giornale di cassa tipo flusso='||tipoFlussoMif||'.Identificativo flusso='||flussoElabMifId||'.';

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
    and   tipoFlussoMif=GIOCASSA_ELAB_FLUSSO_TIPO;

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


	-- verifca esistenza mif_t_elab_giornalecassa ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_giornalecassa].';
    select distinct 1  into codResult
    from  mif_t_elab_giornalecassa m, mif_t_flusso_elaborato mif
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



	-- verifca esistenza mif_t_giornalecassa
    strMessaggio:='Verifica esistenza record da elaborare [mif_t_giornalecassa].';
    select distinct 1  into codResult
    from  mif_t_giornalecassa m
    where m.flusso_elab_mif_id=flussoElabMifId
    and   m.ente_proprietario_id=enteProprietarioId;

    if codResult is null then
        -- SIAC-5765 pto 18.D)
        -- chiudere elaborazione
        -- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
        strMessaggio:='Elaborazione flusso giornale di cassa.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId
                      ||'.Nessun record da elaborare.';
        update  mif_t_flusso_elaborato
        set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
            ('OK',
             'ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '
             ||GIOCASSA_ELAB_FLUSSO_TIPO
             ||'. NESSUN RECORD DA ELABORARE.',
             countOrdAgg+countProvAgg,clock_timestamp())
        where flusso_elab_mif_id=flussoElabMifId;

    --    messaggioRisultato:=strMessaggioFinale||' Elaborazione conclusa OK.';
        messaggioRisultato:=strMessaggio;
        messaggioRisultato:=upper(messaggioRisultato);
        countOrdAggRisultato:=countOrdAgg+countProvAgg;

        return;
--    	raise exception ' Nessun record da elaborare.';
    end if;

    -- inserimento mif_t_elab_giornalecassa
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_giornalecassa da mif_t_giornalecassa].';
    insert into mif_t_elab_giornalecassa
    (
     mif_t_giornalecassa_id,
	 flusso_elab_mif_id,
	 codice_abi_bt,
	 identificativo_flusso,
	 data_ora_creazione_flusso,
	 data_inizio_periodo_riferimento,
	 data_fine_periodo_riferimento,
	 codice_ente,
	 descrizione_ente,
	 codice_ente_bt,
	 esercizio,
	 conto_evidenza,
	 descrizione_conto_evidenza,
	 tipo_movimento,
	 tipo_documento,
	 tipo_operazione,
	 numero_documento,
	 progressivo_documento,
	 importo,
	 numero_bolletta_quietanza,
	 numero_bolletta_quietanza_storno,
	 data_movimento,
	 data_valuta_ente,
	 tipo_esecuzione,
	 coordinate,
	 codice_riferimento_operazione,
	 codice_riferimento_interno,
	 tipo_contabilita,
	 destinazione,
	 assoggettamento_bollo,
	 importo_bollo,
	 assoggettamento_spese,
	 importo_spese,
	 anagrafica_cliente,
	 indirizzo_cliente,
	 cap_cliente,
	 localita_cliente,
	 codice_fiscale_cliente,
	 provincia_cliente,
	 partita_iva_cliente,
	 anagrafica_delegato,
	 indirizzo_delegato,
	 cap_delegato,
	 localita_delegato,
	 provincia_delegato,
	 codice_fiscale_delegato,
	 causale,
	 numero_sospeso,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select
     mif.mif_t_giornalecassa_id,
	 mif.flusso_elab_mif_id,
	 mif.codice_abi_bt,
	 mif.identificativo_flusso,
	 mif.data_ora_creazione_flusso,
	 mif.data_inizio_periodo_riferimento,
	 mif.data_fine_periodo_riferimento,
	 mif.codice_ente,
	 mif.descrizione_ente,
	 mif.codice_ente_bt,
	 mif.esercizio,
	 mif.conto_evidenza,
	 mif.descrizione_conto_evidenza,
	 mif.tipo_movimento,
	 mif.tipo_documento,
	 mif.tipo_operazione,
	 mif.numero_documento,
	 mif.progressivo_documento,
	 abs(mif.importo::numeric),
	 mif.numero_bolletta_quietanza,
	 mif.numero_bolletta_quietanza_storno,
	 mif.data_movimento,
	 mif.data_valuta_ente,
	 mif.tipo_esecuzione,
	 mif.coordinate,
	 mif.codice_riferimento_operazione,
	 mif.codice_riferimento_interno,
	 mif.tipo_contabilita,
	 mif.destinazione,
	 mif.assoggettamento_bollo,
	 abs(mif.importo_bollo::numeric),
	 mif.assoggettamento_spese,
	 abs(mif.importo_spese::numeric),
	 mif.anagrafica_cliente,
	 mif.indirizzo_cliente,
	 mif.cap_cliente,
	 mif.localita_cliente,
	 mif.codice_fiscale_cliente,
	 mif.provincia_cliente,
	 mif.partita_iva_cliente,
	 mif.anagrafica_delegato,
	 mif.indirizzo_delegato,
	 mif.cap_delegato,
	 mif.localita_delegato,
	 mif.provincia_delegato,
	 mif.codice_fiscale_delegato,
	 mif.causale,
	 mif.numero_sospeso,
     clock_timestamp(),
     loginOperazione,
     enteProprietarioId
     from mif_t_giornalecassa mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );


	-- letture enteOIL
    strMessaggio:='Lettura dati ente OIL.';
    select * into strict enteOilRec
    from siac_t_ente_oil
    where ente_proprietario_id=enteProprietarioId;
    codiceAbiBt:=enteOilRec.ente_oil_abi;
    codiceEnteBt:=enteOilRec.ente_oil_codice;

	-- lettura tipoRicevuta
    strMessaggio:='Lettura tipo ricevuta '||QUIET_MIF_FLUSSO_TIPO_CODE||'.';
	select tipo.oil_ricevuta_tipo_id
           into strict oilRicevutaTipoId
    from siac_d_oil_ricevuta_tipo tipo
    where tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;




	-- controlli di integrita flusso

	strMessaggio:='Verifica integrita'' flusso. Codifiche ente.';
    codResult:=null;
    select mif.mif_t_giornalecassa_id into codResult
    from mif_t_elab_giornalecassa  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.codice_abi_bt=codiceAbiBt
    and   mif.codice_ente_bt=codiceEnteBt
    limit 1;

    if codResult is null then
		codErrore:=MIF_DATI_ENTE_TESTA_COD_ERR;
    end if;

	if codErrore is not null then
	    raise exception ' COD.ERRORE=%',codErrore;
    end if;




    -- inserimento in mif_t_ricevuta_oil scarti

    -- MIF_RR_DATI_ENTE_COD_ERR dati ente  non valorizzati o errati
    strMessaggio:='Verifica esistenza record ricevuta  dati ente non valorizzati o errati.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_bolletta_quietanza,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            rr.importo,rr.esercizio,rr.numero_documento,
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   ( rr.codice_abi_bt is null or rr.codice_abi_bt='' or rr.codice_abi_bt!=codiceAbiBt or
             rr.codice_ente_bt is null or rr.codice_ente_bt='' or rr.codice_ente_bt!=codiceEnteBt)
     and errore.oil_ricevuta_errore_code=MIF_RR_DATI_ENTE_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


     -- tipo_movimento +
     -- tipo_documento+tipo_operazione => QUALIFICATORE
     --- da qualificatore trovo esito derivato
     -- quindi tipo_movimento, tipo_documento, tipo_operazione devono essere valorizzati

     -- MIF_RR_QUALIFICATORE_COD_ERR qualificatore non valorizzato
     strMessaggio:='Verifica esistenza record ricevuta dati qualificatore non valorizzati.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_bolletta_quietanza,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.tipo_movimento is null or rr.tipo_movimento=''    -- tipo_movimento ENTRATA-USCITA
          or rr.tipo_documento is null or rr.tipo_documento=''    -- tipo_documento MANDATO-REVERSALE-SOSPESO USCITA-SOSPESO ENTRATA
          or rr.tipo_operazione is null or rr.tipo_operazione='') -- tipo_operazione ESEGUITO-STORNATO-REGOLARIZZATO-RIPRISTINATO
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- MIF_RR_QUALIFICATORE_COD_ERR qualificatore non ammesso
     strMessaggio:='Verifica esistenza record ricevuta dati qualificatore non ammesso.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_bolletta_quietanza,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             abs(rr.importo),rr.esercizio,rr.numero_documento::integer,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.tipo_movimento is not null and rr.tipo_movimento!=''    -- tipo_movimento ENTRATA-USCITA
         and rr.tipo_documento is not null and rr.tipo_documento!=''    -- tipo_documento MANDATO-REVERSALE-SOSPESO USCITA-SOSPESO ENTRATA
         and rr.tipo_operazione is not null and rr.tipo_operazione!='' )-- tipo_operazione ESEGUITO-STORNATO-REGOLARIZZATO-RIPRISTINATO
      and   not exists ( select distinct 1
                         from siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
                         where q.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
                         and   q.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
                         and   q.ente_proprietario_id=enteProprietarioId
                         and   e.oil_esito_derivato_id=q.oil_esito_derivato_id
                         and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	                     and   tipo.oil_ricevuta_tipo_code in
                               (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE,
                                PROVC_MIF_FLUSSO_TIPO_CODE,PROVC_ST_MIF_FLUSSO_TIPO_CODE)
      				   )
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

    -- chiamate fnc per tipo_ricevuta :  gestione scarti e cicli elaborazione
    strMessaggio:='Gestione elaborazione quietanze-storni.';
    -- esecuzione
    -- fnc_mif_flusso_elaborato_giornalecassa_quiet
    select * into recQuiet
    from  fnc_mif_flusso_elaborato_giornalecassa_quiet
		  ( enteProprietarioId,
		    annoBilancio,
	        nomeEnte,
	        tipoFlussoMif,
		    flussoElabMifId,
			enteOilRec.ente_oil_firme_ord,
			loginOperazione,
			dataElaborazione
          );
    if recQuiet.codiceRisultato!= 0 then
    	codErrore:=-1;
        raise exception ' % ', recQuiet.messaggioRisultato;
    else
     countOrdAgg:=coalesce(recQuiet.countOrdAggRisultato,0);
    end if;

    strMessaggio:='Gestione elaborazione provviosori di cassa-storni.';
    -- esecuzione
    -- fnc_mif_flusso_elaborato_giornalecassa_prov
	select * into recProv
    from  fnc_mif_flusso_elaborato_giornalecassa_prov
		  ( enteProprietarioId,
		    annoBilancio,
	        nomeEnte,
	        tipoFlussoMif,
		    flussoElabMifId,
			loginOperazione,
			dataElaborazione
          );
    if recProv.codiceRisultato!= 0 then
       	codErrore:=-1;
        raise exception ' % ', recProv.messaggioRisultato;
    else
     countProvAgg:=coalesce(recProv.countOrdAggRisultato,0);
    end if;

    -- inserimento scarti in siac_t_oil_ricevuta
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
       clock_timestamp(),
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
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;


    -- chiudere elaborazione
	-- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
    strMessaggio:='Elaborazione flusso giornale di cassa.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId
                  ||'.Aggiornati ordinativi num='||countOrdAgg
                  ||'.Aggiornati provvisori di cassa num='||countProvAgg
                  ||'.';
    update  mif_t_flusso_elaborato
    set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
   	    ('OK',
         'ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '
         ||GIOCASSA_ELAB_FLUSSO_TIPO
         ||'. AGGIORNATI NUM='||countOrdAgg||' ORDINATIVI'
         ||'. AGGIORNATI NUM='||countProvAgg||' PROVVISORI.',
         countOrdAgg+countProvAgg,clock_timestamp())
    where flusso_elab_mif_id=flussoElabMifId;

--    messaggioRisultato:=strMessaggioFinale||' Elaborazione conclusa OK.';
    messaggioRisultato:=strMessaggio;
    messaggioRisultato:=upper(messaggioRisultato);
    countOrdAggRisultato:=countOrdAgg+countProvAgg;

    return;

exception
    when RAISE_EXCEPTION THEN
		if codErrore is null then
         messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'') ;
        else
        	messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'') ;
        end if;
     	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

  		-- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	   	delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;

   --     if codErrore is not null then
        	update  mif_t_flusso_elaborato
    		set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  		('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
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
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;

		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
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
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;


		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
		where flusso_elab_mif_id=flussoElabMifId;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;

        update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
		where flusso_elab_mif_id=flussoElabMifId;

        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;