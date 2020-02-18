/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_giornalecassa_quiet
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  flussoElabMifId integer,
  enteOilFirmeOrd boolean,
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

    ordTipoSpesaId integer:=null;
    ordTipoEntrataId integer:=null;

	ordTsDetTipoId integer:=null;
	ordStatoFirmaId integer:=null;
    ordStatoTrasmId integer:=null;
    ordStatoQuietId integer:=null;
    ordStatoAnnullatoId integer:=null;

	countOrdAgg numeric:=0;

    ricevutaRec record;


    ORD_STATO_QUIET CONSTANT varchar:='Q';
    ORD_STATO_FIRMA CONSTANT varchar:='F';
    ORD_STATO_TRASM CONSTANT varchar:='T';
    ORD_STATO_ANNULLATO CONSTANT varchar:='A';

    -- ordinativi
    ORD_TIPO_SPESA CONSTANT varchar :='P';
    ORD_TIPO_ENTRATA CONSTANT varchar :='I';

	ORD_TS_DET_TIPO_A   CONSTANT varchar:='A';

    QUIET_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='Q';    -- quietanze
    STORNI_MIF_FLUSSO_TIPO_CODE  CONSTANT  varchar :='S';    -- storni


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

	MIF_NUM_RICEVUTA_DEF        CONSTANT integer:=999999; -- 24.01.2018 Sofia siac-576
BEGIN

    codiceRisultato:=0;
    countOrdAggRisultato:=0;
    messaggioRisultato:='';


    strMessaggioFinale:='Ciclo elaborazione quietanze-storni.';


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


   	-- lettura ordStatoAnnullatoId
    strMessaggio:='Lettura Id stato ordinativo='||ORD_STATO_ANNULLATO||'.';
    select stato.ord_stato_id into strict ordStatoAnnullatoId
    from siac_d_ordinativo_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and stato.ord_stato_code=ORD_STATO_ANNULLATO;

    -- gestione scarti -- INIZIO
	-- MIF_RR_DATI_ORD_COD_ERR dati ordinativo non indicati
    strMessaggio:='Verifica esistenza record ricevuta dati ordinativo non indicati - quietanza-storno.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             		      else rr.numero_bolletta_quietanza_storno end),
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            rr.importo,rr.esercizio,rr.numero_documento,
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
     and   ( rr.esercizio is null or rr.esercizio=0 or
	         rr.numero_documento is null or  rr.numero_documento=0 or
             rr.data_movimento is null or rr.data_movimento='')
     and errore.oil_ricevuta_errore_code=MIF_RR_DATI_ORD_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


	-- MIF_RR_ANNO_ORD_COD_ERR anno ordinativo non corretto
    strMessaggio:='Verifica esistenza record ricevuta anno ordinativo non corretto rispetto all''anno di bilancio corrente.';
    insert into mif_t_oil_ricevuta
    (  oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
         				  else rr.numero_bolletta_quietanza_storno end),
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            rr.importo,rr.esercizio,rr.numero_documento,
            clock_timestamp(),loginOperazione,enteProprietarioId
     from   mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
     and   rr.esercizio > annoBilancio
     and   errore.oil_ricevuta_errore_code=MIF_RR_ANNO_ORD_COD_ERR::varchar
     and   errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


     -- esistenza ordinativo e annullamento
     -- MIF_RR_ORD_COD_ERR dati ordinativo non esistente
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di spesa non esistente - quietanza-storno.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from   mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
      where  rr.flusso_elab_mif_id=flussoElabMifId
      and    qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and    qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and    qual.oil_qualificatore_segno='U'
      and    qual.ente_proprietario_id=enteProprietarioId
      and    esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and    tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and    tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and    errore.oil_ricevuta_errore_code=MIF_RR_ORD_COD_ERR::varchar
      and    errore.ente_proprietario_id=enteProprietarioId
      and    not exists ( select distinct 1
                          from  siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per
                          where ord.ente_proprietario_id=enteProprietarioId
                          and   ord.ord_numero::integer=rr.numero_documento
                          and   ord.ord_tipo_id=ordTipoSpesaId
                          and   bil.bil_id=ord.bil_id
                          and   per.periodo_id=bil.periodo_id
                          and   per.anno::integer=rr.esercizio
                        )
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
      				  where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di entrata non esistente - quietanza-storno.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
      where  rr.flusso_elab_mif_id=flussoElabMifId
      and    qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and    qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and    qual.oil_qualificatore_segno='E'
      and    qual.ente_proprietario_id=enteProprietarioId
      and    esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and    tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and    tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and    errore.oil_ricevuta_errore_code=MIF_RR_ORD_COD_ERR::varchar
      and    errore.ente_proprietario_id=enteProprietarioId
      and    not exists ( select distinct 1
                          from  siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per
                          where ord.ente_proprietario_id=enteProprietarioId
                          and   ord.ord_numero::integer=rr.numero_documento
                          and   ord.ord_tipo_id=ordTipoEntrataId
                          and   bil.bil_id=ord.bil_id
                          and   per.periodo_id=bil.periodo_id
                          and   per.anno::integer=rr.esercizio
                        )
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


     -- MIF_RR_ORD_ANNULL_COD_ERR dati ordinativo annullato
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di spesa annullato - quietanza-storno.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_annullamento,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,
             rr.esercizio,rr.numero_documento,
             bil.bil_id,ord.ord_id,
             stato.validita_inizio,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_stato stato
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='U'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_ANNULL_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
      and   stato.ord_id=ord.ord_id
      and   stato.ord_stato_id=ordStatoAnnullatoId
      and   stato.data_cancellazione is null
      and   stato.validita_fine is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di entrata annullato - quietanza-storno.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_annullamento,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             bil.bil_id,ord.ord_id,
             stato.validita_inizio,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_stato stato
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='E'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_ANNULL_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
      and   stato.ord_id=ord.ord_id
      and   stato.ord_stato_id=ordStatoAnnullatoId
      and   stato.data_cancellazione is null
      and   stato.validita_fine is null
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


     -- data_emissione ordinativo  successiva data_pagamento
     -- MIF_RR_ORD_DT_EMIS_COD_ERR data_emissione ordinativo  successiva data_pagamento
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di spesa emesso in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_emissione,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,
             rr.esercizio,rr.numero_documento,
             bil.bil_id,ord.ord_id,
             ord.ord_emissione_data,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='U'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
--      and   ord.ord_emissione_data>rr.data_movimento::timestamp -- capire come convertire
      and   date_trunc('DAY',ord.ord_emissione_data)>rr.data_movimento::timestamp -- 24.01.2018 Sofia siac-5765
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_EMIS_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
                        and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

	 -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di entrata emesso in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_emissione,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             bil.bil_id,ord.ord_id,
             ord.ord_emissione_data,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord, siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='E'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
--      and   ord.ord_emissione_data>rr.data_movimento::timestamp -- capire come convertire
      and   date_trunc('DAY',ord.ord_emissione_data)>rr.data_movimento::timestamp -- 24.01.2018 Sofia siac-5765
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_EMIS_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
                        and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- data_trasmissione ordinativo non valorizzata o  successiva data_pagamento
     -- MIF_RR_ORD_DT_TRASM_COD_ERR data_emissione ordinativo  successiva data_pagamento
     -- [ordinativo spesa]
     strMessaggio:='Verifica esistenza record ricevuta  ordinativo di spesa non trasmesso o in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             bil.bil_id,ord.ord_id,
             ord.ord_emissione_data,
             ord.ord_trasm_oil_data,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='U'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
      and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
      and   ( ord.ord_trasm_oil_data is null or
              date_trunc('DAY',ord.ord_trasm_oil_data)>date_trunc('DAY',rr.data_movimento::timestamp) )
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_TRASM_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

	 -- [ordinativo entrata]
     strMessaggio:='Verifica esistenza record ricevuta ordinativo di entrata non trasmesso o in data successiva alla data di quietanza.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             bil.bil_id,ord.ord_id,
             ord.ord_emissione_data,
             ord.ord_trasm_oil_data,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='E'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
      and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
      and   ord.ord_tipo_id=ordTipoEntrataId
      and   bil.bil_id=ord.bil_id
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
      and   ( ord.ord_trasm_oil_data is null or
              date_trunc('DAY',ord.ord_trasm_oil_data)>date_trunc('DAY',rr.data_movimento::timestamp) )
      and errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_TRASM_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


	if enteOilFirmeOrd=true then

	    -- MIF_RR_ORD_DT_FIRMA_COD_ERR ordinativo  firmato successivamente alla data di quietanza
    	-- [ordinativo spesa]
	    strMessaggio:='Verifica esistenza record ricevuta ordinativo di spesa firmato successivamente alla data di quietanza.';
    	insert into mif_t_oil_ricevuta
	    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
	      flusso_elab_mif_id, oil_progr_ricevuta_id,
    	  oil_ricevuta_anno,oil_ricevuta_numero,
	      oil_ricevuta_data,oil_ricevuta_tipo,
    	  oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
          oil_ord_bil_id, oil_ord_id,
	      oil_ord_data_emissione,
    	  oil_ord_trasm_oil_data,
	      oil_ord_data_firma,
    	  validita_inizio,
	      login_operazione,
    	  ente_proprietario_id
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
	            flussoElabMifId,rr.mif_t_giornalecassa_id,
     	        rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
        	    rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
	            rr.importo,rr.esercizio,rr.numero_documento,
                bil.bil_id,ord.ord_id,
    	        ord.ord_emissione_data,
        	    ord.ord_trasm_oil_data,
            	firma.ord_firma_data,
                clock_timestamp(),loginOperazione,enteProprietarioId
	      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
                siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
        	    siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per,
                siac_r_ordinativo_firma firma
	      where rr.flusso_elab_mif_id=flussoElabMifId
	      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
    	  and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
	      and   qual.oil_qualificatore_segno='U'
    	  and   qual.ente_proprietario_id=enteProprietarioId
	      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
    	  and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
	      and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	  and   ord.ente_proprietario_id=enteProprietarioId
	      and   ord.ord_numero::integer=rr.numero_documento
    	  and   ord.ord_tipo_id=ordTipoSpesaId
	      and   bil.bil_id=ord.bil_id
    	  and   per.periodo_id=bil.periodo_id
	      and   per.anno::integer=rr.esercizio
          and   firma.ord_id=ord.ord_id
          and   date_trunc('DAY',firma.ord_firma_data)>date_trunc('DAY',rr.data_movimento::timestamp)
          and   firma.data_cancellazione is null
          and   firma.validita_fine is null
	      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_FIRMA_COD_ERR::varchar
    	  and   errore.ente_proprietario_id=enteProprietarioId
	      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

          -- [ordinativo entrata]
	      strMessaggio:='Verifica esistenza record ricevuta ordinativo di entrata firmato successivamente alla data di quietanza.';
    	  insert into mif_t_oil_ricevuta
	      ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
	     	flusso_elab_mif_id, oil_progr_ricevuta_id,
		    oil_ricevuta_anno,oil_ricevuta_numero,
	        oil_ricevuta_data,oil_ricevuta_tipo,
	    	oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
            oil_ord_bil_id, oil_ord_id,
		    oil_ord_data_emissione,
	     	oil_ord_trasm_oil_data,
		    oil_ord_data_firma,
	    	validita_inizio,
	        login_operazione,
    	    ente_proprietario_id
	      )
    	  (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
	              flussoElabMifId,rr.mif_t_giornalecassa_id,
     	          rr.esercizio,(case when tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE then rr.numero_bolletta_quietanza
             				    else rr.numero_bolletta_quietanza_storno end),
        	      rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
	              rr.importo,rr.esercizio,rr.numero_documento,
                  bil.bil_id,ord.ord_id,
    	          ord.ord_emissione_data,
        	      ord.ord_trasm_oil_data,
            	  firma.ord_firma_data,
                  clock_timestamp(),loginOperazione,enteProprietarioId
 	       from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
                 siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
        	     siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per,
                 siac_r_ordinativo_firma firma
 	       where rr.flusso_elab_mif_id=flussoElabMifId
	       and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
    	   and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
	       and   qual.oil_qualificatore_segno='E'
    	   and   qual.ente_proprietario_id=enteProprietarioId
	       and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
    	   and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
	       and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE)
    	   and   ord.ente_proprietario_id=enteProprietarioId
	       and   ord.ord_numero::integer=rr.numero_documento
    	   and   ord.ord_tipo_id=ordTipoEntrataId
	       and   bil.bil_id=ord.bil_id
    	   and   per.periodo_id=bil.periodo_id
	       and   per.anno::integer=rr.esercizio
           and   firma.ord_id=ord.ord_id
           and   date_trunc('DAY',firma.ord_firma_data)>date_trunc('DAY',rr.data_movimento::timestamp)
           and   firma.data_cancellazione is null
           and   firma.validita_fine is null
	       and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_DT_FIRMA_COD_ERR::varchar
    	   and   errore.ente_proprietario_id=enteProprietarioId
	       and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                  where rr1.flusso_elab_mif_id=flussoElabMifId
         	              and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

    end if;


	-- MIF_DR_ORD_NUM_RIC_COD_ERR esistenza di dettagli di quietanza senza numero quietanza o importo o data
    -- [ricevute di  spesa]
	strMessaggio:='Verifica esistenza record dettaglio ricevuta spesa con dati quietanza non valorizzati.';
    insert into mif_t_oil_ricevuta
	(oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
     flusso_elab_mif_id, oil_progr_ricevuta_id,
     oil_ricevuta_anno,oil_ricevuta_numero,
     oil_ricevuta_data,oil_ricevuta_tipo,
     oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
     oil_ord_bil_id, oil_ord_id,
     oil_ord_data_emissione,
     oil_ord_trasm_oil_data,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
	)
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_bolletta_quietanza,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            rr.importo,rr.esercizio,rr.numero_documento,
            bil.bil_id,ord.ord_id,
            ord.ord_emissione_data,
            ord.ord_trasm_oil_data,
            clock_timestamp(),loginOperazione,enteProprietarioId
	  from   mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
             siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	  where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	  and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='U'
	  and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	  and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code = QUIET_MIF_FLUSSO_TIPO_CODE
	  and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
	  and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
	  and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
      and   ( --rr.numero_bolletta_quietanza is null or rr.numero_bolletta_quietanza=0 or 24.01.2018 Sofia SIAC-5765
           	  rr.data_movimento is null or rr.data_movimento='' or
              rr.importo is null or rr.importo=0
             )
	  and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_NUM_RIC_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
       	                and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

	  -- MIF_DR_ORD_NUM_RIC_COD_ERR esistenza di dettagli di quietanza senza numero quietanza o importo o data
      strMessaggio:='Verifica esistenza record dettaglio ricevuta spesa con dati storno quietanza non valorizzati.';
      insert into mif_t_oil_ricevuta
	  (oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       oil_ord_bil_id, oil_ord_id,
       oil_ord_data_emissione,
       oil_ord_trasm_oil_data,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
	  )
      (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
              flussoElabMifId,rr.mif_t_giornalecassa_id,
              rr.esercizio,rr.numero_bolletta_quietanza_storno,
              rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
              rr.importo,rr.esercizio,rr.numero_documento::integer,
              bil.bil_id,ord.ord_id,
              ord.ord_emissione_data,
              ord.ord_trasm_oil_data,
              clock_timestamp(),loginOperazione,enteProprietarioId
       from   mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
              siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
              siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
       where rr.flusso_elab_mif_id=flussoElabMifId
   	   and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	   and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
       and   qual.oil_qualificatore_segno='U'
	   and   qual.ente_proprietario_id=enteProprietarioId
       and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	   and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
       and   tipo.oil_ricevuta_tipo_code = STORNI_MIF_FLUSSO_TIPO_CODE
	   and   ord.ente_proprietario_id=enteProprietarioId
       and   ord.ord_numero::integer=rr.numero_documento
	   and   ord.ord_tipo_id=ordTipoSpesaId
       and   bil.bil_id=ord.bil_id
	   and   per.periodo_id=bil.periodo_id
       and   per.anno::integer=rr.esercizio
       and   ( --rr.numero_bolletta_quietanza_storno is null or rr.numero_bolletta_quietanza_storno=0 or 24.01.2018 Sofia SIAC-5765
               rr.data_movimento is null or rr.data_movimento='' or
               rr.importo is null or rr.importo=0
             )
       and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_NUM_RIC_COD_ERR::varchar
       and   errore.ente_proprietario_id=enteProprietarioId
       and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                         where rr1.flusso_elab_mif_id=flussoElabMifId
        	             and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

       -- MIF_DR_ORD_NUM_RIC_COD_ERR esistenza di dettagli di quietanza senza numero quietanza o importo o data
       -- [ricevute di  entrata]
	   strMessaggio:='Verifica esistenza record dettaglio ricevuta entrata con dati di quietanza non valorizzati.';
       insert into mif_t_oil_ricevuta
	   (oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
        flusso_elab_mif_id, oil_progr_ricevuta_id,
        oil_ricevuta_anno,oil_ricevuta_numero,
        oil_ricevuta_data,oil_ricevuta_tipo,
        oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
        oil_ord_bil_id, oil_ord_id,
        oil_ord_data_emissione,
        oil_ord_trasm_oil_data,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
	   )
       (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
               flussoElabMifId,rr.mif_t_giornalecassa_id,
               rr.esercizio,rr.numero_bolletta_quietanza,
               rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
               rr.importo,rr.esercizio,rr.numero_documento,
               bil.bil_id,ord.ord_id,
               ord.ord_emissione_data,
               ord.ord_trasm_oil_data,
               clock_timestamp(),loginOperazione,enteProprietarioId
	    from   mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
               siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
               siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	    where rr.flusso_elab_mif_id=flussoElabMifId
      	and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	    and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	and   qual.oil_qualificatore_segno='E'
	    and   qual.ente_proprietario_id=enteProprietarioId
    	and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	    and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    	and   tipo.oil_ricevuta_tipo_code = QUIET_MIF_FLUSSO_TIPO_CODE
	    and   ord.ente_proprietario_id=enteProprietarioId
    	and   ord.ord_numero::integer=rr.numero_documento
	    and   ord.ord_tipo_id=ordTipoEntrataId
    	and   bil.bil_id=ord.bil_id
	    and   per.periodo_id=bil.periodo_id
    	and   per.anno::integer=rr.esercizio
        and   ( -- rr.numero_bolletta_quietanza is null or rr.numero_bolletta_quietanza=0 or 24.01.2018 Sofia SIAC-5765
            	rr.data_movimento is null or rr.data_movimento='' or
                rr.importo is null or rr.importo=0
              )
	    and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_NUM_RIC_COD_ERR::varchar
    	and   errore.ente_proprietario_id=enteProprietarioId
        and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                  where rr1.flusso_elab_mif_id=flussoElabMifId
                          and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

		-- MIF_DR_ORD_NUM_RIC_COD_ERR esistenza di dettagli di quietanza senza numero quietanza o importo o data
		strMessaggio:='Verifica esistenza record dettaglio ricevuta entrata con dati storno quietanza non valorizzati.';
    	insert into mif_t_oil_ricevuta
	    (oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
         flusso_elab_mif_id, oil_progr_ricevuta_id,
         oil_ricevuta_anno,oil_ricevuta_numero,
         oil_ricevuta_data,oil_ricevuta_tipo,
         oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
         oil_ord_bil_id, oil_ord_id,
         oil_ord_data_emissione,
         oil_ord_trasm_oil_data,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
	    )
    	(select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id,
                qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
                flussoElabMifId,rr.mif_t_giornalecassa_id,
                rr.esercizio,rr.numero_bolletta_quietanza_storno,
                rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
                rr.importo,rr.esercizio,rr.numero_documento,
                bil.bil_id,ord.ord_id,
                ord.ord_emissione_data,
                ord.ord_trasm_oil_data,
                clock_timestamp(),loginOperazione,enteProprietarioId
	      from   mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
                 siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
                 siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per
	      where rr.flusso_elab_mif_id=flussoElabMifId
      	  and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	  and   qual.oil_qualificatore_segno='E'
	      and   qual.ente_proprietario_id=enteProprietarioId
    	  and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    	  and   tipo.oil_ricevuta_tipo_code = STORNI_MIF_FLUSSO_TIPO_CODE
	      and   ord.ente_proprietario_id=enteProprietarioId
    	  and   ord.ord_numero::integer=rr.numero_documento
	      and   ord.ord_tipo_id=ordTipoEntrataId
    	  and   bil.bil_id=ord.bil_id
	      and   per.periodo_id=bil.periodo_id
    	  and   per.anno::integer=rr.esercizio
          and   ( -- rr.numero_bolletta_quietanza_storno is null or rr.numero_bolletta_quietanza_storno=0 or 24.01.2018 Sofia SIAC-5765
             	  rr.data_movimento is null or rr.data_movimento='' or
                  rr.importo is null or rr.importo=0
                )
	      and   errore.oil_ricevuta_errore_code=MIF_DR_ORD_NUM_RIC_COD_ERR::varchar
    	  and   errore.ente_proprietario_id=enteProprietarioId
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

    -- gestione scarti -- FINE


    -- inserimento record da elaborare INIZIO
    --- QUIETANZE  STORNI
  	-- [ordinativo spesa]
    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativato spesa da elaborare. Quietanza.';
   	insert into mif_t_oil_ricevuta
    ( oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      oil_ord_anno_bil,oil_ord_numero,
      oil_ord_id,oil_ord_bil_id,
      oil_ord_data_emissione,
      oil_ord_trasm_oil_data,
      oil_ord_data_firma,
      oil_ricevuta_note,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
   	(select tipo.oil_ricevuta_tipo_id,qual.oil_qualificatore_id, esito.oil_esito_derivato_id,
            flussoElabMifId, rr.mif_t_giornalecassa_id,
            rr.esercizio,
            (case when coalesce(rr.numero_bolletta_quietanza,0)=0 then MIF_NUM_RICEVUTA_DEF else rr.numero_bolletta_quietanza end), -- 24.01.2018 Sofia siac-5765
  		    rr.data_movimento::timestamp, -- capire come convertire
            substring(rr.tipo_movimento,1,1),
            rr.importo,
 		    rr.esercizio,rr.numero_documento,
     	 	ord.ord_id, ord.bil_id,
	        ord.ord_emissione_data,
	        ord.ord_trasm_oil_data,
            firmaOrd.ord_firma_data,
            ( case when enteOilFirmeOrd=true and firmaOrd.ord_firma_data is null
                   then  errore.oil_ricevuta_errore_desc
                   else  null end),
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
           siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
           siac_t_bil bil, siac_t_periodo per,
           siac_t_ordinativo ord left outer join
	          (select firma.ord_id, firma.ord_firma_data
    	       from siac_r_ordinativo_firma firma
        	   where firma.ente_proprietario_id=enteProprietarioId
               and   firma.data_cancellazione is null
    	       and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.oil_qualificatore_segno='U'
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	 and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code = QUIET_MIF_FLUSSO_TIPO_CODE
	 and   ord.ente_proprietario_id=enteProprietarioId
     and   ord.ord_numero::integer=rr.numero_documento
	 and   ord.ord_tipo_id=ordTipoSpesaId
     and   bil.bil_id=ord.bil_id
	 and   per.periodo_id=bil.periodo_id
     and   per.anno::integer=rr.esercizio
     and   errore.ente_proprietario_id=enteProprietarioId
     and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
     and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

	 strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativato spesa da elaborare. Storno Quietanza.';
     insert into mif_t_oil_ricevuta
	 (oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      oil_ord_anno_bil,oil_ord_numero,
   	  oil_ord_id,oil_ord_bil_id,
      oil_ord_data_emissione,
      oil_ord_trasm_oil_data,
      oil_ord_data_firma,
      oil_ricevuta_note,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
	 )
     (select tipo.oil_ricevuta_tipo_id,qual.oil_qualificatore_id, esito.oil_esito_derivato_id,
             flussoElabMifId, rr.mif_t_giornalecassa_id,
             rr.esercizio,
             (case when coalesce(rr.numero_bolletta_quietanza_storno,0)=0 then MIF_NUM_RICEVUTA_DEF else rr.numero_bolletta_quietanza_storno end), -- 24.01.2018 Sofia siac-5765
      		 rr.data_movimento::timestamp, -- capire come convertire
             substring(rr.tipo_movimento,1,1),
             rr.importo,
	     	 rr.esercizio,rr.numero_documento,
     	 	 ord.ord_id, ord.bil_id,
	         ord.ord_emissione_data,
	         ord.ord_trasm_oil_data,
             firmaOrd.ord_firma_data,
             ( case when enteOilFirmeOrd=true and firmaOrd.ord_firma_data is null
                    then  errore.oil_ricevuta_errore_desc
                    else  null end),
             clock_timestamp(),loginOperazione,enteProprietarioId
	  from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
            siac_t_bil bil, siac_t_periodo per,
            siac_t_ordinativo ord left outer join
	           (select firma.ord_id, firma.ord_firma_data
    	        from siac_r_ordinativo_firma firma
        	    where firma.ente_proprietario_id=enteProprietarioId
                and   firma.data_cancellazione is null
    	        and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
      where rr.flusso_elab_mif_id=flussoElabMifId
  	  and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	  and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='U'
	  and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	  and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code = STORNI_MIF_FLUSSO_TIPO_CODE
	  and   ord.ente_proprietario_id=enteProprietarioId
      and   ord.ord_numero::integer=rr.numero_documento
	  and   ord.ord_tipo_id=ordTipoSpesaId
      and   bil.bil_id=ord.bil_id
	  and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=rr.esercizio
      and   errore.ente_proprietario_id=enteProprietarioId
      and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
      and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
       	                and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


       -- [ordinativo entrata]
	   strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativo entrata da elaborare. Quietanza.';
       insert into mif_t_oil_ricevuta
	   ( oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
         flusso_elab_mif_id, oil_progr_ricevuta_id,
         oil_ricevuta_anno,oil_ricevuta_numero,
         oil_ricevuta_data,oil_ricevuta_tipo,
         oil_ricevuta_importo,
         oil_ord_anno_bil,oil_ord_numero,
   	     oil_ord_id,oil_ord_bil_id,
         oil_ord_data_emissione,
         oil_ord_trasm_oil_data,
         oil_ord_data_firma,
         oil_ricevuta_note,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
	   )
       (select tipo.oil_ricevuta_tipo_id,qual.oil_qualificatore_id, esito.oil_esito_derivato_id,
               flussoElabMifId, rr.mif_t_giornalecassa_id,
               rr.esercizio,
               (case when coalesce(rr.numero_bolletta_quietanza,0)=0 then MIF_NUM_RICEVUTA_DEF else rr.numero_bolletta_quietanza end), -- 24.01.2018 Sofia siac-5765
     	       rr.data_movimento::timestamp, -- capire come convertire
               substring(rr.tipo_movimento,1,1),
               rr.importo,
			   rr.esercizio,rr.numero_documento,
     		   ord.ord_id, ord.bil_id,
	           ord.ord_emissione_data,
	           ord.ord_trasm_oil_data,
               firmaOrd.ord_firma_data,
               ( case when enteOilFirmeOrd=true and firmaOrd.ord_firma_data is null
                      then  errore.oil_ricevuta_errore_desc
                      else  null end),
               clock_timestamp(),loginOperazione,enteProprietarioId
	     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
               siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
               siac_t_bil bil, siac_t_periodo per,
               siac_t_ordinativo ord left outer join
	           (select firma.ord_id, firma.ord_firma_data
    	        from siac_r_ordinativo_firma firma
        	    where firma.ente_proprietario_id=enteProprietarioId
                and   firma.data_cancellazione is null
    	        and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
	      where rr.flusso_elab_mif_id=flussoElabMifId
      	  and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	  and   qual.oil_qualificatore_segno='E'
	      and   qual.ente_proprietario_id=enteProprietarioId
    	  and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    	  and   tipo.oil_ricevuta_tipo_code = QUIET_MIF_FLUSSO_TIPO_CODE
	      and   ord.ente_proprietario_id=enteProprietarioId
    	  and   ord.ord_numero::integer=rr.numero_documento
	      and   ord.ord_tipo_id=ordTipoEntrataId
    	  and   bil.bil_id=ord.bil_id
	      and   per.periodo_id=bil.periodo_id
    	  and   per.anno::integer=rr.esercizio
          and   errore.ente_proprietario_id=enteProprietarioId
          and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
          and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                    where rr1.flusso_elab_mif_id=flussoElabMifId
         	                and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

    	-- [ordinativo entrata]
	    strMessaggio:='Inserimento mit_t_oil_ricevuta  per ordinativo entrata da elaborare.Storno Quietanza.';
    	insert into mif_t_oil_ricevuta
	    (oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
         flusso_elab_mif_id, oil_progr_ricevuta_id,
         oil_ricevuta_anno,oil_ricevuta_numero,
         oil_ricevuta_data,oil_ricevuta_tipo,
         oil_ricevuta_importo,
         oil_ord_anno_bil,oil_ord_numero,
         oil_ord_id,oil_ord_bil_id,
         oil_ord_data_emissione,
         oil_ord_trasm_oil_data,
         oil_ord_data_firma,
         oil_ricevuta_note,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
	    )
    	(select tipo.oil_ricevuta_tipo_id,qual.oil_qualificatore_id, esito.oil_esito_derivato_id,
                flussoElabMifId, rr.mif_t_giornalecassa_id,
                rr.esercizio,
                (case when coalesce(rr.numero_bolletta_quietanza_storno,0)=0 then MIF_NUM_RICEVUTA_DEF else rr.numero_bolletta_quietanza_storno end), -- 24.01.2018 Sofia siac-5765
        	    rr.data_movimento::timestamp, -- capire come convertire
                substring(rr.tipo_movimento,1,1),
                rr.importo,
			    rr.esercizio,rr.numero_documento,
     		    ord.ord_id, ord.bil_id,
	            ord.ord_emissione_data,
	            ord.ord_trasm_oil_data,
                firmaOrd.ord_firma_data,
                ( case when enteOilFirmeOrd=true and firmaOrd.ord_firma_data is null
                       then  errore.oil_ricevuta_errore_desc
                       else  null end),
                clock_timestamp(),loginOperazione,enteProprietarioId
	      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
                siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
                siac_t_bil bil, siac_t_periodo per,
                siac_t_ordinativo ord  left outer join
 	            (select firma.ord_id, firma.ord_firma_data
    	         from siac_r_ordinativo_firma firma
        	     where firma.ente_proprietario_id=enteProprietarioId
                 and   firma.data_cancellazione is null
    	         and   firma.validita_fine is null) firmaOrd on (firmaOrd.ord_id=ord.ord_id)
	       where rr.flusso_elab_mif_id=flussoElabMifId
      	   and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	       and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	   and   qual.oil_qualificatore_segno='E'
	       and   qual.ente_proprietario_id=enteProprietarioId
    	   and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	       and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    	   and   tipo.oil_ricevuta_tipo_code = STORNI_MIF_FLUSSO_TIPO_CODE
	       and   ord.ente_proprietario_id=enteProprietarioId
    	   and   ord.ord_numero::integer=rr.numero_documento
	       and   ord.ord_tipo_id=ordTipoEntrataId
    	   and   bil.bil_id=ord.bil_id
	       and   per.periodo_id=bil.periodo_id
    	   and   per.anno::integer=rr.esercizio
           and   errore.ente_proprietario_id=enteProprietarioId
           and   errore.oil_ricevuta_errore_code=MIF_RR_ORD_NO_FIRMA_COD_ERR
           and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
    	                     where rr1.flusso_elab_mif_id=flussoElabMifId
          	                and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


    ----------- INIZIO CICLO DI ELABORAZIONE -----------------------------------------------

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
     and   tipo.oil_ricevuta_tipo_code in (QUIET_MIF_FLUSSO_TIPO_CODE,STORNI_MIF_FLUSSO_TIPO_CODE)
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
              if enteOilFirmeOrd=true and
                 ricevutaRec.oil_ord_data_firma is not null
                 then
            	   ordCambioStatoId:=ordStatoFirmaId;
	          else ordCambioStatoId:=ordStatoTrasmId;
    	      end if;
         else
        	-- stato verso cui cambiare
        	ordCambioStatoId:=ordStatoQuietId;

            -- stato attuale
        	if enteOilFirmeOrd=true and
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
	          clock_timestamp(),
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
          clock_timestamp(),
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
    	       clock_timestamp(),
               clock_timestamp(),
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
            update siac_r_ordinativo_quietanza set validita_fine=clock_timestamp(), login_operazione=loginOperazione
            where ord_id=ricevutaRec.oil_ord_id
            and   data_cancellazione is null
            and   validita_fine is null;

        	strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id
                         ||'.Aggiornamento dati ordinativo per totale quietanzato zero.Chiusura storni.';
            update siac_r_ordinativo_storno  set validita_fine=clock_timestamp(), login_operazione=loginOperazione
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
           clock_timestamp(),
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
           clock_timestamp(),
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
       	update siac_r_ordinativo_stato stato set validita_fine=clock_timestamp(), login_operazione=loginOperazione
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
          clock_timestamp(),
          enteProprietarioId,
          loginOperazione
        )
        returning ord_stato_r_id into codResult;

        if codResult is null then
        	raise exception ' Errore in inserimento.';
        end if;

       end if;




       -- aggiorno contatore ordinativi aggiornati
       countOrdAgg:=countOrdAgg+1;
	   raise notice 'countOrdAgg=%',countOrdAgg;
    end loop;



	messaggioRisultato:=strMessaggioFinale||' - FINE.';
	messaggioRisultato:=upper(messaggioRisultato);
    countOrdAggRisultato:=countOrdAgg;

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
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
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