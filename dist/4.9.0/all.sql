/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 20.02.2019 Sofia SIAC-6642 - inizio
drop function if exists 
fnc_mif_flusso_elaborato_giornalecassa_prov
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  flussoElabMifId integer,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out codiceRisultato integer,
  out messaggioRisultato varchar,
  out countOrdAggRisultato numeric );
  
CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_giornalecassa_prov
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


    codResult integer :=null;
    codErrore varchar(10) :=null;

    numeroRicevuta integer :=null;
    oilRicevutaId  integer :=null;


    provCId integer :=null;
   	codErroreId integer:=null;
    provvCEsisteCodeErrId integer:=null;

	provCTipoSpesaId integer:=null;
    provCTipoEntrataId integer:=null;


    provvCNonEsisteCodeErrId integer:=null;
    provvCStornatoCodeErrId integer:=null;
    provvCImpStornatoCodeErrId integer:=null;

	dataAnnullamento timestamp:=null;
    importoProvvisorio numeric:=null;


	countOrdAgg numeric:=0;
    ricevutaRec record;


    PROVC_MIF_FLUSSO_TIPO   CONSTANT  varchar :='P';    -- provvisori
    PROVC_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='P';    -- provvisori
    PROVC_ST_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='PS';    -- storno provvisori

    PROVC_TIPO_SPESA CONSTANT varchar :='S';
    PROVC_TIPO_ENTRATA CONSTANT varchar :='E';



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



BEGIN


    strMessaggioFinale:='Ciclo elaborazione provvisori di cassa-storni.';

    codiceRisultato:=0;
    countOrdAggRisultato:=0;
    messaggioRisultato:='';


    -- provvCEsisteCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_ESISTE_COD_ERR||' per verifica esistenza provvisorio.';
    select errore.oil_ricevuta_errore_id into strict provvCEsisteCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_ESISTE_COD_ERR;

	-- provvCNonEsisteCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_S_COD_ERR||' per verifica esistenza provvisorio.';
    select errore.oil_ricevuta_errore_id into strict provvCNonEsisteCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_COD_ERR;


	-- provvCStornatoCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_S_STO_COD_ERR||' provvisorio stornato.';
    select errore.oil_ricevuta_errore_id into strict provvCStornatoCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_STO_COD_ERR;

	-- provvCImpStornatoCodeErrId
    strMessaggio:='Lettura Id errore code='||MIF_RR_PROVC_S_IMP_COD_ERR||' provvisorio importo < stornato.';
    select errore.oil_ricevuta_errore_id into strict provvCImpStornatoCodeErrId
    from siac_d_oil_ricevuta_errore errore
    where errore.ente_proprietario_id=enteProprietarioId
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_IMP_COD_ERR;



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


    -- gestione scarti - INIZIO
    -- MIF_RR_PC_CASSA_COD_ERR - dati provvisorio di cassa non indicati
    strMessaggio:='Verifica esistenza record ricevuta dati provvisorio non indicati - provvisorio-storno.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_documento,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            abs(rr.importo),
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
           siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (PROVC_MIF_FLUSSO_TIPO_CODE, PROVC_ST_MIF_FLUSSO_TIPO_CODE)
     and   ( rr.esercizio is null or rr.esercizio=0 or
             rr.numero_documento is null or  rr.numero_documento=0 or
             rr.data_movimento is null or rr.data_movimento='')
     and errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


	-- MIF_RR_PC_CASSA_ANNO_COD_ERR - dati provvisorio di cassa non indicati
    strMessaggio:='Verifica esistenza record ricevuta  anno provvisorio di cassa non corretto rispetto all''anno di bilancio corrente.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_documento,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            abs(rr.importo),
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
           siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (PROVC_MIF_FLUSSO_TIPO_CODE, PROVC_ST_MIF_FLUSSO_TIPO_CODE)
--     and   rr.esercizio!=annoBilancio -- 20.02.2019 Sofia SIAC-6642
     and   ( rr.esercizio!=annoBilancio and rr.esercizio!=annoBilancio-1 )
     and   errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_ANNO_COD_ERR::varchar
     and   errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


    -- MIF_RR_PC_CASSA_IMP_COD_ERR - importo provvisorio di cassa/storno non valito
    strMessaggio:='Verifica esistenza record ricevuta importo provvisorio non valido - provvisorio-storno.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_documento,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            abs(rr.importo),
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
           siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (PROVC_MIF_FLUSSO_TIPO_CODE, PROVC_ST_MIF_FLUSSO_TIPO_CODE)
     and   ( rr.importo is null or rr.importo=0 )
     and errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_IMP_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


	-- MIF_RR_PC_CASSA_DT_COD_ERR data emissione provvisorio di cassa non corretto
    strMessaggio:='Verifica esistenza record ricevuta  data emissione provvisorio di cassa non corretto rispetto alla data di elaborazione.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,
      oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id,
            tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_documento,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            abs(rr.importo),
            clock_timestamp(),loginOperazione,enteProprietarioId
     from mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
          siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and   qual.ente_proprietario_id=enteProprietarioId
     and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (PROVC_MIF_FLUSSO_TIPO_CODE, PROVC_ST_MIF_FLUSSO_TIPO_CODE)
     and   rr.data_movimento::timestamp>dataElaborazione
     and   errore.oil_ricevuta_errore_code=MIF_RR_PC_CASSA_DT_COD_ERR::varchar
     and   errore.ente_proprietario_id=enteProprietarioId
     and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

	-- esistenza provvisorio di cassa per ricevuta di inserimento provvisorio - provvisorio esistente
    -- MIF_RR_PROVC_ESISTE_COD_ERR
    -- [provvissorio_cassa_spesa]
    strMessaggio:='Verifica esistenza record ricevuta  provvisorio di cassa spesa esistente per operazione di inserimento.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
      oil_provc_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
            flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_documento,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            abs(rr.importo),
            prov.provc_id,
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
           siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
           siac_t_prov_cassa prov
     where  rr.flusso_elab_mif_id=flussoElabMifId
     and    qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
     and    qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
     and    qual.oil_qualificatore_segno='U'
     and    qual.ente_proprietario_id=enteProprietarioId
     and    esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
     and    tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
     and    tipo.oil_ricevuta_tipo_code = PROVC_MIF_FLUSSO_TIPO_CODE
     and    prov.ente_proprietario_id=enteProprietarioId
     and    prov.provc_anno::integer=rr.esercizio
     and    prov.provc_numero::integer=rr.numero_documento
     and    prov.provc_tipo_id=provCTipoSpesaId
     and    prov.data_cancellazione is null
     and    prov.validita_fine is null
     and    errore.oil_ricevuta_errore_code=MIF_RR_PROVC_ESISTE_COD_ERR::varchar
     and    errore.ente_proprietario_id=enteProprietarioId
     and    not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                        where rr1.flusso_elab_mif_id=flussoElabMifId
                        and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta  provvisorio di cassa entrata esistente per operazione di inserimento.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_documento,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             abs(rr.importo),
             prov.provc_id,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
             siac_t_prov_cassa prov
      where  rr.flusso_elab_mif_id=flussoElabMifId
      and    qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and    qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and    qual.oil_qualificatore_segno='E'
      and    qual.ente_proprietario_id=enteProprietarioId
      and    esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and    tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and    tipo.oil_ricevuta_tipo_code = PROVC_MIF_FLUSSO_TIPO_CODE
      and    prov.ente_proprietario_id=enteProprietarioId
      and    prov.provc_anno::integer=rr.esercizio
      and    prov.provc_numero::integer=rr.numero_documento
      and    prov.provc_tipo_id=provCTipoEntrataId
      and    prov.data_cancellazione is null
      and    prov.validita_fine is null
      and    errore.oil_ricevuta_errore_code=MIF_RR_PROVC_ESISTE_COD_ERR::varchar
      and    errore.ente_proprietario_id=enteProprietarioId
      and    not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                         where rr1.flusso_elab_mif_id=flussoElabMifId
                         and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

   -- provvissorio di cassa esistente per ricevuta di storno provvisorio completamente stornato (data_annullamento valorizzata )
   -- MIF_RR_PROVC_S_STO_COD_ERR provvissorio di cassa  esistente per storno provv stornato (data_annullamento valorizzata )
   -- [provvissorio_cassa_spesa]
   strMessaggio:='Verifica esistenza record ricevuta provvisorio di cassa spesa per operazione di storno provvisorio stornato [data_annullamento valorizzata].';
   insert into mif_t_oil_ricevuta
   (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
   )
   (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
           flussoElabMifId,rr.mif_t_giornalecassa_id,
           rr.esercizio,rr.numero_documento,
           rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
           abs(rr.importo),
           prov.provc_id,
           clock_timestamp(),loginOperazione,enteProprietarioId
    from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
          siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
          siac_t_prov_cassa prov
    where rr.flusso_elab_mif_id=flussoElabMifId
    and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
    and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    and   qual.oil_qualificatore_segno='U'
    and   qual.ente_proprietario_id=enteProprietarioId
    and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
    and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
    and   prov.ente_proprietario_id=enteProprietarioId
    and   prov.provc_anno::integer=rr.esercizio
    and   prov.provc_numero::integer=rr.numero_documento
    and   prov.provc_tipo_id=provCTipoSpesaId
    and   prov.provc_data_annullamento is not null -- stornato
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_STO_COD_ERR::varchar
    and   errore.ente_proprietario_id=enteProprietarioId
    and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                    where rr1.flusso_elab_mif_id=flussoElabMifId
                    and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


   -- [provvissorio_cassa_entrata]
   strMessaggio:='Verifica esistenza record ricevuta provvisorio di cassa spesa per operazione di storno provvisorio stornato [data_annullamento valorizzata].';
   insert into mif_t_oil_ricevuta
   (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
   )
   (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
           flussoElabMifId,rr.mif_t_giornalecassa_id,
           rr.esercizio,rr.numero_documento,
           rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
           abs(rr.importo),
           prov.provc_id,
           clock_timestamp(),loginOperazione,enteProprietarioId
    from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
          siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
          siac_t_prov_cassa prov
    where rr.flusso_elab_mif_id=flussoElabMifId
    and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
    and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    and   qual.oil_qualificatore_segno='E'
    and   qual.ente_proprietario_id=enteProprietarioId
    and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
    and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
    and   prov.ente_proprietario_id=enteProprietarioId
    and   prov.provc_anno::integer=rr.esercizio
    and   prov.provc_numero::integer=rr.numero_documento
    and   prov.provc_tipo_id=provCTipoEntrataId
    and   prov.provc_data_annullamento is not null -- stornato
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_STO_COD_ERR::varchar
    and   errore.ente_proprietario_id=enteProprietarioId
    and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                    where rr1.flusso_elab_mif_id=flussoElabMifId
                    and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


   -- provvissorio di cassa esistente per ricevuta di storno importo di storno>  importo prov
   -- MIF_RR_PROVC_S_IMP_COD_ERR provvissorio di cassa  esistente per storno importo storno > importo prov
   -- [provvissorio_cassa_spesa]
   strMessaggio:='Verifica esistenza record ricevuta  provvisorio di cassa spesa per operazione di storno con importo storno maggiore importo provvisorio.';
   insert into mif_t_oil_ricevuta
   (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
   )
   (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
           flussoElabMifId,rr.mif_t_giornalecassa_id,
           rr.esercizio,rr.numero_documento,
           rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
           abs(rr.importo),
           prov.provc_id,
           clock_timestamp(),loginOperazione,enteProprietarioId
    from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
          siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
          siac_t_prov_cassa prov
    where rr.flusso_elab_mif_id=flussoElabMifId
    and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
    and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    and   qual.oil_qualificatore_segno='U'
    and   qual.ente_proprietario_id=enteProprietarioId
    and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
    and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
    and   prov.ente_proprietario_id=enteProprietarioId
    and   prov.provc_anno::integer=rr.esercizio
    and   prov.provc_numero::integer=rr.numero_documento
    and   prov.provc_tipo_id=provCTipoSpesaId
    and   prov.provc_importo<abs(rr.importo)
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_IMP_COD_ERR::varchar
    and   errore.ente_proprietario_id=enteProprietarioId
    and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                    where rr1.flusso_elab_mif_id=flussoElabMifId
                    and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta  provvisorio di cassa entrata per operazione di storno con importo storno maggiore importo provvisorio.';
     insert into mif_t_oil_ricevuta
     (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_documento,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             abs(rr.importo),
             prov.provc_id,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
            siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='E'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno::integer=rr.esercizio
      and   prov.provc_numero::integer=rr.numero_documento
      and   prov.provc_tipo_id=provCTipoEntrataId
      and   prov.provc_importo<abs(rr.importo)
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_IMP_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));



   -- provvissorio di cassa esistente per ricevuta di storno soggetto diverso da denominazione su provvisorio
   -- MIF_RR_PROVC_S_SOG_COD_ERR provvissorio di cassa  esistente per storno soggetto diverso da denominazione su provvisorio
   -- [provvissorio_cassa_spesa]
   strMessaggio:='Verifica esistenza record ricevuta provvisorio di cassa spesa per operazione di storno con soggetto non coerente con provvisorio.';
   insert into mif_t_oil_ricevuta
   (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
   )
   (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
           flussoElabMifId,rr.mif_t_giornalecassa_id,
           rr.esercizio,rr.numero_documento,
           rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
           abs(rr.importo),
           substring(rr.anagrafica_cliente,1,500),
           prov.provc_id,
           clock_timestamp(),loginOperazione,enteProprietarioId
    from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
          siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
          siac_t_prov_cassa prov
    where rr.flusso_elab_mif_id=flussoElabMifId
    and   rr.anagrafica_cliente is not null
    and   rr.anagrafica_cliente!=''
    and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
    and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    and   qual.oil_qualificatore_segno='U'
    and   qual.ente_proprietario_id=enteProprietarioId
    and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
    and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
    and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
    and   prov.ente_proprietario_id=enteProprietarioId
    and   prov.provc_anno::integer=rr.esercizio
    and   prov.provc_numero::integer=rr.numero_documento
    and   prov.provc_tipo_id=provCTipoSpesaId
    and   prov.provc_denom_soggetto!=substring(rr.anagrafica_cliente,1,500)
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null
    and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_SOG_COD_ERR::varchar
    and   errore.ente_proprietario_id=enteProprietarioId
    and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                    where rr1.flusso_elab_mif_id=flussoElabMifId
                    and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

	 -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta provvisorio di cassa entrata per operazione di storno con soggetto non coerente con provvisorio.';
     insert into mif_t_oil_ricevuta
     (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
             flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_documento,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             abs(rr.importo),
             substring(rr.anagrafica_cliente,1,500),
             prov.provc_id,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
            siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
            siac_t_prov_cassa prov
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   rr.anagrafica_cliente is not null
      and   rr.anagrafica_cliente!=''
      and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
      and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
      and   qual.oil_qualificatore_segno='E'
      and   qual.ente_proprietario_id=enteProprietarioId
      and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
      and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
      and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
      and   prov.ente_proprietario_id=enteProprietarioId
      and   prov.provc_anno::integer=rr.esercizio
      and   prov.provc_numero::integer=rr.numero_documento
      and   prov.provc_tipo_id=provCTipoEntrataId
      and   prov.provc_denom_soggetto!=substring(rr.anagrafica_cliente,1,500)
      and   prov.data_cancellazione is null
      and   prov.validita_fine is null
      and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_SOG_COD_ERR::varchar
      and   errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                      where rr1.flusso_elab_mif_id=flussoElabMifId
                      and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

  --- esistenza provvisorio - storno , legato ad un ordinativo

  -- MIF_RR_PROVC_S_REG_COD_ERR provvissorio di cassa  esistente per storno collegato a ordinativo di spesa
  -- [provvissorio_cassa_spesa]
  strMessaggio:='Verifica esistenza record ricevuta  provvisorio di cassa spesa per operazione di storno regolarizzato.';
  insert into mif_t_oil_ricevuta
  (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
  )
  (
      with
       ordProvCassa as
       (
       	select r.provc_id
        from siac_r_ordinativo_prov_cassa r, siac_t_ordinativo ord , siac_r_ordinativo_stato rstato , siac_d_ordinativo_stato stato
        where stato.ente_proprietario_id=enteProprietarioId
        and   stato.ord_stato_code!='A'
        and   rstato.ord_stato_id=stato.ord_stato_id
        and   ord.ord_id=rstato.ord_id
        and   r.ord_id=ord.ord_id
        and   rstato.data_cancellazione is null
        and   rstato.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null
       ),
       provCassa as
       (
       select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
              rr.mif_t_giornalecassa_id,
              rr.esercizio,rr.numero_documento,
              rr.data_movimento::timestamp data_movimento,
              substring(rr.tipo_movimento,1,1) tipo_movimento,
              abs(rr.importo) importo,
              substring(rr.anagrafica_cliente,1,500) anagrafica_cliente,
              prov.provc_id
       from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
             siac_t_prov_cassa prov
       where rr.flusso_elab_mif_id=flussoElabMifId
       --and   rr.anagrafica_cliente is not null
       --and   rr.anagrafica_cliente!=''
       and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
       and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
       and   qual.oil_qualificatore_segno='U'
       and   qual.ente_proprietario_id=enteProprietarioId
       and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
       and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
       and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
       and   prov.ente_proprietario_id=enteProprietarioId
       and   prov.provc_anno::integer=rr.esercizio
       and   prov.provc_numero::integer=rr.numero_documento
       and   prov.provc_tipo_id=provCTipoSpesaId
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_REG_COD_ERR::varchar
       and   errore.ente_proprietario_id=enteProprietarioId
       and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id)
      )
      select provCassa.oil_ricevuta_errore_id, provCassa.oil_ricevuta_tipo_id, provCassa.oil_qualificatore_id,provCassa.oil_esito_derivato_id,
             flussoElabMifId,provCassa.mif_t_giornalecassa_id,
             provCassa.esercizio,provCassa.numero_documento,
             provCassa.data_movimento,provCassa.tipo_movimento,
             provCassa.importo,
             provCassa.anagrafica_cliente,
             provCassa.provc_id,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from provCassa, ordProvCassa
      where provCassa.provc_id=ordProvCassa.provc_id);

     -- MIF_RR_PROVC_S_REG_COD_ERR provvissorio di cassa  esistente per storno collegato a ordinativo di entrata
	 -- [provvissorio_cassa_entrata]
     strMessaggio:='Verifica esistenza record ricevuta  provvisorio di cassa entrata per operazione di storno regolarizzato.';
     insert into mif_t_oil_ricevuta
     (
	   oil_ricevuta_errore_id,oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
       flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,
       oil_ricevuta_denominazione,
       oil_provc_id,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (
      with
       ordProvCassa as
       (
       	select r.provc_id
        from siac_r_ordinativo_prov_cassa r, siac_t_ordinativo ord , siac_r_ordinativo_stato rstato , siac_d_ordinativo_stato stato
        where stato.ente_proprietario_id=enteProprietarioId
        and   stato.ord_stato_code!='A'
        and   rstato.ord_stato_id=stato.ord_stato_id
        and   ord.ord_id=rstato.ord_id
        and   r.ord_id=ord.ord_id
        and   rstato.data_cancellazione is null
        and   rstato.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null
       ),
       provCassa as
       (
       select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
              rr.mif_t_giornalecassa_id,
              rr.esercizio,rr.numero_documento,
              rr.data_movimento::timestamp data_movimento,
              substring(rr.tipo_movimento,1,1) tipo_movimento,
              abs(rr.importo) importo,
              substring(rr.anagrafica_cliente,1,500) anagrafica_cliente,
              prov.provc_id
       from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
             siac_t_prov_cassa prov
       where rr.flusso_elab_mif_id=flussoElabMifId
--       and   rr.anagrafica_cliente is not null
--       and   rr.anagrafica_cliente!=''
       and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
       and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
       and   qual.oil_qualificatore_segno='E'
       and   qual.ente_proprietario_id=enteProprietarioId
       and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
       and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
       and   tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE
       and   prov.ente_proprietario_id=enteProprietarioId
       and   prov.provc_anno::integer=rr.esercizio
       and   prov.provc_numero::integer=rr.numero_documento
       and   prov.provc_tipo_id=provCTipoEntrataId
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   errore.oil_ricevuta_errore_code=MIF_RR_PROVC_S_REG_COD_ERR::varchar
       and   errore.ente_proprietario_id=enteProprietarioId
       and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id)
      )
      select provCassa.oil_ricevuta_errore_id, provCassa.oil_ricevuta_tipo_id, provCassa.oil_qualificatore_id,provCassa.oil_esito_derivato_id,
             flussoElabMifId,provCassa.mif_t_giornalecassa_id,
             provCassa.esercizio,provCassa.numero_documento,
             provCassa.data_movimento,provCassa.tipo_movimento,
             provCassa.importo,
             provCassa.anagrafica_cliente,
             provCassa.provc_id,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from provCassa, ordProvCassa
      where provCassa.provc_id=ordProvCassa.provc_id);

    -- gestione scarti - FINE

    -- inserimento record elaborazione - INIZIO

    -- [provvisorio_cassa_spesa]
	strMessaggio:='Inserimento mit_t_oil_ricevuta  per ricevuta provvisorio di cassa spesa da elaborare.';
    insert into mif_t_oil_ricevuta
	( oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
      flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_provc_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,
 	  oil_ricevuta_denominazione,
      oil_ricevuta_note,
      -- 07.11.2018 Sofia siac-6351
      oil_ricevuta_conto_evidenza,
      oil_ricevuta_conto_evidenza_desc,
      -- 07.11.2018 Sofia siac-6351
      validita_inizio,
      login_operazione,
      ente_proprietario_id
	 )
     (select
          tipo.oil_ricevuta_tipo_id,
          qual.oil_qualificatore_id,
          esito.oil_esito_derivato_id,
          flussoElabMifId,
          rr.mif_t_giornalecassa_id,
         (case when tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE then -1 else null end ),
     	  rr.esercizio,
          rr.numero_documento,
          rr.data_movimento::timestamp,
          qual.oil_qualificatore_segno,
          abs(rr.importo),
          substring(rr.anagrafica_cliente,1,500),
          substring(rr.causale,1,500),
          -- 07.11.2018 Sofia siac-6351
          rr.conto_evidenza,
          rr.descrizione_conto_evidenza,
          -- 07.11.2018 Sofia siac-6351
          clock_timestamp(),loginOperazione,enteProprietarioId
         from  siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
               mif_t_elab_giornalecassa rr
               left outer join
               (select prov.provc_id,prov.provc_anno, prov.provc_numero, prov.provc_tipo_id
                from siac_t_prov_cassa prov
				where prov.ente_proprietario_id=enteProprietarioId
                and   prov.data_cancellazione is null
                and   prov.validita_fine is null) provCassa
                      on (provCassa.provc_anno::integer=rr.esercizio
                      and provCassa.provc_numero::integer=rr.numero_documento
                      and provCassa.provc_tipo_id=provCTipoSpesaId )
	     where rr.flusso_elab_mif_id=flussoElabMifId
      	 and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	 and   qual.oil_qualificatore_segno='U'
	     and   qual.ente_proprietario_id=enteProprietarioId
    	 and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( PROVC_ST_MIF_FLUSSO_TIPO_CODE,PROVC_MIF_FLUSSO_TIPO_CODE)
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
   	                       where rr1.flusso_elab_mif_id=flussoElabMifId
       	                   and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


      -- [provvisorio_cassa_entrata]
	  strMessaggio:='Inserimento mit_t_oil_ricevuta  per ricevuta provvisorio di cassa entrata da elaborare.';
      insert into mif_t_oil_ricevuta
	  ( oil_ricevuta_tipo_id,oil_qualificatore_id,oil_esito_derivato_id,
        flusso_elab_mif_id, oil_progr_ricevuta_id,
        oil_provc_id,
        oil_ricevuta_anno,oil_ricevuta_numero,
        oil_ricevuta_data,oil_ricevuta_tipo,
        oil_ricevuta_importo,
 	    oil_ricevuta_denominazione,
        oil_ricevuta_note,
        -- 07.11.2018 Sofia siac-6351
        oil_ricevuta_conto_evidenza,
        oil_ricevuta_conto_evidenza_desc,
        -- 07.11.2018 Sofia siac-6351
        validita_inizio,
        login_operazione,
        ente_proprietario_id
	   )
       (select
          tipo.oil_ricevuta_tipo_id,
          qual.oil_qualificatore_id,
          esito.oil_esito_derivato_id,
          flussoElabMifId,
          rr.mif_t_giornalecassa_id,
         (case when tipo.oil_ricevuta_tipo_code=PROVC_ST_MIF_FLUSSO_TIPO_CODE then -1 else null end ),
     	  rr.esercizio,
          rr.numero_documento,
          rr.data_movimento::timestamp,
          qual.oil_qualificatore_segno,
          abs(rr.importo),
          substring(rr.anagrafica_cliente,1,500),
          substring(rr.causale,1,500),
          -- 07.11.2018 Sofia siac-6351
          rr.conto_evidenza,
          rr.descrizione_conto_evidenza,
          -- 07.11.2018 Sofia siac-6351
          clock_timestamp(),loginOperazione,enteProprietarioId
         from  siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
               mif_t_elab_giornalecassa rr
               left outer join
               (select prov.provc_id,prov.provc_anno, prov.provc_numero, prov.provc_tipo_id
                from siac_t_prov_cassa prov
				where prov.ente_proprietario_id=enteProprietarioId
                and   prov.data_cancellazione is null
                and   prov.validita_fine is null) provCassa
                      on (provCassa.provc_anno::integer=rr.esercizio
                      and provCassa.provc_numero::integer=rr.numero_documento
                      and provCassa.provc_tipo_id=provCTipoEntrataId )
	     where rr.flusso_elab_mif_id=flussoElabMifId
      	 and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	 and   qual.oil_qualificatore_segno='E'
	     and   qual.ente_proprietario_id=enteProprietarioId
    	 and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( PROVC_ST_MIF_FLUSSO_TIPO_CODE,PROVC_MIF_FLUSSO_TIPO_CODE)
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
   	                       where rr1.flusso_elab_mif_id=flussoElabMifId
       	                   and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

    -- inserimento record elaborazione - FINE

    --- Inizio ciclo di elaborazione

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
            -- 07.11.2018 Sofia siac-6351
            mif.oil_ricevuta_conto_evidenza,
            mif.oil_ricevuta_conto_evidenza_desc,
            -- 07.11.2018 Sofia siac-6351
            mif.oil_ricevuta_denominazione,
            mif.oil_ricevuta_tipo
     from mif_t_oil_ricevuta mif, siac_d_oil_ricevuta_tipo tipo
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.oil_ricevuta_errore_id is null
     and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id
     and   tipo.oil_ricevuta_tipo_code in (PROVC_MIF_FLUSSO_TIPO_CODE,PROVC_ST_MIF_FLUSSO_TIPO_CODE)
     order by mif.oil_progr_ricevuta_id
    )
    loop
		codResult:=null;
        oilRicevutaId:=null;
		provCId:=null;
		codErroreId:=null;

        dataAnnullamento:=null;
        importoProvvisorio:=null;

        strMessaggio:='Ciclo di lettura di ricevute da elaborare [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
    --    raise notice 'strMessaggio=%',strMessaggio;
    --    raise notice 'ricevutaRec.oil_provc_id=%',ricevutaRec.oil_provc_id;
        if ricevutaRec.oil_provc_id is null then
			strMessaggio:='Verifica esistenza provvisorio di cassa prima di operazione inserimento [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
			select cassa.provc_id into codResult
            from siac_t_prov_cassa cassa
            where cassa.ente_proprietario_id=enteProprietarioId
            and   cassa.provc_anno::integer=ricevutaRec.oil_ricevuta_anno
            and   cassa.provc_numero::integer=ricevutaRec.oil_ricevuta_numero
            and   cassa.provc_tipo_id=(case when ricevutaRec.oil_ricevuta_tipo='U' then provCTipoSpesaId else provCTipoEntrataId END)
            and   cassa.data_cancellazione is null
            and   cassa.validita_fine is null;

            if codResult is not null then
            	codErroreId:=provvCEsisteCodeErrId;
                provCId:=codResult;
        	end if;
		elsif ricevutaRec.oil_provc_id=-1 then
        	strMessaggio:='Verifica esistenza provvisorio di cassa prima di operazione storno [mif_t_oil_ricevuta] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
			select cassa.provc_id, cassa.provc_data_annullamento, cassa.provc_importo
                 into codResult, dataAnnullamento, importoProvvisorio
            from siac_t_prov_cassa cassa
            where cassa.ente_proprietario_id=enteProprietarioId
            and   cassa.provc_anno::integer=ricevutaRec.oil_ricevuta_anno
            and   cassa.provc_numero::integer=ricevutaRec.oil_ricevuta_numero
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

            raise notice 'codResult=%',codResult;
            raise notice 'codErroreId=%',codErroreId;

        --    if codErroreId is null then
	            provCId:=codResult;
                ricevutaRec.oil_provc_id:=codResult;

--                raise notice 'provCId=%',provCId;

--                raise notice 'ricevutaRec.oil_provc_id=%',ricevutaRec.oil_provc_id;

         --   end if;

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
          -- 07.11.2018 Sofia siac-6351
          oil_ricevuta_conto_evidenza,
          oil_ricevuta_conto_evidenza_desc,
          -- 07.11.2018 Sofia siac-6351
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
          -- 07.11.2018 Sofia siac-6351
          ricevutaRec.oil_ricevuta_conto_evidenza,
          ricevutaRec.oil_ricevuta_conto_evidenza_desc,
          -- 07.11.2018 Sofia siac-6351
       	  ricevutaRec.oil_ricevuta_tipo,
          ricevutaRec.oil_ricevuta_tipo_id,
          codErroreId, -- solo per provvCEsisteCodeErrId
          flussoElabMifId,
          ricevutaRec.oil_progr_ricevuta_id,
          clock_timestamp(),
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
             -- 07.11.2018 Sofia siac-6351
             provc_conto_evidenza,
             provc_conto_evidenza_desc,
             -- 07.11.2018 Sofia siac-6351
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
             -- 07.11.2018 Sofia siac-6351
             ricevutaRec.oil_ricevuta_conto_evidenza,
             ricevutaRec.oil_ricevuta_conto_evidenza_desc,
             -- 07.11.2018 Sofia siac-6351
             (case when ricevutaRec.oil_ricevuta_tipo='U' then provCTipoSpesaId else provCTipoEntrataId END),
             clock_timestamp(),
             loginOperazione,
             enteProprietarioId
            )
            returning provc_id into provCId;

    --        raise notice 'strMessaggio=%',strMessaggio;
    --        raise notice 'provCId=%',provCId;
            if provCId is null then
            	raise exception ' Errore in inserimento.';
            end if;
         else
        	strMessaggio:='Aggiornamento provvissorio di cassa per storno [siac_t_prov_cassa] RR.ID='||ricevutaRec.oil_progr_ricevuta_id||'.';
        	update siac_t_prov_cassa set
               provc_importo=provc_importo-ricevutaRec.oil_ricevuta_importo,
               data_modifica=clock_timestamp(),
               login_operazione=loginOperazione,
               provc_data_annullamento=(case when provc_importo-ricevutaRec.oil_ricevuta_importo=0 then clock_timestamp() else null end)
            where provc_id=ricevutaRec.oil_provc_id;

            provCId:=  ricevutaRec.oil_provc_id;

    --        raise notice 'strMessaggio=%',strMessaggio;
    --        raise notice 'provCId=%',provCId;
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
          clock_timestamp(),
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

-- 20.02.2019 Sofia SIAC-6642 - fine

-- 21.02.2019 Sofia SIAC-6683 - inizio 

drop function if exists fnc_fasi_bil_gest_apertura_pluri_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  tipocapitologest varchar,
  tipomovgest varchar,
  tipomovgestts varchar,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists fnc_siac_dicuiimpegnatoup_comp_anno_fasi (
  id_in integer,
  anno_in varchar,
  faseEP boolean    -- true = fase di Esercizio Provvisorio
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  tipocapitologest varchar,
  tipomovgest varchar,
  tipomovgestts varchar,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;

    movGestRec        record;
    aggProgressivi    record;


	movgestTsTipoDetIniz integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetAtt  integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetUtil integer; -- 29.01.2018 Sofia siac-5830

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';
	SIM_MOVGEST_TS_TIPO CONSTANT varchar:='SIM';
    SAC_MOVGEST_TS_TIPO CONSTANT varchar:='SAC';


    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

	-- 14.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    INIZ_MOVGEST_TS_DET_TIPO  constant varchar:='I'; -- 29.01.2018 Sofia siac-5830
    ATT_MOVGEST_TS_DET_TIPO   constant varchar:='A'; -- 29.01.2018 Sofia siac-5830
    UTI_MOVGEST_TS_DET_TIPO   constant varchar:='U'; -- 29.01.2018 Sofia siac-5830

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    raise notice 'fnc_fasi_bil_gest_apertura_pluri_elabora tipoCapitoloGest=%',tipoCapitoloGest;

	if tipoMovGest=IMP_MOVGEST_TIPO then
    	 movGestTsTipoCode=SIM_MOVGEST_TS_TIPO;
    else movGestTsTipoCode=SAC_MOVGEST_TS_TIPO;
    end if;

    dataInizioVal:= clock_timestamp();
--    dataEmissione:=((annoBilancio-1)::varchar||'-12-31')::timestamp; -- da capire che data impostare come data emissione
    -- 23.08.2016 Sofia in attesa di indicazioni diverse ho deciso di impostare il primo di gennaio del nuovo anno di bilancio
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;
--    raise notice 'fasbilElabId %',faseBilElabId;
	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora tipoMovGest='||tipoMovGest||' minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_pluri.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_pluri fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna movimento da creare.';
    end if;


    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_pluri].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_pluri_id) into maxId
        from fase_bil_t_gest_apertura_pluri fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null;
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;


     strMessaggio:='Lettura id identificativo per tipo capitolo='||tipoCapitoloGest||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=tipoCapitoloGest
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



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

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I,A
     strMessaggio:='Lettura id identificativo per tipoMovGest='||tipoMovGest||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=tipoMovGest
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
          movGestTsTipoId:=tipoMovGestTsTId;
     else movGestTsTipoId:=tipoMovGestTsSId;
     end if;

     if movGestTsTipoId is null then
      strMessaggio:='Lettura identificativo per tipoMovGestTs='||tipoMovGestTs||'.';
      select tipo.movgest_ts_tipo_id into strict movGestTsTipoId
      from siac_d_movgest_ts_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.movgest_ts_tipo_code=tipoMovGestTs
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
     end if;


	 -- 14.02.2017 Sofia SIAC-4425
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;
     end if;

	 -- 29.01.2018 Sofia siac-5830
     strMessaggio:='Lettura identificativo per tipo importo='||INIZ_MOVGEST_TS_DET_TIPO||'.';
     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetIniz
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=INIZ_MOVGEST_TS_DET_TIPO;

     strMessaggio:='Lettura identificativo per tipo importo='||ATT_MOVGEST_TS_DET_TIPO||'.';

     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetAtt
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=ATT_MOVGEST_TS_DET_TIPO;

--	 if tipoMovGest=ACC_MOVGEST_TIPO then
     	 strMessaggio:='Lettura identificativo per tipo importo='||UTI_MOVGEST_TS_DET_TIPO||'.';
		 select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetUtil
    	 from siac_d_movgest_ts_det_tipo tipo
	     where tipo.ente_proprietario_id=enteProprietarioId
    	 and   tipo.movgest_ts_det_tipo_code=UTI_MOVGEST_TS_DET_TIPO;
  --   end if;
     -- 29.01.2018 Sofia siac-5830



     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- se impegno-accertamento verifico che i relativi capitoli siano presenti sul nuovo Bilancio
     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. INIZIO.';
	   	codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
       	 validita_inizio, login_operazione, ente_proprietario_id
      	)
      	values
      	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      	returning fase_bil_elab_log_id into codResult;

      	if codResult is null then
     		raise exception ' Errore in inserimento LOG.';
      	end if;

        update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='IMAC1',
            scarto_desc='Movimento impegno/accertamento pluriennale privo di capitolo nel nuovo bilancio'
      	from siac_t_bil_elem elem
      	where fase.fase_bil_elab_id=faseBilElabId
      	and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      	and   fase.movgest_tipo=movGestTsTipoCode
     	and   fase.fl_elab='N'
        and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
     	and   elem.ente_proprietario_id=fase.ente_proprietario_id
        and   elem.elem_id=fase.elem_orig_id
    	and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
     	and   elem.data_cancellazione is null
     	and   elem.validita_fine is null
        and   not exists (select 1 from siac_t_bil_elem elemnew
                          where elemnew.ente_proprietario_id=elem.ente_proprietario_id
                          and   elemnew.elem_tipo_id=elem.elem_tipo_id
                          and   elemnew.bil_id=bilancioId
                          and   elemnew.elem_code=elem.elem_code
                          and   elemnew.elem_code2=elem.elem_code2
                          and   elemnew.elem_code3=elem.elem_code3
                          and   elemnew.data_cancellazione is null
                          and   elemnew.validita_fine is null
                         );


        strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. FINE.';
	   	codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
       	 validita_inizio, login_operazione, ente_proprietario_id
      	)
      	values
      	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      	returning fase_bil_elab_log_id into codResult;

      	if codResult is null then
     		raise exception ' Errore in inserimento LOG.';
      	end if;

     end if;
     -- se sub, verifico prima se i relativi padri sono stati elaborati e creati
     -- se non sono stati ribaltati scarto  i relativi sub per escluderli da elaborazione

     if tipoMovGestTs=MOVGEST_TS_S_TIPO then
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. INIZIO.';
	  codResult:=null;
	  insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
       validita_inizio, login_operazione, ente_proprietario_id
      )
      values
      (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

      if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
      end if;

      update fase_bil_t_gest_apertura_pluri fase
      set fl_elab='X',
          scarto_code='SUB1',
          scarto_desc='Movimento sub impegno/accertamento pluriennale privo di impegno/accertamento pluri nel nuovo bilancio'
      from siac_t_movgest mprec
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   fase.movgest_tipo=movGestTsTipoCode
      and   fase.fl_elab='N'
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   mprec.ente_proprietario_id=fase.ente_proprietario_id
      and   mprec.movgest_id=fase.movgest_orig_id
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   mprec.data_cancellazione is null
      and   mprec.validita_fine is null
      and   not exists (select 1 from siac_t_movgest mnew
                        where mnew.ente_proprietario_id=mprec.ente_proprietario_id
                        and   mnew.movgest_tipo_id=mprec.movgest_tipo_id
                        and   mnew.bil_id=bilancioId
                        and   mnew.movgest_anno=mprec.movgest_anno
                        and   mnew.movgest_numero=mprec.movgest_numero
                        and   mnew.data_cancellazione is null
                        and   mnew.validita_fine is null
                        );
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. FINE.';
	  codResult:=null;
	  insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
       validita_inizio, login_operazione, ente_proprietario_id
      )
      values
      (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

      if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
      end if;

     end if;

     strMessaggio:='Inizio ciclo per tipoMovGest='||tipoMovGest||' tipoMovGestTs='||tipoMovGestTs||'.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     for movGestRec in
     (select tipo.movgest_tipo_code,
     		 m.*,
             tstipo.movgest_ts_tipo_code,
             ts.*,
             fase.fase_bil_gest_ape_pluri_id,
             fase.movgest_orig_id,
             fase.movgest_orig_ts_id,
             fase.elem_orig_id,
             mpadre.movgest_id movgest_id_new,
             tspadre.movgest_ts_id movgest_ts_id_padre_new
      from  fase_bil_t_gest_apertura_pluri fase
             join siac_t_movgest m
               left outer join
               ( siac_t_movgest mpadre join  siac_t_movgest_ts tspadre
                   on (tspadre.movgest_id=mpadre.movgest_id
                   and tspadre.movgest_ts_tipo_id=tipoMovGestTsTId
                   and tspadre.data_cancellazione is null
                   and tspadre.validita_fine is null)
                )
                on (mpadre.movgest_anno=m.movgest_anno
                and mpadre.movgest_numero=m.movgest_numero
                and mpadre.bil_id=bilancioId
                and mpadre.ente_proprietario_id=m.ente_proprietario_id
                and mpadre.movgest_tipo_id = tipoMovGestId
                and mpadre.data_cancellazione is null
                and mpadre.validita_fine is null)
             on   ( m.ente_proprietario_id=fase.ente_proprietario_id  and   m.movgest_id=fase.movgest_orig_id),
            siac_d_movgest_tipo tipo,
            siac_t_movgest_ts ts,
            siac_d_movgest_ts_tipo tstipo
      where fase.fase_bil_elab_id=faseBilElabId
          and   tipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tipo.movgest_tipo_code=tipoMovGest
          and   tstipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tstipo.movgest_ts_tipo_code=tipoMovGestTs
          and   m.ente_proprietario_id=fase.ente_proprietario_id
          and   m.movgest_id=fase.movgest_orig_id
          and   m.movgest_tipo_id=tipo.movgest_tipo_id
          and   ts.ente_proprietario_id=fase.ente_proprietario_id
          and   ts.movgest_ts_id=fase.movgest_orig_ts_id
          and   ts.movgest_ts_tipo_id=tstipo.movgest_ts_tipo_id
          and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
          and   fase.fl_elab='N'
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          order by fase_bil_gest_ape_pluri_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        codResult:=null;
		elemNewId:=null;

        strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
         raise notice 'strMessaggio=%  movGestRec.movgest_id_new=%', strMessaggio, movGestRec.movgest_id_new;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

    	codResult:=null;
        if movGestRec.movgest_id_new is null then
      	 strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                       ' anno='||movGestRec.movgest_anno||
                       ' numero='||movGestRec.movgest_numero||' [siac_t_movgest].';
     	 insert into siac_t_movgest
         (movgest_anno,
		  movgest_numero,
		  movgest_desc,
		  movgest_tipo_id,
		  bil_id,
		  validita_inizio,
	      ente_proprietario_id,
	      login_operazione,
	      parere_finanziario,
	      parere_finanziario_data_modifica,
	      parere_finanziario_login_operazione)
         values
         (movGestRec.movgest_anno,
		  movGestRec.movgest_numero,
		  movGestRec.movgest_desc,
		  movGestRec.movgest_tipo_id,
		  bilancioId,
		  dataInizioVal,
	      enteProprietarioId,
	      loginOperazione,
	      movGestRec.parere_finanziario,
	      movGestRec.parere_finanziario_data_modifica,
	      movGestRec.parere_finanziario_login_operazione
         )
         returning movgest_id into movGestIdRet;
         if movGestIdRet is null then
           strMessaggioTemp:=strMessaggio;
           codResult:=-1;
         end if;
			raise notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movGestIdRet;
		 if codResult is null then
         strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';

         raise notice 'strMessaggio=%',strMessaggio;

         select  new.elem_id into elemNewId
         from siac_r_movgest_bil_elem r,
              siac_t_bil_elem prec, siac_t_bil_elem new
         where r.movgest_id=movGestRec.movgest_orig_id
         and   prec.elem_id=r.elem_id
         and   new.elem_code=prec.elem_code
         and   new.elem_code2=prec.elem_code2
         and   new.elem_code3=prec.elem_code3
         and   prec.elem_tipo_id=new.elem_tipo_id
         and   prec.bil_id=bilancioPrecId
         and   new.bil_id=bilancioId
         and   r.data_cancellazione is null
         and   r.validita_fine is null
         and   prec.data_cancellazione is null
         and   prec.validita_fine is null
         and   new.data_cancellazione is null
         and   new.validita_fine is null;
         if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
         end if;
		 raise notice 'elemNewId=%',elemNewId;
		 if codResult is null then
          	  strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
             	            ' anno='||movGestRec.movgest_anno||
                 	        ' numero='||movGestRec.movgest_numero||' [siac_r_movgest_bil_elem]';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   elemNewId,
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
         end if;
        end if;
      else
        movGestIdRet:=movGestRec.movgest_id_new;
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';
        select  r.elem_id into elemNewId
        from siac_r_movgest_bil_elem r
        where r.movgest_id=movGestIdRet
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;
      end if;


      if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts].';
		raise notice 'strMessaggio=% ',strMessaggio;
/*        dataEmissione:=( (2018::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;*/

        -- 21.02.2019 Sofia SIAC-6683
        dataEmissione:=( (annoBilancio::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;
        raise notice 'dataEmissione=% ',dataEmissione;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        values
        ( movGestRec.movgest_ts_code,
          movGestRec.movgest_ts_desc,
          movGestIdRet,    -- inserito se I/A, per SUB ricavato
          movGestRec.movgest_ts_tipo_id,
          movGestRec.movgest_ts_id_padre_new,  -- valorizzato se SUB
          movGestRec.movgest_ts_scadenza_data,
          movGestRec.ordine,
          movGestRec.livello,
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataInizioVal else dataEmissione end), -- 25.11.2016 Sofia
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataEmissione else dataInizioVal end), -- 25.11.2016 Sofia
--          dataEmissione, -- 12.04.2017 Sofia
          dataEmissione,   -- 09.02.2018 Sofia
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          movGestRec.siope_tipo_debito_id,
		  movGestRec.siope_assenza_motivazione_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;
        raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;
       -- siac_r_liquidazione_movgest --> x pluriennali non dovrebbe esserci legame e andrebbe ricreato cmq con il ribaltamento delle liq
       -- siac_r_ordinativo_ts_movgest_ts --> x pluriennali non dovrebbe esistere legame in ogni caso non deve essere  ribaltato
       -- siac_r_movgest_ts --> legame da creare alla conclusione del ribaltamento dei pluriennali e dei residui

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        -- 29.01.2018 Sofia siac-5830 - insert sostituita con le tre successive


        /*insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );*/
        --returning movgest_ts_det_id into  codResult;

        -- 29.01.2018 Sofia siac-5830 - iniziale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetIniz,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - attuale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - utilizzabile = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetUtil,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );
--        returning movgest_classif_id into  codResult;

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;


        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );
        --returning bil_elem_attr_id into  codResult;

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

        /*select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        --returning movgest_atto_amm_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
         end if;
       end if;*/

       -- se movimento provvisorio atto_amm potrebbe non esserci
	   select 1  into codResult
       from siac_r_movgest_ts_atto_amm det1
       where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
       and   det1.data_cancellazione is null
       and   det1.validita_fine is null
       and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
			             where det.movgest_ts_id=movGestTsIdRet
					       and   det.data_cancellazione is null
					       and   det.validita_fine is null
					       and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning movgest_ts_sog_id into  codResult;

        /*select 1 into codResult
        from siac_r_movgest_ts_sog det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
          and   classe.data_cancellazione is null
          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning soggetto_classe_id into  codResult;

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_programma
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_programma].';

        insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning movgest_ts_programma_id into  codResult;
        /*select 1 into codResult
        from siac_r_movgest_ts_programma det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning mut_voce_movgest_id into  codResult;

        /*select 1 into codResult
        from siac_r_mutuo_voce_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa economale - da non ricreare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning gstmovgest_id into  codResult;

    /*    select 1 into codResult
        from siac_r_giustificativo_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_cartacont_det_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_causale_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning caus_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_causale_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_fondo_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning liq_movgest_id into  codResult;

       /* select 1 into codResult
        from siac_r_fondo_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_richiesta_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning riceconsog_id into  codResult;

       /* select 1 into codResult
        from siac_r_richiesta_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_subdoc_movgest_ts].';

        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

       /* select 1 into codResult
        from siac_r_subdoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning predoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_predoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- cancellazione logica relazioni anno precedente
       -- siac_r_cartacont_det_movgest_ts
/*  non si gestisce in seguito ad indicazioni con Annalina
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' . Cancellazione siac_r_cartacont_det_movgest_ts anno bilancio precedente.';

        update siac_r_cartacont_det_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_cartacont_det_movgest_ts r,	siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if codResult is not null then
        	 strMessaggioTemp:=strMessaggio;
        	 codResult:=-1;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/


       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_pluri per scarto
	   if codResult=-1 then
       	/*if movGestRec.movgest_id_new is null then
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        end if; spostato sotto */

        if movGestTsIdRet is not null then
         -- siac_t_movgest_ts
 	    /*strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet; spostato sotto */

         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
         -- siac_r_mutuo_voce_movgest
/*
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet;*/
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if movGestRec.movgest_id_new is null then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;


        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='PLUR1',
            scarto_desc='Movimento impegno/accertamento sub  pluriennale non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

		continue;
       end if;

	   -- annullamento relazioni movimenti precedenti
       -- siac_r_subdoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             --strMessaggioTemp:=strMessaggio;
             raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
--             strMessaggioTemp:=strMessaggio;
               raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'. Aggiornamento fase_bil_t_gest_apertura_pluri per fine elaborazione.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='S',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet,
            elem_id=elemNewId,
            bil_id=bilancioId
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

       strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


     -- aggiornamento progressivi
	 if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	 strMessaggio:='Aggiornamento progressivi.';
		 select * into aggProgressivi
   		 from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGest, loginOperazione);
	     if aggProgressivi.codresult=-1 then
			RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
     	 end if;
     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     	INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'N',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
        and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null);

        -- insert S per impegni mov.movgest_anno::integer=annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
		INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'S',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::integer=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null)
        and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
						 where ra.movgest_ts_id=ts.movgest_ts_id
						 and   atto.attoamm_id=ra.attoamm_id
				 		 and   atto.attoamm_anno::integer < annoBilancio
		     			 and   ra.data_cancellazione is null
				         and   ra.validita_fine is null);

        -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
		update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
		and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atto amministrativo antecedente.';
        update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts,
		     siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::INTEGER=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   ra.movgest_ts_id=ts.movgest_ts_id
		and   atto.attoamm_id=ra.attoamm_id
		and   atto.attoamm_anno::integer < annoBilancio
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        and   ra.data_cancellazione is null
        and   ra.validita_fine is null;

     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-2.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_siac_dicuiimpegnatoup_comp_anno_fasi (
  id_in integer,
  anno_in varchar,
  faseEP boolean    -- true = fase di Esercizio Provvisorio
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

FASE_OP_BIL_PREV constant VARCHAR:='P';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';


strMessaggio varchar(1500):=NVL_STR;


bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestStatoId1 integer:=0; -- DAVIDE - 03.10.2016 aggiunta filtro su movimenti provvisori
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;


movGestIdRec record;

elemTipoCode VARCHAR(20):=NVL_STR;
faseOpCode varchar(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;

elemIdGestEq integer:=0;
bilIdElemGestEq integer:=0;

BEGIN

 raise notice 'fnc_siac_dicuiimpegnatoup_comp_anno_fasi anno_in=% faseEP=%',anno_in, faseEP;

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
 raise notice 'faseOpCode =% ',faseOpCode;

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

                  --- 06.10.2016 Sofia
                  faseEP:=false;
    else
        	bilIdElemGestEq:=bilancioId;
            --- 06.10.2016 Sofia
            faseEP:=true;
    end if;
 else
	 RAISE EXCEPTION '% Fase non valida.',strMessaggio;
 end if;
 raise notice 'bilancioId=% ',bilIdElemGestEq;
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

-- DAVIDE - 03.10.2016 aggiunta filtro su movimenti provvisori
 select movGestStato.movgest_stato_id into strict movGestStatoId1
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

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
    raise notice 'Dentro loop impegni ';

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    if faseEP =  false then
        raise notice 'calcolo faseEP=% movGestTsId anno_id=%',faseEP,anno_in;
        select movGestTs.movgest_ts_id into  movGestTsId
          from siac_t_movgest_ts movGestTs
         where movGestTs.movgest_id = movGestIdRec.movgest_id
           and movGestTs.data_cancellazione is null
           and movGestTs.movgest_ts_tipo_id=movGestTsTipoId
           and exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                        where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                         -- and movGestTsRel.movgest_stato_id!=movGestStatoId); DAVIDE - 03.10.2016 aggiunta filtro su movimenti provvisori
                          and movGestTsRel.movgest_stato_id not in (movGestStatoId, movGestStatoId1)
                          and movGestTsRel.data_cancellazione is null
                          and movGestTsRel.validita_fine is NULL);  -- 05.10.2016 Sofia
    else
	    -- in fase di Esercizio Provvisorio, si esegue la query con il filtro
		-- sulla data_emissione (validita_inizio)

        raise notice 'calcolo movGestTsId anno_id=%',anno_in;

        select movGestTs.movgest_ts_id into  movGestTsId
          from siac_t_movgest_ts movGestTs
         where movGestTs.movgest_id = movGestIdRec.movgest_id
           and movGestTs.data_cancellazione is null
           and movGestTs.movgest_ts_tipo_id=movGestTsTipoId
		-- Sofia   and movGestTs.validita_inizio='01/01/'||anno_in
--           and movGestTs.validita_inizio=(anno_in||'-01-01')::timestamp
--           and movGestTs.validita_inizio=(annoBilancio||'-01-01')::timestamp -- 21.02.2019 Sofia SIAC-6683
-- 21.02.2019 Sofia SIAC-6683
           and date_trunc('DAY',movGestTs.validita_inizio)=date_trunc('DAY',(annoBilancio||'-01-01')::timestamp)
           and exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                        where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                         -- and movGestTsRel.movgest_stato_id!=movGestStatoId); DAVIDE - 03.10.2016 aggiunta filtro su movimenti provvisori
                          and movGestTsRel.movgest_stato_id not in (movGestStatoId, movGestStatoId1)
                          and movGestTsRel.data_cancellazione is null  -- 05.10.2016 Sofia
                          and movGestTsRel.validita_fine is null);

         raise notice 'movGestTsId=% ',movGestTsId;
    end if;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
				      ||'.Per elemento gest equivalente elem_id='||elemIdGestEq
                      ||'.Calcolo accertato anno_in='||anno_in||'.Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;
end if;

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


-- 21.02.2019 Sofia SIAC-6683 - fine 

-- SIAC-6331: Maurizio - INIZIO

/*
CONFIGURAZIONE REPORT BILR217 per Regione ed Enti REGIONALI
Sono da escludere in questa configurazione gli enti locali:
	ENTI LOCALI = (1,3,8,15,29,30,31,32,33)
	
*/

	
INSERT INTO siac_t_report (
	rep_codice,  
	rep_desc,
  	rep_birt_codice ,
  	validita_inizio ,
  	validita_fine,
  	ente_proprietario_id,
  	data_creazione,
  	data_modifica,
  	data_cancellazione,
  	login_operazione)
SELECT 'BILR217',
	'All. 9 - Equilibri di Bilancio Regione Assestamento (BILR217)',
    'BILR217_equilibri_bilancio_regione_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
	and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR217');    
      


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_sc_assest',
	'01) Utilizzo risultato di amministrazione presunto per il finanziamento di spese correnti e al rimborso di prestiti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_sc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'rip_dis_prec_assest',
	'02) Ripiano disavanzo presunto di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='rip_dis_prec_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'fpv_vinc_sc_assest',
	'03) Fondo pluriennale vincolato per spese correnti iscritto in entrata',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_vinc_sc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_cc_contib_invest_assest',
	'04) Entrate in conto capitale per Contributi agli investimenti direttamente destinati al rimborso dei prestiti da amministrazioni pubbliche',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_cc_contib_invest_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_est_prestiti_cc_assest',
	'05) Entrate in c/capitale destinate all''estinzione anticipata di prestiti',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_est_prestiti_cc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_est_prestiti_assest',
	'06) Entrate per accensioni di prestiti destinate all''estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_est_prestiti_assest');


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_disp_legge_assest',
	'07) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_disp_legge_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_fpv_sc_assest',
	'08) Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fpv_sc_assest');

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'rimb_prestiti_assest',
	'09) Rimborso prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='rimb_prestiti_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_ant_liq_assest',
	'10) Rimborso prestiti - di cui Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ant_liq_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_est_ant_pre_assest',
	'11) Rimborso prestiti - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_est_ant_pre_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_si_assest',
	'12) Utilizzo risultato presunto di amministrazione per il finanziamento di spese d''investimento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_si_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'fpv_vinc_cc_assest',
	'13) Fondo pluriennale vincolato per spese in conto capitale iscritto in entrata',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_vinc_cc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_fpv_cc_assest',
	'14) Spese in conto capitale - di cui fondo pluriennale vincolato',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fpv_cc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'disava_pregr_assest',
	'15) Disavanzo pregresso derivante da debito autorizzato e non contratto (presunto)',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='disava_pregr_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                  
SELECT 'variaz_att_finanz_assest',
    '16) Variazioni di attivita'' finanziarie (se positivo)',
    '0',
    'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='variaz_att_finanz_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_af_assest',
	'17) Utilizzo risultato presunto di amministrazione vincolato al finanziamento di attivita'' finanziarie',
	'0',
	'N',
	17,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_af_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_fpv_sc_assest',
	'18) Fondo pluriennale vincolato per spese correnti iscritto in entrata al netto delle componenti non vincolate derivanti dal riaccertamento ord.',
	'0',
	'N',
	18,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_fpv_sc_assest');
	 
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_entrate_tit123_vinc_dest_assest',
	'19) Entrate titoli 1-2-3 non sanitarie con specifico vincolo di destinazione',
	'0',
	'N',
	19,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_entrate_tit123_vinc_dest_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_entrate_tit123_ssn_assest',
	'20) Entrate titoli 1-2-3 destinate al finanziamento del SSN',
	'0',
	'N',
	20,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_entrate_tit123_ssn_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_spese_vinc_dest_assest',
	'21) Spese correnti non sanitarie finanziate da entrate con specifico vincolo di destinazione',
	'0',
	'N',
	21,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_spese_vinc_dest_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_fpv_pc_assest',
	'22) Fondo pluriennale vincolato di parte corrente (di spesa) al netto delle componenti non vincolate derivanti dal riaccertamento ord.',
	'0',
	'N',
	22,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_fpv_pc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_sc_ssn_assest',
	'23) Spese correnti finanziate da entrate destinate al SSN',
	'0',
	'N',
	23,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_sc_ssn_assest');
	  

      

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_sc_assest',
	'01) Utilizzo risultato di amministrazione presunto per il finanziamento di spese correnti e al rimborso di prestiti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_sc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'rip_dis_prec_assest',
	'02) Ripiano disavanzo presunto di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='rip_dis_prec_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'fpv_vinc_sc_assest',
	'03) Fondo pluriennale vincolato per spese correnti iscritto in entrata',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_vinc_sc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_cc_contib_invest_assest',
	'04) Entrate in conto capitale per Contributi agli investimenti direttamente destinati al rimborso dei prestiti da amministrazioni pubbliche',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_cc_contib_invest_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_est_prestiti_cc_assest',
	'05) Entrate in c/capitale destinate all''estinzione anticipata di prestiti',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_est_prestiti_cc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_est_prestiti_assest',
	'06) Entrate per accensioni di prestiti destinate all''estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_est_prestiti_assest');


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_disp_legge_assest',
	'07) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_disp_legge_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_fpv_sc_assest',
	'08) Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fpv_sc_assest');

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'rimb_prestiti_assest',
	'09) Rimborso prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='rimb_prestiti_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_ant_liq_assest',
	'10) Rimborso prestiti - di cui Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ant_liq_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_est_ant_pre_assest',
	'11) Rimborso prestiti - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_est_ant_pre_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_si_assest',
	'12) Utilizzo risultato presunto di amministrazione per il finanziamento di spese d''investimento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_si_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'fpv_vinc_cc_assest',
	'13) Fondo pluriennale vincolato per spese in conto capitale iscritto in entrata',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_vinc_cc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_fpv_cc_assest',
	'14) Spese in conto capitale - di cui fondo pluriennale vincolato',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fpv_cc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'disava_pregr_assest',
	'15) Disavanzo pregresso derivante da debito autorizzato e non contratto (presunto)',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='disava_pregr_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'variaz_att_finanz_assest',
	'16) Variazioni di attivita'' finanziarie (se positivo)',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='variaz_att_finanz_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_af_assest',
	'17) Utilizzo risultato presunto di amministrazione vincolato al finanziamento di attivita'' finanziarie',
	'0',
	'N',
	17,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_af_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_fpv_sc_assest',
	'18) Fondo pluriennale vincolato per spese correnti iscritto in entrata al netto delle componenti non vincolate derivanti dal riaccertamento ord.',
	'0',
	'N',
	18,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_fpv_sc_assest');
	 
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_entrate_tit123_vinc_dest_assest',
	'19) Entrate titoli 1-2-3 non sanitarie con specifico vincolo di destinazione',
	'0',
	'N',
	19,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_entrate_tit123_vinc_dest_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_entrate_tit123_ssn_assest',
	'20) Entrate titoli 1-2-3 destinate al finanziamento del SSN',
	'0',
	'N',
	20,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_entrate_tit123_ssn_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_spese_vinc_dest_assest',
	'21) Spese correnti non sanitarie finanziate da entrate con specifico vincolo di destinazione',
	'0',
	'N',
	21,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_spese_vinc_dest_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_fpv_pc_assest',
	'22) Fondo pluriennale vincolato di parte corrente (di spesa) al netto delle componenti non vincolate derivanti dal riaccertamento ord.',
	'0',
	'N',
	22,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_fpv_pc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_sc_ssn_assest',
	'23) Spese correnti finanziate da entrate destinate al SSN',
	'0',
	'N',
	23,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_sc_ssn_assest');
	  


      

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_sc_assest',
	'01) Utilizzo risultato di amministrazione presunto per il finanziamento di spese correnti e al rimborso di prestiti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_sc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'rip_dis_prec_assest',
	'02) Ripiano disavanzo presunto di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='rip_dis_prec_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'fpv_vinc_sc_assest',
	'03) Fondo pluriennale vincolato per spese correnti iscritto in entrata',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_vinc_sc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_cc_contib_invest_assest',
	'04) Entrate in conto capitale per Contributi agli investimenti direttamente destinati al rimborso dei prestiti da amministrazioni pubbliche',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_cc_contib_invest_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_est_prestiti_cc_assest',
	'05) Entrate in c/capitale destinate all''estinzione anticipata di prestiti',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_est_prestiti_cc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_est_prestiti_assest',
	'06) Entrate per accensioni di prestiti destinate all''estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_est_prestiti_assest');


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_disp_legge_assest',
	'07) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_disp_legge_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_fpv_sc_assest',
	'08) Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fpv_sc_assest');

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'rimb_prestiti_assest',
	'09) Rimborso prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='rimb_prestiti_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_ant_liq_assest',
	'10) Rimborso prestiti - di cui Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_ant_liq_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_est_ant_pre_assest',
	'11) Rimborso prestiti - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_est_ant_pre_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_si_assest',
	'12) Utilizzo risultato presunto di amministrazione per il finanziamento di spese d''investimento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_si_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'fpv_vinc_cc_assest',
	'13) Fondo pluriennale vincolato per spese in conto capitale iscritto in entrata',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_vinc_cc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_fpv_cc_assest',
	'14) Spese in conto capitale - di cui fondo pluriennale vincolato',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_fpv_cc_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'disava_pregr_assest',
	'15) Disavanzo pregresso derivante da debito autorizzato e non contratto (presunto)',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='disava_pregr_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'variaz_att_finanz_assest',
	'16) Variazioni di attivita'' finanziarie (se positivo)',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='variaz_att_finanz_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ava_amm_af_assest',
	'17) Utilizzo risultato presunto di amministrazione vincolato al finanziamento di attivita'' finanziarie',
	'0',
	'N',
	17,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ava_amm_af_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_fpv_sc_assest',
	'18) Fondo pluriennale vincolato per spese correnti iscritto in entrata al netto delle componenti non vincolate derivanti dal riaccertamento ord.',
	'0',
	'N',
	18,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_fpv_sc_assest');
	 
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_entrate_tit123_vinc_dest_assest',
	'19) Entrate titoli 1-2-3 non sanitarie con specifico vincolo di destinazione',
	'0',
	'N',
	19,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_entrate_tit123_vinc_dest_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_entrate_tit123_ssn_assest',
	'20) Entrate titoli 1-2-3 destinate al finanziamento del SSN',
	'0',
	'N',
	20,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_entrate_tit123_ssn_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_spese_vinc_dest_assest',
	'21) Spese correnti non sanitarie finanziate da entrate con specifico vincolo di destinazione',
	'0',
	'N',
	21,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_spese_vinc_dest_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_fpv_pc_assest',
	'22) Fondo pluriennale vincolato di parte corrente (di spesa) al netto delle componenti non vincolate derivanti dal riaccertamento ord.',
	'0',
	'N',
	22,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_fpv_pc_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 's_sc_ssn_assest',
	'23) Spese correnti finanziate da entrate destinate al SSN',
	'0',
	'N',
	23,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='s_sc_ssn_assest');
	  


--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR217'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and a.repimp_codice in ('ava_amm_sc_assest',
'rip_dis_prec_assest',
'fpv_vinc_sc_assest',
'ent_cc_contib_invest_assest',
'ent_est_prestiti_cc_assest',
'ent_est_prestiti_assest',
'ent_disp_legge_assest',
'di_cui_fpv_sc_assest',
'rimb_prestiti_assest',
'di_cui_ant_liq_assest',
'di_cui_est_ant_pre_assest',
'ava_amm_si_assest',
'fpv_vinc_cc_assest',
'di_cui_fpv_cc_assest',
'disava_pregr_assest',
'variaz_att_finanz_assest',
'ava_amm_af_assest',
's_fpv_sc_assest',
's_entrate_tit123_vinc_dest_assest',
's_entrate_tit123_ssn_assest',
's_spese_vinc_dest_assest',
's_fpv_pc_assest',
's_sc_ssn_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
/* tabelle BKO */

INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR217', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR217');
    
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)    
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,0,
	b.repimp_modificabile, b.repimp_progr_riga
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
	and a.rep_codice='BILR217'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);	
	
/*
CONFIGURAZIONE REPORT BILR218 per Regione ed Enti REGIONALI
Sono da escludere in questa configurazione gli enti locali:
	ENTI LOCALI = (1,3,8,15,29,30,31,32,33)
	
*/

INSERT INTO siac_t_report (
	rep_codice,  
	rep_desc,
  	rep_birt_codice ,
  	validita_inizio ,
  	validita_fine,
  	ente_proprietario_id,
  	data_creazione,
  	data_modifica,
  	data_cancellazione,
  	login_operazione)
SELECT 'BILR218',
	'All. 9 - All d) Limiti debito Regione Assestamento (BILR218)',
    'BILR218_Allegato_D_Limiti_indebitamento_regioni_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
	and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR218');    
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_prest_prec_assest',
	'01) E) Ammontare rate per mutui e prestiti autorizzati fino al 31/12/ esercizio precedente',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_prec_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_prest_att_assest',
	'02) F) Ammontare rate per mutui e prestiti autorizzati nell''esercizio in corso',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_att_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_pot_deb_assest',
	'03) G) Ammontare rate relative a  mutui e prestiti che costituiscono debito potenziale',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_pot_deb_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_aut_legge_assest',
	'04) H) Ammontare rate per mutui e prestiti autorizzati con la Legge in esame',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_aut_legge_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'contr_erariali_assest',
	'05) I) Contributi erariali sulle rate di ammortamento dei mutui in essere al momento della sottoscrizione del finanziamento',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_debiti_assest',
	'06) L) Ammontare rate riguardanti debiti espressamente esclusi dai limiti di indebitamento',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_debiti_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_contratto_prec_assest',
	'07) Debito contratto al 31/12/ esercizio precedente',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_contratto_prec_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_autoriz_att_assest',
	'08) Debito autorizzato nell''esercizio in corso',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_att_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_autoriz_legge_assest',
	'09) Debito autorizzato dalla Legge in esame',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_legge_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'gar_princ_assest',
	'10) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='gar_princ_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_gar_princ_assest',
	'11) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti - di cui, garanzie per le quali e'' stato costituito accantonamento',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_gar_princ_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_assest');

	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_prest_prec_assest',
	'01) E) Ammontare rate per mutui e prestiti autorizzati fino al 31/12/ esercizio precedente',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_prec_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_prest_att_assest',
	'02) F) Ammontare rate per mutui e prestiti autorizzati nell''esercizio in corso',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_att_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_pot_deb_assest',
	'03) G) Ammontare rate relative a  mutui e prestiti che costituiscono debito potenziale',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_pot_deb_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_aut_legge_assest',
	'04) H) Ammontare rate per mutui e prestiti autorizzati con la Legge in esame',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_aut_legge_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'contr_erariali_assest',
	'05) I) Contributi erariali sulle rate di ammortamento dei mutui in essere al momento della sottoscrizione del finanziamento',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_debiti_assest',
	'06) L) Ammontare rate riguardanti debiti espressamente esclusi dai limiti di indebitamento',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_debiti_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_contratto_prec_assest',
	'07) Debito contratto al 31/12/ esercizio precedente',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_contratto_prec_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_autoriz_att_assest',
	'08) Debito autorizzato nell''esercizio in corso',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_att_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_autoriz_legge_assest',
	'09) Debito autorizzato dalla Legge in esame',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_legge_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'gar_princ_assest',
	'10) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='gar_princ_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_gar_princ_assest',
	'11) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti - di cui, garanzie per le quali e'' stato costituito accantonamento',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_gar_princ_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_assest');

	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_prest_prec_assest',
	'01) E) Ammontare rate per mutui e prestiti autorizzati fino al 31/12/ esercizio precedente',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_prec_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_prest_att_assest',
	'02) F) Ammontare rate per mutui e prestiti autorizzati nell''esercizio in corso',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_prest_att_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_pot_deb_assest',
	'03) G) Ammontare rate relative a  mutui e prestiti che costituiscono debito potenziale',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_pot_deb_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_aut_legge_assest',
	'04) H) Ammontare rate per mutui e prestiti autorizzati con la Legge in esame',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_aut_legge_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'contr_erariali_assest',
	'05) I) Contributi erariali sulle rate di ammortamento dei mutui in essere al momento della sottoscrizione del finanziamento',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'amm_rate_debiti_assest',
	'06) L) Ammontare rate riguardanti debiti espressamente esclusi dai limiti di indebitamento',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='amm_rate_debiti_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_contratto_prec_assest',
	'07) Debito contratto al 31/12/ esercizio precedente',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_contratto_prec_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_autoriz_att_assest',
	'08) Debito autorizzato nell''esercizio in corso',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_att_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_autoriz_legge_assest',
	'09) Debito autorizzato dalla Legge in esame',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_autoriz_legge_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'gar_princ_assest',
	'10) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='gar_princ_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_gar_princ_assest',
	'11) Garanzie principali o sussidiarie prestate dalla Regione a favore di altre Amministrazioni pubbliche e di altri soggetti - di cui, garanzie per le quali e'' stato costituito accantonamento',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_gar_princ_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_assest');


--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR218'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.ente_proprietario_id not in (1,3,8,15,29,30,31,32,33)
	and a.repimp_codice in ('amm_rate_prest_prec_assest',
	'amm_rate_prest_att_assest',
	'amm_rate_pot_deb_assest',
	'amm_rate_aut_legge_assest',
	'contr_erariali_assest',
	'amm_rate_debiti_assest',
	'deb_contratto_prec_assest',
	'deb_autoriz_att_assest',
	'deb_autoriz_legge_assest',
	'gar_princ_assest',
	'di_cui_gar_princ_assest',
	'garanzie_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
	  
/* tabelle BKO */
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR218', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR218');
    
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)    
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,0,
	b.repimp_modificabile, b.repimp_progr_riga
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
	and a.rep_codice='BILR218'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);	

/*
CONFIGURAZIONE REPORT BILR219 per ENTI LOCALI
Sono da escludere in questa configurazione la regione e gli enti Regionali.
	ENTI LOCALI = (1,3,8,15,29,30,31,32,33)
	
*/	


INSERT INTO siac_t_report (
	rep_codice,  
	rep_desc,
  	rep_birt_codice ,
  	validita_inizio ,
  	validita_fine,
  	ente_proprietario_id,
  	data_creazione,
  	data_modifica,
  	data_cancellazione,
  	login_operazione)
SELECT 'BILR219',
	'All. 9 - Equilibri di Bilancio EELL Assestamento (BILR219)',
    'BILR219_Equilibri_bilancio_EELL_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where  a.data_cancellazione IS NULL
	and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR219');  
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'A_assest',
	'01) A) Fondo pluriennale vincolato di entrata per spese correnti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='A_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'AA_assest',
	'02) AA) Recupero disavanzo di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='AA_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'B_di_cui_assest',
	'03) B)  Entrate Titoli 1.00 - 2.00 - 3.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='B_di_cui_assest');
	  


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'D_cui_fpv_assest',
	'04) D) Spese Titolo 1.00 - Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fpv_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'D_cui_fcde_assest',
	'05) D) Spese Titolo 1.00 - Spese correnti - di cui fondo crediti di dubbia esigibilita''',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fcde_assest');
	  


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'F_di_cui_ant_prest_assest',
	'06) F) Spese Titolo 4.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_ant_prest_assest');

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'F_di_cui_fondo_assest',
	'07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_fondo_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'H_assest',
	'08) H) Utilizzo risultato di amministrazione presunto per spese correnti',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'H_di_cui_assest',
	'09) H) Utilizzo risultato di amministrazione presunto per spese correnti - di  cui per estinzione anticipata di prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_di_cui_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'I_assest',
	'10) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_assest');	  
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'I_di_cui_assest',
	'11) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_di_cui_assest');	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'L_assest',
	'12) L) Entrate di parte corrente destinate a spese di investimento in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='L_assest');	 
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'M_assest',
	'13) M) Entrate da accensione di prestiti destinate a estinzione anticipata dei prestiti',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='M_assest');	 
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'P_assest',
	'14) P) Utilizzo risultato di amministrazione presunto per spese di investimento',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='P_assest');	 	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'Q_assest',
	'15) Q) Fondo pluriennale vincolato di entrata per spese in conto capitale',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='Q_assest');	 	

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'U_di_cui_assest',
	'16) U) Spese titolo 2.00 - di cui fondo pluriennale vincolato',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='U_di_cui_assest');	 	  
	  


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'A_assest',
	'01) A) Fondo pluriennale vincolato di entrata per spese correnti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='A_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'AA_assest',
	'02) AA) Recupero disavanzo di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='AA_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'B_di_cui_assest',
	'03) B)  Entrate Titoli 1.00 - 2.00 - 3.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='B_di_cui_assest');
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'D_cui_fpv_assest',
	'04) D) Spese Titolo 1.00 - Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fpv_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'D_cui_fcde_assest',
	'05) D) Spese Titolo 1.00 - Spese correnti - di cui fondo crediti di dubbia esigibilita''',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fcde_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'F_di_cui_ant_prest_assest',
	'06) F) Spese Titolo 4.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_ant_prest_assest');

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'F_di_cui_fondo_assest',
	'07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_fondo_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'H_assest',
	'08) H) Utilizzo risultato di amministrazione presunto per spese correnti',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'H_di_cui_assest',
	'09) H) Utilizzo risultato di amministrazione presunto per spese correnti - di  cui per estinzione anticipata di prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_di_cui_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'I_assest',
	'10) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_assest');	  
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'I_di_cui_assest',
	'11) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_di_cui_assest');	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'L_assest',
	'12) L) Entrate di parte corrente destinate a spese di investimento in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='L_assest');	 
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'M_assest',
	'13) M) Entrate da accensione di prestiti destinate a estinzione anticipata dei prestiti',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='M_assest');	 
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'P_assest',
	'14) P) Utilizzo risultato di amministrazione presunto per spese di investimento',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='P_assest');	 	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'Q_assest',
	'15) Q) Fondo pluriennale vincolato di entrata per spese in conto capitale',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='Q_assest');	 	

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'U_di_cui_assest',
	'16) U) Spese titolo 2.00 - di cui fondo pluriennale vincolato',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='U_di_cui_assest');	 	  
	  
	  


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'A_assest',
	'01) A) Fondo pluriennale vincolato di entrata per spese correnti',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='A_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'AA_assest',
	'02) AA) Recupero disavanzo di amministrazione esercizio precedente',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='AA_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'B_di_cui_assest',
	'03) B)  Entrate Titoli 1.00 - 2.00 - 3.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='B_di_cui_assest');
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'D_cui_fpv_assest',
	'04) D) Spese Titolo 1.00 - Spese correnti - di cui fondo pluriennale vincolato',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fpv_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'D_cui_fcde_assest',
	'05) D) Spese Titolo 1.00 - Spese correnti - di cui fondo crediti di dubbia esigibilita''',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='D_cui_fcde_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'F_di_cui_ant_prest_assest',
	'06) F) Spese Titolo 4.00 - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_ant_prest_assest');

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'F_di_cui_fondo_assest',
	'07) F) Spese Titolo 4.00 - di cui Fondo anticipazioni di liquidita'' (DL 35/2013 e successive modifiche e rifinanziamenti)',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='F_di_cui_fondo_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'H_assest',
	'08) H) Utilizzo risultato di amministrazione presunto per spese correnti',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'H_di_cui_assest',
	'09) H) Utilizzo risultato di amministrazione presunto per spese correnti - di  cui per estinzione anticipata di prestiti',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='H_di_cui_assest');
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'I_assest',
	'10) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_assest');	  
	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'I_di_cui_assest',
	'11) I) Entrate di parte capitale destinate a spese correnti in base a specifiche disposizioni di legge o dei principi contabili - di cui per estinzione anticipata di prestiti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='I_di_cui_assest');	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'L_assest',
	'12) L) Entrate di parte corrente destinate a spese di investimento in base a specifiche disposizioni di legge o dei principi contabili',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='L_assest');	 
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'M_assest',
	'13) M) Entrate da accensione di prestiti destinate a estinzione anticipata dei prestiti',
	'0',
	'N',
	13,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='M_assest');	 
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'P_assest',
	'14) P) Utilizzo risultato di amministrazione presunto per spese di investimento',
	'0',
	'N',
	14,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='P_assest');	 	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'Q_assest',
	'15) Q) Fondo pluriennale vincolato di entrata per spese in conto capitale',
	'0',
	'N',
	15,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='Q_assest');	 	

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'U_di_cui_assest',
	'16) U) Spese titolo 2.00 - di cui fondo pluriennale vincolato',
	'0',
	'N',
	16,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='U_di_cui_assest');	 	  
	  
	  

--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR219'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where  a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and a.repimp_codice in ('A_assest',
'AA_assest',
'B_di_cui_assest',
'D_cui_fcde_assest',
'D_cui_fpv_assest',
'F_di_cui_ant_prest_assest',
'F_di_cui_fondo_assest',
'H_assest',
'H_di_cui_assest',
'I_assest',
'I_di_cui_assest',
'L_assest',
'M_assest',
'P_assest',
'Q_assest',
'U_di_cui_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
	  
/* tabelle BKO */
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR219', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR219');
    
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)    
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,0,
	b.repimp_modificabile, b.repimp_progr_riga
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
	and a.rep_codice='BILR219'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);		  
	
/*
CONFIGURAZIONE REPORT BILR220 per ENTI LOCALI
Sono da escludere in questa configurazione la regione e gli enti Regionali.
	ENTI LOCALI = (1,3,8,15,29,30,31,32,33)
	
*/		

INSERT INTO siac_t_report (
	rep_codice,  
	rep_desc,
  	rep_birt_codice ,
  	validita_inizio ,
  	validita_fine,
  	ente_proprietario_id,
  	data_creazione,
  	data_modifica,
  	data_cancellazione,
  	login_operazione)
SELECT 'BILR220',
	'All. 9 - All d) Limiti debito EELL (BILR220)',
    'BILR220_Allegato_D_Limiti_indebitamento_EELL_assest',
    now(),
    NULL,
    ente_proprietario_id,
    now(),
    now(),
    NULL,
    'admin'
FROM siac_t_ente_proprietario a
	where a.data_cancellazione IS NULL
	and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
    and not exists (select 1 
      from siac_t_report z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.rep_codice='BILR220');  
	  

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_corr_nat_trib_tit1_assest',
	'01) 1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_corr_nat_trib_tit1_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'traf_correnti_tit2_assest',
	'02) 2) Trasferimenti correnti (titolo II)',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='traf_correnti_tit2_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_extratrib_tit3_assest',
	'03) 3) Entrate extratributarie (titolo III)',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_extratrib_tit3_assest');
	  

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_anno_prec_assest',
	'04) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati fino al 31/12/ esercizio precedente',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_anno_prec_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_anno_assest',
	'05) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati nell''esercizio in corso',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_anno_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'contr_erariali1_assest',
	'06) Contributi  erariali in c/interessi su mutui',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali1_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_deb_esclusi_assest',
	'07) Ammontare interessi riguardanti debiti espressamente esclusi dai limiti di indebitamento',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_deb_esclusi_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_anno_prec_assest',
	'08) Debito contratto al 31/12/ esercizio precedente',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_anno_prec_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_aut_anno_assest',
	'09) Debito autorizzato nell''esercizio in corso',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_aut_anno_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_prin_assest',
	'10) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_prin_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_garanzie_assest',
	'11) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_garanzie_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_lim_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2019'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_lim_assest');	  
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_corr_nat_trib_tit1_assest',
	'01) 1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_corr_nat_trib_tit1_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'traf_correnti_tit2_assest',
	'02) 2) Trasferimenti correnti (titolo II)',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='traf_correnti_tit2_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_extratrib_tit3_assest',
	'03) 3) Entrate extratributarie (titolo III)',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_extratrib_tit3_assest');
	  

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_anno_prec_assest',
	'04) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati fino al 31/12/ esercizio precedente',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_anno_prec_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_anno_assest',
	'05) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati nell''esercizio in corso',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_anno_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'contr_erariali1_assest',
	'06) Contributi  erariali in c/interessi su mutui',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali1_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_deb_esclusi_assest',
	'07) Ammontare interessi riguardanti debiti espressamente esclusi dai limiti di indebitamento',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_deb_esclusi_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_anno_prec_assest',
	'08) Debito contratto al 31/12/ esercizio precedente',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_anno_prec_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_aut_anno_assest',
	'09) Debito autorizzato nell''esercizio in corso',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_aut_anno_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_prin_assest',
	'10) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_prin_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_garanzie_assest',
	'11) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_garanzie_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_lim_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2020'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_lim_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_corr_nat_trib_tit1_assest',
	'01) 1) Entrate correnti di natura tributaria, contributiva e perequativa (Titolo I)',
	'0',
	'N',
	1,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_corr_nat_trib_tit1_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'traf_correnti_tit2_assest',
	'02) 2) Trasferimenti correnti (titolo II)',
	'0',
	'N',
	2,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='traf_correnti_tit2_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'ent_extratrib_tit3_assest',
	'03) 3) Entrate extratributarie (titolo III)',
	'0',
	'N',
	3,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='ent_extratrib_tit3_assest');
	  

	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_anno_prec_assest',
	'04) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati fino al 31/12/ esercizio precedente',
	'0',
	'N',
	4,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_anno_prec_assest');

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_anno_assest',
	'05) Ammontare interessi per mutui, prestiti obbligazionari, aperture di credito e garanzie di cui all''articolo 207 del TUEL autorizzati nell''esercizio in corso',
	'0',
	'N',
	5,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_anno_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'contr_erariali1_assest',
	'06) Contributi  erariali in c/interessi su mutui',
	'0',
	'N',
	6,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='contr_erariali1_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'inter_deb_esclusi_assest',
	'07) Ammontare interessi riguardanti debiti espressamente esclusi dai limiti di indebitamento',
	'0',
	'N',
	7,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='inter_deb_esclusi_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_anno_prec_assest',
	'08) Debito contratto al 31/12/ esercizio precedente',
	'0',
	'N',
	8,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_anno_prec_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'deb_aut_anno_assest',
	'09) Debito autorizzato nell''esercizio in corso',
	'0',
	'N',
	9,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='deb_aut_anno_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_prin_assest',
	'10) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	10,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_prin_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_garanzie_assest',
	'11) Garanzie principali o sussidiarie prestate dall''Ente a favore di altre Amministrazioni pubbliche e di altri soggetti',
	'0',
	'N',
	11,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='di_cui_garanzie_assest');
	  
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'garanzie_lim_assest',
	'12) Garanzie che concorrono al limite di indebitamento',
	'0',
	'N',
	12,
	a.bil_id,
    b2.periodo_id,
	now(),
	NULL,
	a.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'admin'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and  b2.anno = '2021'
and c2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='garanzie_lim_assest');
	  
	  
--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR220'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'admin' login_operazione
from   siac_t_report_importi a
where a.ente_proprietario_id in (1,3,8,15,29,30,31,32,33)
and a.repimp_codice in ('ent_corr_nat_trib_tit1_assest',
'traf_correnti_tit2_assest',
'ent_extratrib_tit3_assest',
'inter_anno_prec_assest',
'inter_anno_assest',
'contr_erariali1_assest',
'inter_deb_esclusi_assest',
'deb_anno_prec_assest',
'deb_aut_anno_assest',
'garanzie_prin_assest',
'di_cui_garanzie_assest',
'garanzie_lim_assest')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);
	  
	  
/* tabelle BKO */
INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,  rep_competenza_anni)
SELECT 'BILR220', 3
WHERE not exists (select 1 
	from BKO_T_REPORT_COMPETENZE
    where  rep_codice = 'BILR220');
    
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)    
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,0,
	b.repimp_modificabile, b.repimp_progr_riga
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c
where a.rep_id=c.rep_id
	and b.repimp_id=c.repimp_id
	and a.rep_codice='BILR220'
    and not exists (select 1
 from BKO_T_REPORT_IMPORTI aa
 where aa.rep_codice = a.rep_codice
 	and aa.repimp_codice = b.repimp_codice);		  	  
	
	
-- PROCEDURE PL/SQL

DROP FUNCTION if exists siac."BILR217_equilibri_bilancio_regione_assest_entrate"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR217_equilibri_bilancio_regione_assest_spese"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR218_Allegato_D_Limiti_di_indebitamento_regioni_assest"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR219_Equilibri_bilancio_EELL_entrate_assest"(p_ente_prop_id integer, p_anno varchar, p_pluriennale varchar);
DROP FUNCTION if exists siac."BILR219_Equilibri_bilancio_EELL_spese_assest"(p_ente_prop_id integer, p_anno varchar, p_pluriennale varchar);
DROP FUNCTION if exists siac."BILR220_Allegato_D_Limiti_indebitamento_EELL_assest"(p_ente_prop_id integer, p_anno varchar, p_pluriennale varchar);

CREATE OR REPLACE FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_entrate" (
  p_ente_prop_id integer,
  p_anno varchar
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
  codice_pdc varchar
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
h_count integer :=0;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

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
select *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,user_table);



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
where ct.classif_tipo_code='CATEGORIA'
and ct.classif_tipo_id=cl.classif_tipo_id
and cl.classif_id=rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno= p_anno
and bilancio.periodo_id=anno_eserc.periodo_id 
and e.bil_id=bilancio.bil_id 
and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id=rc.elem_id
and r_capitolo_pdc.classif_id = pdc.classif_id
and pdc.classif_tipo_id = pdc_tipo.classif_tipo_id
and pdc_tipo.classif_tipo_code like 'PDC_%'
and e.elem_id = r_capitolo_pdc.elem_id
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
and	cat_del_capitolo.data_cancellazione	is null
and	r_capitolo_pdc.data_cancellazione	is null
and	pdc.data_cancellazione				is null
and	pdc_tipo.data_cancellazione			is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_capitolo_pdc.validita_inizio and coalesce (r_capitolo_pdc.validita_fine, now())
and	now() between pdc.validita_inizio and coalesce (pdc.validita_fine, now())
and	now() between pdc_tipo.validita_inizio and coalesce (pdc_tipo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());



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
            siac_r_bil_elem_categoria r_cat_capitolo
where 		capitolo_importi.ente_proprietario_id = p_ente_prop_id  
    	        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;




insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;

raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    



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
/*from  	siac_rep_tit_tip_cat_riga v1*/
from	siac_rep_tit_tip_cat_riga_anni	v1

			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					-----and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            	AND TB.utente=tb1.utente
                    and tb.utente=user_table)
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


-- importi capitolo

/*raise notice 'record';*/
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


end loop;
/*delete from siac_rep_tit_tip_cat_riga where utente=user_table;*/

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


CREATE OR REPLACE FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_spese" (
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
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  pdc varchar
) AS
$body$
DECLARE

capitoloRec record;
capitoloImportiRec record;
classifBilRec record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
user_table	varchar;
tipologia_capitolo	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI';	 -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
pdc='';
 
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

return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
       		capitolo.*
		from 
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
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),
pdc_capitolo as (
select r_capitolo_pdc.elem_id,
	 pdc.classif_code pdc_code
from siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo
where r_capitolo_pdc.classif_id = pdc.classif_id and
  	 pdc.classif_tipo_id 		= pdc_tipo.classif_tipo_id and
     r_capitolo_pdc.ente_proprietario_id	=	p_ente_prop_id and 
     pdc_tipo.classif_tipo_code like 'PDC_%'		and
     r_capitolo_pdc.data_cancellazione 			is null and 	
     pdc.data_cancellazione is null 	and
     pdc_tipo.data_cancellazione 	is null),           
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes --'STR'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_fpv_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id)                                                                                                 
select 
   capitoli.anno_bilancio::varchar bil_anno,
   ''::varchar missione_tipo_code,
   strut_bilancio.missione_tipo_desc::varchar missione_tipo_desc,
   strut_bilancio.missione_code::varchar missione_code,
   strut_bilancio.missione_desc::varchar missione_desc,
   ''::varchar programma_tipo_code,
   strut_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
   strut_bilancio.programma_code::varchar programma_code,
   strut_bilancio.programma_desc::varchar programma_desc,
   ''::varchar titusc_tipo_code,
   strut_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
   strut_bilancio.titusc_code::varchar titusc_code,
   strut_bilancio.titusc_desc::varchar titusc_desc,
   ''::varchar macroag_tipo_code,
   strut_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
   strut_bilancio.macroag_code::varchar macroag_code,
   strut_bilancio.macroag_desc::varchar macroag_desc,
   capitoli.elem_code::varchar bil_ele_code,
   capitoli.elem_desc::varchar bil_ele_desc,
   capitoli.elem_code2::varchar bil_ele_code2,
   capitoli.elem_desc2::varchar bil_ele_desc2,
   capitoli.elem_id::integer bil_ele_id,
   capitoli.elem_id_padre::integer bil_ele_id_padre,
   COALESCE(imp_residui_anno.importo,0)::numeric stanziamento_prev_res_anno,   
   COALESCE(imp_res_anno_prec.importo,0)::numeric stanziamento_anno_prec,
   COALESCE(imp_cassa_anno.importo,0)::numeric stanziamento_prev_cassa_anno,
   COALESCE(imp_comp_anno.importo,0)::numeric stanziamento_prev_anno,
   COALESCE(imp_comp_anno1.importo,0)::numeric stanziamento_prev_anno1,
   COALESCE(imp_comp_anno2.importo,0)::numeric stanziamento_prev_anno2,
   0::numeric impegnato_anno,
   0::numeric impegnato_anno1,
   0::numeric impegnato_anno2,
   COALESCE(imp_res_fpv_anno_prec.importo,0)::numeric stanziamento_fpv_anno_prec,
   COALESCE(imp_comp_fpv_anno.importo,0)::numeric stanziamento_fpv_anno,
   COALESCE(imp_comp_fpv_anno1.importo,0)::numeric stanziamento_fpv_anno1,
   COALESCE(imp_comp_fpv_anno2.importo,0)::numeric stanziamento_fpv_anno2,
   pdc_capitolo.pdc_code::varchar pdc      
from strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN pdc_capitolo on capitoli.elem_id = pdc_capitolo.elem_id    
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id
    LEFT JOIN imp_residui_anno on capitoli.elem_id = imp_residui_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno on capitoli.elem_id = imp_comp_fpv_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno1 on capitoli.elem_id = imp_comp_fpv_anno1.elem_id
    LEFT JOIN imp_comp_fpv_anno2 on capitoli.elem_id = imp_comp_fpv_anno2.elem_id
    LEFT JOIN imp_res_anno_prec on capitoli.elem_id = imp_res_anno_prec.elem_id
    LEFT JOIN imp_res_fpv_anno_prec on capitoli.elem_id = imp_res_fpv_anno_prec.elem_id;



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

CREATE OR REPLACE FUNCTION siac."BILR218_Allegato_D_Limiti_di_indebitamento_regioni_assest" (
  p_ente_prop_id integer,
  p_anno varchar
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
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='SRI'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
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
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;


select fnc_siac_random_user()
into	user_table;

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

insert into siac_rep_tit_tip_cat_riga_anni
select *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,user_table);


insert into siac_rep_cap_ep
select 	cl.classif_id,
  		p_anno anno_bilancio,
  		e.*, 
        user_table utente
 from 		siac_r_bil_elem_class rc, 
 			siac_t_bil_elem e, 
            siac_d_class_tipo ct,
			siac_t_class cl,  
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo,
        	siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo,
        	siac_r_bil_elem_categoria r_cat_capitolo
where  ct.classif_tipo_id				=cl.classif_tipo_id
and cl.classif_id					=rc.classif_id 
and e.elem_tipo_id		=	tipo_elemento.elem_tipo_id 
and e.elem_id			=			rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.bil_id=id_bil
and e.ente_proprietario_id=p_ente_prop_id
and ct.classif_tipo_code			='CATEGORIA'
and tipo_elemento.elem_tipo_code = elemTipoCode
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;



insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
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
    	and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
    group by
           capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	TipoImpComp		AND
        			tb2.periodo_anno = annoCapImp1		AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2		AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb2.utente	
    				and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
               

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
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					-----and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    and	tb.utente=user_table
                    and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

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
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;


-- importi capitolo

/*raise notice 'record';*/
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
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;

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
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR219_Equilibri_bilancio_EELL_entrate_assest" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
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
  codice_pdc varchar
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
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
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
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

-----------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,user_table);


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
where ct.classif_tipo_code='CATEGORIA'
and ct.classif_tipo_id=cl.classif_tipo_id
and cl.classif_id=rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno= p_anno
and bilancio.periodo_id=anno_eserc.periodo_id 
and e.bil_id=bilancio.bil_id 
and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id=rc.elem_id
and r_capitolo_pdc.classif_id = pdc.classif_id
and pdc.classif_tipo_id = pdc_tipo.classif_tipo_id
and pdc_tipo.classif_tipo_code like 'PDC_%'
and e.elem_id = r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione				is null
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
and r_cat_capitolo.data_cancellazione 	is null
and now() between rc.validita_inizio and coalesce(rc.validita_fine, now())
and now() between e.validita_inizio and coalesce(e.validita_fine, now())
and now() between ct.validita_inizio and coalesce(ct.validita_fine, now())
and now() between cl.validita_inizio and coalesce(cl.validita_fine, now())
and now() between bilancio.validita_inizio and coalesce(bilancio.validita_fine, now())
and now() between anno_eserc.validita_inizio and coalesce(anno_eserc.validita_fine, now())
and now() between tipo_elemento.validita_inizio and coalesce(tipo_elemento.validita_fine, now())
and now() between r_capitolo_pdc.validita_inizio and coalesce(r_capitolo_pdc.validita_fine, now())
and now() between pdc.validita_inizio and coalesce(pdc.validita_fine, now())
and now() between pdc_tipo.validita_inizio and coalesce(pdc_tipo.validita_fine, now())
and now() between stato_capitolo.validita_inizio and coalesce(stato_capitolo.validita_fine, now())
and now() between r_capitolo_stato.validita_inizio and coalesce(r_capitolo_stato.validita_fine, now())
and now() between cat_del_capitolo.validita_inizio and coalesce(cat_del_capitolo.validita_fine, now())
and now() between r_cat_capitolo.validita_inizio and coalesce(r_cat_capitolo.validita_fine, now())
;



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
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by
           capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
        			

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
/*from  	siac_rep_tit_tip_cat_riga*/
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            	AND TB.utente=tb1.utente
                and tb.utente=user_table)
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
IF p_pluriennale = 'N' THEN
	stanziamento_prev_anno1:=0;
	stanziamento_prev_anno2:=0;
ELSE
	stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
	stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
END IF;

codice_pdc:=classifBilRec.codice_pdc;

-- importi capitolo

/*raise notice 'record';*/
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


end loop;
  

/*delete from siac_rep_tit_tip_cat_riga where utente=user_table;*/

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

CREATE OR REPLACE FUNCTION siac."BILR219_Equilibri_bilancio_EELL_spese_assest" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
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
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_res_anno numeric,
  stanziamento_anno_prec numeric,
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  codice_pdc varchar
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
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
codice_pdc='';

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

return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
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
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id = id_bil AND
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and   																						
    		programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),
pdc_capitolo as (
select r_capitolo_pdc.elem_id,
	 pdc.classif_code pdc_code
from siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo
where r_capitolo_pdc.classif_id = pdc.classif_id and
  	 pdc.classif_tipo_id 		= pdc_tipo.classif_tipo_id and
     r_capitolo_pdc.ente_proprietario_id	=	p_ente_prop_id and 
     pdc_tipo.classif_tipo_code like 'PDC_%'		and
     r_capitolo_pdc.data_cancellazione 			is null and 	
     pdc.data_cancellazione is null 	and
     pdc_tipo.data_cancellazione 	is null),           
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil 
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes --'STR'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id  	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_fpv_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id = id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id)                                                                                                 
select 
   capitoli.anno_bilancio::varchar bil_anno,
   ''::varchar missione_tipo_code,
   strut_bilancio.missione_tipo_desc::varchar missione_tipo_desc,
   strut_bilancio.missione_code::varchar missione_code,
   strut_bilancio.missione_desc::varchar missione_desc,
   ''::varchar programma_tipo_code,
   strut_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
   strut_bilancio.programma_code::varchar programma_code,
   strut_bilancio.programma_desc::varchar programma_desc,
   ''::varchar titusc_tipo_code,
   strut_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
   strut_bilancio.titusc_code::varchar titusc_code,
   strut_bilancio.titusc_desc::varchar titusc_desc,
   ''::varchar macroag_tipo_code,
   strut_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
   strut_bilancio.macroag_code::varchar macroag_code,
   strut_bilancio.macroag_desc::varchar macroag_desc,
   capitoli.elem_code::varchar bil_ele_code,
   capitoli.elem_desc::varchar bil_ele_desc,
   capitoli.elem_code2::varchar bil_ele_code2,
   capitoli.elem_desc2::varchar bil_ele_desc2,
   capitoli.elem_id::integer bil_ele_id,
   capitoli.elem_id_padre::integer bil_ele_id_padre,
   COALESCE(imp_residui_anno.importo,0)::numeric stanziamento_prev_res_anno,   
   COALESCE(imp_res_anno_prec.importo,0)::numeric stanziamento_anno_prec,
   COALESCE(imp_cassa_anno.importo,0)::numeric stanziamento_prev_cassa_anno,
   COALESCE(imp_comp_anno.importo,0)::numeric stanziamento_prev_anno,
   CASE WHEN p_pluriennale = 'S' THEN
   		COALESCE(imp_comp_anno1.importo,0) ::numeric
   ELSE 0::numeric end stanziamento_prev_anno1,
   CASE WHEN p_pluriennale = 'S' THEN
   		COALESCE(imp_comp_anno2.importo,0) ::numeric
   ELSE 0::numeric end stanziamento_prev_anno2,
   0::numeric impegnato_anno,
   0::numeric impegnato_anno1,
   0::numeric impegnato_anno2,
   COALESCE(imp_res_fpv_anno_prec.importo,0)::numeric stanziamento_fpv_anno_prec,
   COALESCE(imp_comp_fpv_anno.importo,0)::numeric stanziamento_fpv_anno,
   CASE WHEN p_pluriennale = 'S' THEN
   		COALESCE(imp_comp_fpv_anno1.importo,0) ::numeric
   ELSE 0::numeric end stanziamento_fpv_anno1,
   CASE WHEN p_pluriennale = 'S' THEN
   		COALESCE(imp_comp_fpv_anno2.importo,0) ::numeric
   ELSE 0::numeric end stanziamento_fpv_anno2,   
   pdc_capitolo.pdc_code::varchar codice_pdc      
from strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN pdc_capitolo on capitoli.elem_id = pdc_capitolo.elem_id    
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id
    LEFT JOIN imp_residui_anno on capitoli.elem_id = imp_residui_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno on capitoli.elem_id = imp_comp_fpv_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno1 on capitoli.elem_id = imp_comp_fpv_anno1.elem_id
    LEFT JOIN imp_comp_fpv_anno2 on capitoli.elem_id = imp_comp_fpv_anno2.elem_id
    LEFT JOIN imp_res_anno_prec on capitoli.elem_id = imp_res_anno_prec.elem_id
    LEFT JOIN imp_res_fpv_anno_prec on capitoli.elem_id = imp_res_fpv_anno_prec.elem_id;

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

CREATE OR REPLACE FUNCTION siac."BILR220_Allegato_D_Limiti_indebitamento_EELL_assest" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
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
  stanziamento_prev_cassa_anno numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  residui_presunti numeric,
  previsioni_anno_prec numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
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
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;


select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,user_table);


insert into siac_rep_cap_ep
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
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
      /*  and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    

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
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_ep_imp_riga tb1  
           on (tb1.elem_id	=	tb.elem_id 
           		and	tb.utente	=user_table
                and tb1.utente	=	tb.utente)
    where v1.utente = user_table	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

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
IF p_pluriennale = 'N' THEN
	stanziamento_prev_anno1:=0;
	stanziamento_prev_anno2:=0;
ELSE
	stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
	stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
END IF;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;

-- importi capitolo

/*raise notice 'record';*/
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
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;

end loop;
delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6331: Maurizio - FINE
-- SIAC-6468

drop FUNCTION siac.fnc_siac_capitoli_from_variazioni (integer) ; 


CREATE OR REPLACE FUNCTION siac.fnc_siac_capitoli_from_variazioni (
  p_uid_variazione integer
)
RETURNS TABLE (
  stato_variazione varchar,
  anno_capitolo varchar,
  numero_capitolo varchar,
  numero_articolo varchar,
  numero_ueb varchar,
  tipo_capitolo varchar,
  descrizione_capitolo varchar,
  descrizione_articolo varchar,
  missione varchar,
  programma varchar,
  titolo_uscita varchar,
  macroaggregato varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  var_competenza numeric,
  var_residuo numeric,
  var_cassa numeric,
  var_competenza1 numeric,
  var_residuo1 numeric,
  var_cassa1 numeric,
  var_competenza2 numeric,
  var_residuo2 numeric,
  var_cassa2 numeric,
  cap_competenza numeric,
  cap_residuo numeric,
  cap_cassa numeric,
  cap_competenza1 numeric,
  cap_residuo1 numeric,
  cap_cassa1 numeric,
  cap_competenza2 numeric,
  cap_residuo2 numeric,
  cap_cassa2 numeric,
  tipologiaFinanziamento varchar,
  sac varchar,
  variazione_num integer,
  variazione_anno varchar
) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
	SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;

	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id_padre                      AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre is not null
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine,to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
        tipofinanziamento AS (
        	SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipofinanziamento_tipo_desc,
				siac_t_class.classif_id tipofinanziamento_id,
				siac_t_class.classif_code tipofinanziamento_code,
				siac_t_class.classif_desc tipofinanziamento_desc,
				siac_t_class.validita_inizio tipofinanziamento_validita_inizio,
				siac_t_class.validita_fine tipofinanziamento_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipofinanziamento_code_desc,
				siac_r_bil_elem_class.elem_id tipofinanziamento_elem_id
			FROM 
                     siac_t_class
                JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
                JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			where 
                   siac_d_class_tipo.classif_tipo_code = 'TIPO_FINANZIAMENTO'
              AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
        ),
        sac AS (
        	SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc sar_tipo_desc,
				siac_t_class.classif_id sac_id,
				siac_t_class.classif_code sac_code,
				siac_t_class.classif_desc sac_desc,
				siac_t_class.validita_inizio sac_validita_inizio,
				siac_t_class.validita_fine sac_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc,
				siac_r_bil_elem_class.elem_id sac_elem_id
			FROM 
                     siac_t_class
                JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
                JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			where 
                   siac_d_class_tipo.classif_tipo_code in ('CDC','CDR')
              AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
        ),
        
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		-- CTE importi capitolo
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		)
		SELECT
			 siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			
            ,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
            
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
            
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2           
            ,tipofinanziamento.tipofinanziamento_code_desc tipologiaFinanziamento
            ,sac.sac_code_desc sac
            ,siac_t_variazione.variazione_num
            ,periodo_variazione.anno variazione_anno
            
		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		
        --JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		--JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		JOIN siac_t_periodo periodo_variazione ON (siac_t_variazione.periodo_id = periodo_variazione.periodo_id                                          AND periodo_variazione.data_cancellazione IS NULL)
		
        -- Importi variazione, anno 0
		LEFT OUTER JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = periodo_variazione.anno::INTEGER)
		-- Importi variazione, anno +1
		LEFT OUTER JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		LEFT OUTER JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		LEFT OUTER JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = periodo_variazione.anno::INTEGER)
		-- Importi capitolo, anno +1
		LEFT OUTER JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		LEFT OUTER JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
        -- SIAC-6468
        LEFT OUTER JOIN tipofinanziamento ON (tipofinanziamento.tipofinanziamento_elem_id = siac_t_bil_elem.elem_id)
        LEFT OUTER JOIN sac ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
        
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--Fine Siac-6468

-- 27.02.2019 Sofia SIAC-6713 - inizio

drop FUNCTION if exists fnc_siac_riaccertamento 
(
  mod_id_in integer,
  login_operazione_in varchar,
  tipo_operazione_in varchar
);

CREATE OR REPLACE FUNCTION fnc_siac_riaccertamento (
  mod_id_in integer,
  login_operazione_in varchar,
  tipo_operazione_in varchar
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
importo_mod_da_scalare numeric;
ente_proprietario_id_in integer;
rec record;
recannullamento record;

cur CURSOR(par_in integer) FOR
--avav
SELECT 'avav' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
case when n.avav_tipo_code='FPVSC' then 1
	 when n.avav_tipo_code='FPVCC' then 1 when n.avav_tipo_code='AAM' then 2 else 3 end
		as tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_r_movgest_ts i,
siac_t_avanzovincolo l, siac_d_movgest_ts_tipo m,siac_d_avanzovincolo_tipo n
WHERE
a.mod_id=par_in--mod_id_in
 and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and --movgest_ts_b_id e' impegno
i.movgest_ts_b_id=f.movgest_ts_id and
n.avav_tipo_id=l.avav_tipo_id and
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.avav_id=i.avav_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null and
n.data_cancellazione is null
--order by 1 asc,3 desc
union
-- imp acc
SELECT
'impacc',
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo,
4 tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_r_movgest_ts i,--, siac_t_movgest l,siac_d_movgest_tipo m
siac_t_movgest_ts l, siac_d_movgest_ts_tipo m
WHERE
a.mod_id=par_in--mod_id_in
and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
--h.movgest_tipo_code='A' and
i.movgest_ts_b_id=f.movgest_ts_id and --movgest_ts_b_id e' impegno
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.movgest_ts_id=i.movgest_ts_a_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null
order
by 5 desc,2 asc,4 desc;   -- 27.02.2019 SIAC-6713
--by 5 asc,2 asc,4 desc;  -- 27.02.2019 SIAC-6713

begin
esito:='oknodata'::varchar;

if tipo_operazione_in = 'INSERIMENTO' then

      --data la modifica trovo il suo importo da sottrarre ai vincoli
      --modifiche di impegno
      SELECT c.movgest_ts_det_importo,
      c.ente_proprietario_id
      into importo_mod_da_scalare,
      ente_proprietario_id_in
      FROM siac_t_modifica a,
      siac_r_modifica_stato b,
      siac_t_movgest_ts_det_mod c,
      siac_d_modifica_stato d,
      siac_d_movgest_ts_det_tipo e,
      siac_t_movgest_ts f,
      siac_t_movgest g,
      siac_d_movgest_tipo h
      WHERE a.mod_id = mod_id_in and
      a.mod_id = b.mod_id AND
      c.mod_stato_r_id = b.mod_stato_r_id AND
      d.mod_stato_id = b.mod_stato_id and
      e.movgest_ts_det_tipo_id = c.movgest_ts_det_tipo_id and
      f.movgest_ts_id = c.movgest_ts_id and
      g.movgest_id = f.movgest_id and
      d.mod_stato_code = 'V' and
      h.movgest_tipo_id = g.movgest_tipo_id and
      h.movgest_tipo_code = 'I' and
      now() BETWEEN b.validita_inizio and
      COALESCE(b.validita_fine, now()) and
      a.data_cancellazione IS NULL AND
      b.data_cancellazione IS NULL AND
      c.data_cancellazione IS NULL AND
      d.data_cancellazione IS NULL and
      e.data_cancellazione is null and
      f.data_cancellazione is null and
      g.data_cancellazione is null and
      h.data_cancellazione is null;

      if importo_mod_da_scalare<0 then

      ----------nuova sez inizio -------------
      for rec in cur(mod_id_in) loop
          if rec.movgest_ts_importo is not null and importo_mod_da_scalare<0 then
              if rec.movgest_ts_importo + importo_mod_da_scalare < 0 then
                esito:='ok';
                update siac_r_movgest_ts
                  set movgest_ts_importo = movgest_ts_importo - movgest_ts_importo --per farlo diventare zero
                  ,login_operazione = login_operazione_in,data_modifica = clock_timestamp()
                  where movgest_ts_r_id = rec.movgest_ts_r_id;

                insert into siac_r_modifica_vincolo(mod_id, movgest_ts_r_id,
                  modvinc_tipo_operazione, importo_delta, validita_inizio, ente_proprietario_id,
                  login_operazione)
                values (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO', - rec.movgest_ts_importo,
                  clock_timestamp(), ente_proprietario_id_in, login_operazione_in || ' - ' ||
                  'fnc_siac_riccertamento');

                /*INSERT INTO siac.tmp_riaccertamento_debug(tmp_mod_id_in,
                  tmp_login_operazione_in, tmp_tipo_operazione_in, tmp_movgest_ts_r_id,
                  tmp_movgest_ts_importo, tmp_importo_mod_da_scalare, esito)
                VALUES (mod_id_in, login_operazione_in, tipo_operazione_in, rec.movgest_ts_r_id,
                  rec.movgest_ts_importo, importo_mod_da_scalare, esito);*/

                importo_mod_da_scalare:= importo_mod_da_scalare + rec.movgest_ts_importo;

              elsif rec.movgest_ts_importo + importo_mod_da_scalare >= 0 then
                esito:='ok';
                update siac_r_movgest_ts set
                movgest_ts_importo = movgest_ts_importo + importo_mod_da_scalare
                , login_operazione=login_operazione_in, data_modifica=clock_timestamp()
                where movgest_ts_r_id=rec.movgest_ts_r_id;

                insert into siac_r_modifica_vincolo (mod_id,movgest_ts_r_id,modvinc_tipo_operazione,
                importo_delta,validita_inizio,ente_proprietario_id
                ,login_operazione )
                values
                (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO',importo_mod_da_scalare,clock_timestamp(), ente_proprietario_id_in,
                login_operazione_in||' - '||'fnc_siac_riccertamento' );

                /*INSERT INTO siac.tmp_riaccertamento_debug(tmp_mod_id_in,
                tmp_login_operazione_in, tmp_tipo_operazione_in, tmp_movgest_ts_r_id,
                tmp_movgest_ts_importo, tmp_importo_mod_da_scalare, esito)
                VALUES (mod_id_in, login_operazione_in, tipo_operazione_in,
                rec.movgest_ts_r_id, rec.movgest_ts_importo, importo_mod_da_scalare,
                'ok=');*/

                importo_mod_da_scalare:= importo_mod_da_scalare - importo_mod_da_scalare;

              end if;
          end if;
       --  esito:='ok';
      end loop;
      ----------nuova sez fine -------------
      return next;

      end if;

elsif tipo_operazione_in = 'ANNULLA' then

    for recannullamento in
    select a.* from siac_r_modifica_vincolo a where a.modvinc_tipo_operazione='INSERIMENTO'
    and a.mod_id=mod_id_in
    and a.data_cancellazione is null
    and now() between a.validita_inizio and coalesce(a.validita_fine,now())

    loop

    --aggiorna importo riportandolo a situazione pre riaccertamento
    update siac_r_movgest_ts set movgest_ts_importo=movgest_ts_importo-recannullamento.importo_delta
    where movgest_ts_r_id=recannullamento.movgest_ts_r_id;

    --inserisce record di ANNULLAMENTO con importo_delta=-importo_delta
    INSERT INTO
      siac.siac_r_modifica_vincolo
    (
      mod_id,
      movgest_ts_r_id,
      modvinc_tipo_operazione,
      importo_delta,
      validita_inizio,
      ente_proprietario_id,
      login_operazione
    )
    values (recannullamento.mod_id,
    recannullamento.movgest_ts_r_id,
    'ANNULLAMENTO',--tipo_operazione_in,
    -recannullamento.importo_delta,
    clock_timestamp(),
    recannullamento.ente_proprietario_id,
    login_operazione_in||' - '||'fnc_siac_riccertamento'
    );

    --annulla precedente modifica in INSERIMENTO
    update siac_r_modifica_vincolo set validita_fine=clock_timestamp()
    where modvinc_id=recannullamento.modvinc_id
    ;
    esito:='ok';

    --insert tabella debug
    /*  INSERT INTO
      siac.tmp_riaccertamento_debug
    (
      tmp_mod_id_in,
      tmp_login_operazione_in,
      tmp_tipo_operazione_in,
      tmp_movgest_ts_r_id,
      tmp_movgest_ts_importo,
      tmp_importo_mod_da_scalare,
      esito
    )
    VALUES (
      mod_id_in,
      login_operazione_in,
      tipo_operazione_in,
      recannullamento.movgest_ts_r_id,
      null,
      -recannullamento.importo_delta,
      esito
    );
*/



    end loop;
    return next;

end if;----tipo_operazione_in = 'INSERIMENTO'

/*if esito='oknodata' then
INSERT INTO
  siac.tmp_riaccertamento_debug
(
  tmp_mod_id_in,
  tmp_login_operazione_in,
  tmp_tipo_operazione_in,
esito
) VALUES(
 mod_id_in,
  login_operazione_in,
  tipo_operazione_in,
  esito);

end if;
*/


EXCEPTION
WHEN others THEN
  esito:='ko';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- 27.02.2019 Sofia SIAC-6713 - fine



--SIAC-6718 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR105_stampa_versamenti_iva" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
  p_data_quietanza_da date,
  p_data_quietanza_a date
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_mandato integer,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_split_comm varchar,
  importo_iva_comm numeric,
  tipo_split_istituz varchar,
  importo_iva_istituz numeric,
  tipo_split_reverse varchar,
  importo_iva_reverse numeric,
  num_riscoss varchar,
  display_error varchar,
  cartacont varchar,
  aliquota varchar,
  data_quietanza date
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
numeroParametriData Integer;
cartacont_pk Integer;
var_attr_id integer;


BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

importo_lordo_mandato=0;
tipo_split_comm='';
importo_iva_comm=0;
tipo_split_istituz='';
importo_iva_istituz=0;
tipo_split_reverse='';
importo_iva_reverse=0;

num_riscoss='';

numeroParametriData=0;
display_error='';

cartacont_pk=0;
cartacont='';
aliquota='';
data_quietanza=NULL;

if (p_data_trasm_da IS NOT NULL OR p_data_trasm_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_mandato_da IS NOT NULL OR p_data_mandato_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;
if (p_data_quietanza_da IS NOT NULL OR p_data_quietanza_a IS NOT NULL) THEN
	numeroParametriData=numeroParametriData+1;
end if;

/*
if p_data_trasm_da IS NULL AND p_data_trasm_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A" E "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;
if p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL 
	AND p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI DUE INTERVALLI DI DATA "DATA MANDATO DA/A" E "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;*/

if numeroParametriData = 0 THEN
	display_error='OCCORRE SPECIFICARE UNO TRA GLI INTERVALLI "DATA MANDATO DA/A",  "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if numeroParametriData>=2 THEN
	display_error='OCCORRE SPECIFICARE UNO SOLO DEI TRE INTERVALLI DI DATA "DATA MANDATO DA/A", "DATA TRASMISSIONE DA/A" E "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;

if (p_data_trasm_da IS NULL AND p_data_trasm_a IS NOT NULL) OR 
	(p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA TRASMISSIONE DA/A".';
    return next;
    return;
end if;

if (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL) OR 
	(p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA MANDATO DA/A".';
    return next;
    return;
end if;

if (p_data_quietanza_da IS NULL AND p_data_quietanza_a IS NOT NULL) OR 
	(p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS  NULL) THEN
	display_error='OCCORRE SPECIFICARE ENTRAMBE LE DATE "DATA QUIETANZA DA/A".';
    return next;
    return;
end if;


RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;


select attr_id into var_attr_id from siac_t_attr t_attr where  t_attr.attr_code = 'ALIQUOTA_SOGG' and t_attr.ente_proprietario_id=p_ente_prop_id;

for elencoMandati in
select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
		t_periodo.anno anno_eser, t_ordinativo.ord_anno,
		 t_ordinativo.ord_desc, t_ordinativo.ord_id,
        t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
        t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
        d_ord_stato.ord_stato_code, 
        SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
        t_movgest.movgest_anno anno_impegno
        ,r_ord_quietanza.ord_quietanza_data
		FROM  	siac_t_ente_proprietario ep,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo,                
                siac_t_ordinativo t_ordinativo
                --10/02/2017: aggiunta la tabella della quietanza per testare
                  -- la data quietanza se specificata in input.
                LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                    on (r_ord_quietanza.ord_id=t_ordinativo.ord_id
                        and r_ord_quietanza.data_cancellazione IS NULL
                        --SIAC-6718 Aggiunto il test sulla data di fine validita'
                        and r_ord_quietanza.validita_fine IS NULL),
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_liquidazione_ord r_liq_ord,
                siac_r_liquidazione_movgest r_liq_movgest,
                siac_t_movgest t_movgest,
                siac_t_movgest_ts t_movgest_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_stato r_ord_stato,  
                siac_d_ordinativo_stato d_ord_stato ,
                 siac_d_ordinativo_tipo d_ord_tipo,
                 siac_r_ordinativo_soggetto r_ord_soggetto ,
                 siac_t_soggetto t_soggetto  		    	
        WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id        	                 
           AND t_ordinativo.ord_id=r_ord_stato.ord_id
           AND t_bil.bil_id=t_ordinativo.bil_id
           AND t_periodo.periodo_id=t_bil.periodo_id
           AND t_ord_ts.ord_id=t_ordinativo.ord_id           
           AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
           AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
           AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
           AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
           AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
           AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
           AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
           AND r_liq_movgest.liq_id=r_liq_ord.liq_id
           AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
           AND t_movgest_ts.movgest_id=t_movgest.movgest_id            
			AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
            	AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                	between p_data_mandato_da AND p_data_mandato_a))
                OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL))
            AND ((p_data_trasm_da IS NOT NULL AND p_data_trasm_a IS NOT NULL
            	AND (to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                	between p_data_trasm_da AND p_data_trasm_a))
                OR (p_data_trasm_da IS  NULL AND p_data_trasm_a IS  NULL))   
				--10/02/2017: aggiunto test sulla data quietanza
                -- se specificata in input.
              AND ((p_data_quietanza_da IS NOT NULL AND p_data_quietanza_a IS NOT NULL
                  AND (to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                      between p_data_quietanza_da AND p_data_quietanza_a)) 
                  OR (p_data_quietanza_da IS  NULL AND p_data_quietanza_a IS  NULL))                         		
            AND t_ordinativo.ente_proprietario_id= p_ente_prop_id
            AND t_periodo.anno=p_anno
            	/* Gli stati possibili sono:
                	I = INSERITO
                    T = TRASMESSO 
                    Q = QUIETANZIATO
                    F = FIRMATO
                    A = ANNULLATO 
                    Prendo tutti tranne gli annullati.
                   */
            AND d_ord_stato.ord_stato_code <> 'A'
            AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            	/* devo testare la data di fine validita' perche'
                	quando un ordinativo e' annullato, lo trovo 2 volte,
                    uno con stato inserito e l'altro annullato */
            AND r_ord_stato.validita_fine IS NULL 
            AND ep.data_cancellazione IS NULL
            AND r_ord_stato.data_cancellazione IS NULL
            AND  t_bil.data_cancellazione IS NULL
            AND  t_periodo.data_cancellazione IS NULL
            AND  t_ordinativo.data_cancellazione IS NULL
            AND  t_ord_ts.data_cancellazione IS NULL
            AND  t_ord_ts_det.data_cancellazione IS NULL
            AND  d_ts_det_tipo.data_cancellazione IS NULL
            AND  r_ord_stato.data_cancellazione IS NULL
            AND  d_ord_stato.data_cancellazione IS NULL
            AND  d_ord_tipo.data_cancellazione IS NULL  
            AND r_ord_soggetto.data_cancellazione IS NULL
            AND t_soggetto.data_cancellazione IS NULL
            AND r_liq_ord.data_cancellazione IS NULL 
            AND r_liq_movgest.data_cancellazione IS NULL 
            AND t_movgest.data_cancellazione IS NULL
            AND t_movgest_ts.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
              t_periodo.anno , t_ordinativo.ord_anno,
               t_ordinativo.ord_desc, t_ordinativo.ord_id,
              t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
              t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
             d_ord_stato.ord_stato_code, t_movgest.movgest_anno
             ,r_ord_quietanza.ord_quietanza_data
            ORDER BY t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data                        
loop

importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);


	/* cerco gli oneri 
    	09/03/2016: prendo il codice dello split/reverse da siac_d_splitreverse_iva_tipo
        l'importo dell'imposta non e' piu' preso dagli oneri del mandato ma e'
        l'importo della reversale */
for elencoOneri IN
        SELECT d_onere_tipo.onere_tipo_code, d_onere.onere_code,
          d_onere.onere_desc, d_split_iva_tipo.sriva_tipo_code,
          t_cartacont.cartac_id, t_cartacont.cartac_numero,t_cartacont.cartac_data_scadenza
          , r_onere_attr.percentuale
       --   sum(r_doc_onere.importo_imponibile) IMPORTO_IMPONIBILE,
       --   sum(r_doc_onere.importo_carico_soggetto) IMPOSTA
        from siac_t_ordinativo_ts t_ordinativo_ts,
            siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
            siac_t_doc t_doc, 
            siac_t_subdoc t_subdoc
               left join siac_r_cartacont_det_subdoc r_cartacont_det_subdoc on (t_subdoc.subdoc_id=r_cartacont_det_subdoc.subdoc_id)
               left join siac_t_cartacont_det t_cartacont_det on (r_cartacont_det_subdoc.cartac_det_id=t_cartacont_det.cartac_det_id)
               left join siac_t_cartacont t_cartacont on (t_cartacont_det.cartac_id=t_cartacont.cartac_id),     
            siac_r_doc_onere r_doc_onere,
            siac_d_onere d_onere
            	left join siac_r_onere_attr r_onere_attr on 
                	(d_onere.onere_id = r_onere_attr.onere_id and r_onere_attr.data_cancellazione is null and r_onere_attr.attr_id=var_attr_id)
            ,siac_d_onere_tipo d_onere_tipo,
            siac_r_subdoc_splitreverse_iva_tipo r_subdoc_split_iva,
            siac_d_splitreverse_iva_tipo d_split_iva_tipo
        WHERE r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
            AND t_doc.doc_id=t_subdoc.doc_id
            and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            AND r_doc_onere.doc_id=t_doc.doc_id
            AND d_onere.onere_id=r_doc_onere.onere_id
            AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id 
            AND r_subdoc_split_iva.subdoc_id=t_subdoc.subdoc_id     
            AND d_split_iva_tipo.sriva_tipo_id=r_subdoc_split_iva.sriva_tipo_id  
            AND t_ordinativo_ts.ord_id=elencoMandati.ord_id
            --AND upper(d_onere_tipo.onere_tipo_code)='SP' --SPLIT
            AND d_onere_tipo.onere_tipo_code='SP' --SPLIT
            AND t_doc.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_split_iva.data_cancellazione IS NULL
            AND d_split_iva_tipo.data_cancellazione IS NULL
       order by t_cartacont.cartac_id
          --  GROUP BY d_onere_tipo.onere_tipo_code,d_onere.onere_code, d_onere.onere_desc,
           -- 	d_split_iva_tipo.sriva_tipo_code
    loop       
--raise notice 'numero mandato %, tipo split % ',elencoMandati.ord_numero, elencoOneri.sriva_tipo_code;
				--SPLIT COMMERCIALE
            IF elencoOneri.sriva_tipo_code =  'SC' THEN
            	tipo_split_comm=elencoOneri.sriva_tipo_code; 
                --SPLIT ISTITUZIONALE
            ELSIF elencoOneri.sriva_tipo_code = 'SI' THEN
            	tipo_split_istituz=elencoOneri.sriva_tipo_code;
                --REVERSE CHANGE
            ELSIF elencoOneri.sriva_tipo_code = 'RC' THEN
            	tipo_split_reverse=elencoOneri.sriva_tipo_code;
            END IF;
            if elencoOneri.cartac_id is not null and cartacont_pk != elencoOneri.cartac_id then
            	cartacont_pk := elencoOneri.cartac_id;
            	if cartacont = '' then
                	cartacont=elencoOneri.cartac_numero||' - '||to_char(elencoOneri.cartac_data_scadenza,'dd/MM/yyyy');
                else
                	cartacont=cartacont||', '||elencoOneri.cartac_numero||' - '||to_char(elencoOneri.cartac_data_scadenza,'dd/MM/yyyy');
                end if;
            end if;
            IF elencoOneri.percentuale is not null and aliquota not like '%'||elencoOneri.percentuale||'%' then
            	if aliquota = '' then
                	aliquota=aliquota||elencoOneri.percentuale ;
                else
                	aliquota=aliquota||', '||elencoOneri.percentuale;
                end if;
            end if;
          /*IF substr( upper(elencoOneri.onere_code),1,2) = 'SC' THEN
              tipo_split_comm=substr( upper(elencoOneri.onere_code),1,2); 
              importo_iva_comm=elencoOneri.IMPOSTA;		                                                                       
          	                        
          ELSIF  substr( upper(elencoOneri.onere_code),1,2) = 'SI' THEN
 		      tipo_split_istituz=substr( upper(elencoOneri.onere_code),1,2); 
              importo_iva_istituz=elencoOneri.IMPOSTA;
          	
          ELSIF  substr( upper(elencoOneri.onere_code),1,2) = 'RC' THEN
 		      tipo_split_reverse=substr( upper(elencoOneri.onere_code),1,2); 
              importo_iva_reverse=elencoOneri.IMPOSTA;                      
          END IF;*/
    end loop;      

	/* 09/03/2016; sono inviati al report solo i mandati che hanno 
    		un onere */
if tipo_split_comm <> '' OR  tipo_split_istituz <> '' OR
	tipo_split_reverse <> '' THEN
	--raise notice 'Id ordinativo: %',elencoMandati.ord_id;
		for elencoReversali in     
            select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                    t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                    t_ord_ts_det.ord_ts_det_importo importo_ord
            from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                  siac_d_ordinativo_tipo d_ordinativo_tipo,
                  siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo
                  where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                      AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                      AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                      AND t_ord_ts.ord_id=t_ordinativo.ord_id
                      AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                      AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* 09/03/2016:  estraggo solo le reversali di tipo SPR
                        	DOVREBBE ESSERE SOLO 1 */
                AND d_relaz_tipo.relaz_tipo_code='SPR' 
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = elencoMandati.ord_id
                and t_ordinativo.ente_proprietario_id=p_ente_prop_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
          loop
--raise notice 'numero mandato %, importo rev % ',elencoMandati.ord_numero, elencoReversali.importo_ord;             
              if num_riscoss = '' THEN
                  num_riscoss = elencoReversali.ord_numero ::VARCHAR;
              else
                  num_riscoss = num_riscoss||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;
              /* 09/03/2016: l'importo dell'iva e' quello della reversale.
              	Il tipo di iva e' impostato in base al tipo onere del mandato
                estratto in precedenza */
              if tipo_split_comm <> '' THEN
              	importo_iva_comm=elencoReversali.importo_ord;
              elsif tipo_split_istituz <> '' THEN
              	importo_iva_istituz=elencoReversali.importo_ord;
              elsif tipo_split_reverse <> '' THEN
              	importo_iva_reverse=elencoReversali.importo_ord;
              END IF;
              
          end loop; 
--raise notice 'numero mandato % ',elencoMandati.ord_numero;
	/*
    Occorre mandare i mandati solo se esiste una reversale.
    Inoltre l'importo IVA deve essere quella della reversale.
    X capire su quale tipo di iva assegnare l'importo  accedere a:
    siac_t_subdoc per la quota
    siac_r_subdoc_splitreverse_iva_tipo
    siac_d_splitreverse_iva_tipo
    */
    	/* 09/03/2016: se non c'e' la reversale il mandato non deve essere inviato */
    IF num_riscoss <> '' THEN
    	
      stato_mandato= elencoMandati.ord_stato_code;

      nome_ente=elencoMandati.ente_denominazione;
      partita_iva_ente=elencoMandati.cod_fisc_ente;
      anno_ese_finanz=elencoMandati.anno_eser;
      desc_mandato=COALESCE(elencoMandati.ord_desc,'');

      anno_mandato=elencoMandati.ord_anno;
      numero_mandato=elencoMandati.ord_numero;
      data_mandato=elencoMandati.ord_emissione_data;
      benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
      benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
      benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
      
	  data_quietanza=elencoMandati.ord_quietanza_data;
      	
      return next;
    end if;
end if;


nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

importo_lordo_mandato=0;
tipo_split_comm='';
importo_iva_comm=0;
tipo_split_istituz='';
importo_iva_istituz=0;
tipo_split_reverse='';
importo_iva_reverse=0;
num_riscoss='';
cartacont_pk=0;
cartacont='';
aliquota='';
data_quietanza=NULL;

--raise notice 'fine numero mandato % ',elencoMandati.ord_numero;

end loop;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato' ;
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

--SIAC-6718 - Maurizio - FINE

--- siac-6630 - Sofia inizio 

drop FUNCTION if exists fnc_fasi_bil_prev_approva_struttura (
  annobilancio integer,
  fasebilancio varchar,
  euelemtipo varchar,
  bilelemprevtipo varchar,
  bilelemgesttipo varchar,
  checkgest boolean,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva_struttura (
  annobilancio integer,
  fasebilancio varchar,
  euelemtipo varchar,
  bilelemprevtipo varchar,
  bilelemgesttipo varchar,
  checkgest boolean,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';


    FLAG_PER_MEM CONSTANT varchar := 'FlagPerMemoria';

	elemBilPrev record;

	-- CLASSIFICATORI
	CL_MACROAGGREGATO CONSTANT varchar :='MACROAGGREGATO';
	CL_PROGRAMMA CONSTANT varchar :='PROGRAMMA';
    CL_CATEGORIA CONSTANT varchar :='CATEGORIA';
    CL_CDC CONSTANT varchar :='CDC';
    CL_CDR CONSTANT varchar :='CDR';
	CL_RICORRENTE_SPESA CONSTANT varchar:='RICORRENTE_SPESA';
    CL_RICORRENTE_ENTRATA CONSTANT varchar:='RICORRENTE_ENTRATA';
	CL_TRANSAZIONE_UE_SPESA CONSTANT varchar:='TRANSAZIONE_UE_SPESA';
  	CL_TRANSAZIONE_UE_ENTRATA CONSTANT varchar:='TRANSAZIONE_UE_ENTRATA';


    CL_PDC_FIN_QUARTO     CONSTANT varchar :='PDC_IV';
    CL_PDC_FIN_QUINTO     CONSTANT varchar :='PDC_V';
	CL_COFOG 			  CONSTANT varchar :='GRUPPO_COFOG';
	CL_SIOPE_SPESA_TERZO  CONSTANT varchar:='SIOPE_SPESA_I';
    CL_SIOPE_ENTRATA_TERZO  CONSTANT varchar:='SIOPE_ENTRATA_I';

	TIPO_ELAB_P CONSTANT varchar :='P'; -- previsione
    TIPO_ELAB_G CONSTANT varchar :='G'; -- gestione

    TIPO_ELEM_EU CONSTANT varchar:='U';

	APPROVA_PREV_SU_GEST CONSTANT varchar:='APROVA_PREV';

    GESTIONE_FASE       CONSTANT varchar:='G';
    PREVISIONE_FASE     CONSTANT varchar:='P'; -- 13.10.2016 Sofia
    PROVVISORIO_FASE    CONSTANT varchar:='E'; -- 13.10.2016 Sofia
    PROVVISORIO_EP_FASE    CONSTANT varchar:='EP'; -- 13.10.2016 Sofia


	macroAggrTipoId     integer:=null;
    programmaTipoId      integer:=null;
    categoriaTipoId      integer:=null;
    cdcTipoId            integer:=null;
    cdrTipoId            integer:=null;
    ricorrenteSpesaId    integer:=null;
    transazioneUeSpesaId INTEGER:=null;
    ricorrenteEntrataId    integer:=null;
    transazioneUeEntrataId INTEGER:=null;

    pdcFinIVId             integer:=null;
    pdcFinVId             integer:=null;
    cofogTipoId          integer:=null;
    siopeSpesaTipoId          integer:=null;
    siopeEntrataTipoId          integer:=null;

    bilElemGestTipoId integer:=null;
    bilElemPrevTipoId integer:=null;
    bilElemIdRet      integer:=null;
    bilancioId        integer:=null;
    periodoId         integer:=null;
    flagPerMemAttrId  integer:=null;

	codResult         integer:=null;
	dataInizioVal     timestamp:=null;
    faseBilElabId     integer:=null;

    CATEGORIA_STD     constant varchar := 'STD';
    categoriaCapCode  varchar :=null;

    faseOpNew         varchar(15):=null; -- 13.10.2016 Sofia

    -- 04.11.2016 anto JIRA-SIAC-4161
    bilElemStatoAN CONSTANT varchar:='AN';
    -- 04.11.2016 anto JIRA-SIAC-4161
	bilElemStatoANId  integer:=null;

    -- anto JIRA-SIAC-4167 15.11.2016
    dataInizioValClass timestamp:=null;
    dataFineValClass   timestamp:=null;
BEGIN



    messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;

--    dataInizioVal:=date_trunc('DAY', now());
    dataInizioVal:= clock_timestamp(); -- now();

    -- 12.12.2016 Sofia
	dataInizioValClass:= clock_timestamp();
    dataFineValClass:=(annoBilancio||'-01-01')::timestamp;

	strMessaggioFinale:='Approvazione bilancio di previsione.Aggiornamento struttura Gestione '||bilElemGestTipo||' da Previsione '||bilElemPrevTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APPROVA_PREV_SU_GEST||' IN CORSO : AGGIORNAMENTO STRUTTURE.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APPROVA_PREV_SU_GEST
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;

	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;




    strMessaggio:='Lettura bilElemStatoAN  per tipo='||bilElemStatoAN||'.';
	select tipo.elem_stato_id into strict bilElemStatoANId
    from siac_d_bil_elem_stato tipo
    where tipo.elem_stato_code=bilElemStatoAN
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


	strMessaggio:='Lettura bilElemPrevTipo  per tipo='||bilElemPrevTipo||'.';
	select tipo.elem_tipo_id into strict bilElemPrevTipoId
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=bilElemPrevTipo
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura bilElemGestTipo  per tipo='||bilElemGestTipo||'.';
	select tipo.elem_tipo_id into strict bilElemGestTipoId
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=bilElemGestTipo
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


    -- lettura classificatori Tipo Id
	strMessaggio:='Lettura flagPerMemAttrId  per attr='||FLAG_PER_MEM||'.';
	select attr.attr_id into strict flagPerMemAttrId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
	and   attr.attr_code=FLAG_PER_MEM
    and   attr.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

	strMessaggio:='Lettura cdcTipoId  per classif='||CL_CDC||'.';
	select tipo.classif_tipo_id into strict cdcTipoId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_CDC
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura cdcTipoId  per classif='||CL_CDR||'.';
	select tipo.classif_tipo_id into strict cdrTipoId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_CDR
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

    strMessaggio:='Lettura pdcFinIVId  per classif='||CL_PDC_FIN_QUARTO||'.';
	select tipo.classif_tipo_id into strict pdcFinIVId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_PDC_FIN_QUARTO
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

    strMessaggio:='Lettura pdcFinVId  per classif='||CL_PDC_FIN_QUINTO||'.';
	select tipo.classif_tipo_id into strict pdcFinVId
    from siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.classif_tipo_code=CL_PDC_FIN_QUINTO
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	if euElemTipo=TIPO_ELEM_EU then
		strMessaggio:='Lettura macroAggrTipoId  per classif='||CL_MACROAGGREGATO||'.';
		select tipo.classif_tipo_id into strict macroAggrTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_MACROAGGREGATO
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

		strMessaggio:='Lettura programmaTipoId  per classif='||CL_PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_PROGRAMMA
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura ricorrenteSpesaId  per classif='||CL_RICORRENTE_SPESA||'.';
		select tipo.classif_tipo_id into strict ricorrenteSpesaId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_RICORRENTE_SPESA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura transazioneUeSpesaId  per classif='||CL_TRANSAZIONE_UE_SPESA||'.';
		select tipo.classif_tipo_id into strict transazioneUeSpesaId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_TRANSAZIONE_UE_SPESA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura cofogTipoId  per classif='||CL_COFOG||'.';
		select tipo.classif_tipo_id into strict cofogTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_COFOG
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura siopeSpesaTipoId  per classif='||CL_SIOPE_SPESA_TERZO||'.';
		select tipo.classif_tipo_id into strict siopeSpesaTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_SIOPE_SPESA_TERZO
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

    else

		strMessaggio:='Lettura categoriaTipoId  per classif='||CL_CATEGORIA||'.';
		select tipo.classif_tipo_id into strict categoriaTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_CATEGORIA
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura ricorrenteEntrataId  per classif='||CL_RICORRENTE_ENTRATA||'.';
		select tipo.classif_tipo_id into strict ricorrenteEntrataId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_RICORRENTE_ENTRATA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura transazioneUeEntrataId  per classif='||CL_TRANSAZIONE_UE_ENTRATA||'.';
		select tipo.classif_tipo_id into strict transazioneUeEntrataId
    	from siac_d_class_tipo tipo
	    where tipo.ente_proprietario_id=enteProprietarioId
    	and   tipo.classif_tipo_code=CL_TRANSAZIONE_UE_ENTRATA
	    and   tipo.data_cancellazione is null
    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	    strMessaggio:='Lettura siopeEntrataTipoId  per classif='||CL_SIOPE_ENTRATA_TERZO||'.';
		select tipo.classif_tipo_id into strict siopeEntrataTipoId
	    from siac_d_class_tipo tipo
    	where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.classif_tipo_code=CL_SIOPE_ENTRATA_TERZO
    	and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


    end if;

    -- fine lettura classificatori Tipo Id
    strMessaggio:='Inserimento LOG per lettura classificatori tipo.';
	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio;


	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
    end if;

	-- 13.10.2016 Sofia testo il tipo elaborazione
    -- faseBilancio=PROVVISORIO_FASE    -- gestione da gestione   -- provvisorio
    -- faseBilancio=PROVVISORIO_EP_FASE -- gestione da previsione -- provvisorio
	-- faseBilancio=GESTIONE_FASE       -- gestione da previsione -- definitivo
    if faseBilancio=PROVVISORIO_FASE or faseBilancio=PROVVISORIO_EP_FASE then
    	faseOpNew:=PROVVISORIO_FASE;
    elsif faseBilancio=GESTIONE_FASE then
    	faseOpNew:=GESTIONE_FASE;
    end if;

--- 29.06.2016 Sofia - aggiunta gestione fase
--- cancellazione della precedente presente se diversa da G
--- inserimento della nuova G se non gia presente
-- 	strMessaggio:='Cancellazione fase tipo diversa da '||GESTIONE_FASE||' per bilancio annoBilancio='||annoBilancio::varchar||'.';
--  13.10.2016 Sofia
 	strMessaggio:='Cancellazione fase tipo diversa da '||faseOpNew||' per bilancio annoBilancio='||annoBilancio::varchar||'.';
    delete from siac_r_bil_fase_operativa r
    where r.ente_proprietario_id=enteproprietarioid
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   r.bil_id=bilancioId
    and   exists (select 1 from siac_d_fase_operativa d
                  where  d.fase_operativa_id=r.fase_operativa_id
                  and    d.fase_operativa_code!=faseOpNew);
--                  and    d.fase_operativa_code!=GESTIONE_FASE); -- 13.10.2016 Sofia

--   	strMessaggio:='Inserimento fase tipo='||GESTIONE_FASE||' per bilancio annoBilancio='||annoBilancio::varchar||'.';
-- 13.10.2016 Sofia
   	strMessaggio:='Inserimento fase tipo='||faseOpNew||' per bilancio annoBilancio='||annoBilancio::varchar||'.';
	insert into siac_r_bil_fase_operativa
	(bil_id,fase_operativa_id, validita_inizio, ente_proprietario_id, login_operazione )
	(select bilancioId,f.fase_operativa_id,dataInizioVal,f.ente_proprietario_id,loginOperazione
	 from siac_d_fase_operativa f
     where f.ente_proprietario_id=enteProprietarioId
--	 and   f.fase_operativa_code=GESTIONE_FASE
	 and   f.fase_operativa_code=faseOpNew      -- 13.10.2016 Sofia
	 and   not exists (select 1 from siac_r_bil_fase_operativa r
     	 		       where  r.bil_id=bilancioId
                       and    r.data_cancellazione is null));

---

	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
    end if;

	-- pulizia e popolamento tabella appoggio

	-- capitoli previsione non esistenti in gestione
-- 16.02.2016 Danie e Anto: la chiusura del record non  necessaria andando sempre per bilancio id
--    strMessaggio:='Pulizia fase_bil_t_prev_approva_str_elem_gest_nuovo.';
--    update fase_bil_t_prev_approva_str_elem_gest_nuovo g set data_cancellazione=now()
--    where ente_proprietario_id=enteProprietarioId
--    and   bil_id=bilancioId;

	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- capitoli previsione esistenti in gestione
	strMessaggio:='Pulizia fase_bil_t_prev_approva_str_elem_gest_esiste.';
    update fase_bil_t_prev_approva_str_elem_gest_esiste set data_cancellazione=now()
    where ente_proprietario_id=enteProprietarioId
    and   bil_id=bilancioId;


	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    strMessaggio:='Popolamento fase_bil_t_prev_approva_str_elem_gest_nuovo.';
    insert into fase_bil_t_prev_approva_str_elem_gest_nuovo
    (elem_id,elem_code,elem_code2, elem_code3,
     bil_id,fase_bil_elab_id,
     ente_proprietario_id,validita_inizio,login_operazione)
    (select prev.elem_id, prev.elem_code,prev.elem_code2,prev.elem_code3,
            prev.bil_id,faseBilElabId,
            prev.ente_proprietario_id, dataInizioVal,loginOperazione
     from siac_t_bil_elem prev
     where prev.ente_proprietario_id=enteProprietarioId
     and   prev.elem_tipo_id=bilElemPrevTipoId
     and   prev.bil_id=bilancioId
     and   prev.data_cancellazione is null

     and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                  					 where rstato.elem_id=prev.elem_id
				                     and   rstato.elem_stato_id!=bilElemStatoANId
					                 and   rstato.data_cancellazione is null
					                 and   rstato.validita_fine is null
				                     )

     and   date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
     and   not exists (select 1 from siac_t_bil_elem gest
                       where gest.ente_proprietario_id=prev.ente_proprietario_id
                       and   gest.bil_id=prev.bil_id
                       and   gest.elem_tipo_id=bilElemGestTipoId
                       and   gest.elem_code=prev.elem_code
                       and   gest.elem_code2=prev.elem_code2
                       and   gest.elem_code3=prev.elem_code3
                       and   gest.data_cancellazione is null

                       and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                  					 where rstato.elem_id=gest.elem_id
				                     and   rstato.elem_stato_id!=bilElemStatoANId
					                 and   rstato.data_cancellazione is null
					                 and   rstato.validita_fine isnull
				                     )

                       and   date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
   			 		   and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
                       order by gest.elem_id limit 1
                      )
     order by prev.elem_code::integer,prev.elem_code2::integer,prev.elem_code3
     );


	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

    if checkGest=true then

    	strMessaggio:='Popolamento fase_bil_t_prev_approva_str_elem_gest_esiste - previsione con gestione eq esistente.';
	    insert into fase_bil_t_prev_approva_str_elem_gest_esiste
    	(elem_prev_id, elem_gest_id,elem_code,elem_code2, elem_code3,
         bil_id,fase_bil_elab_id,
         ente_proprietario_id,validita_inizio,login_operazione)
	    (select prev.elem_id, gest.elem_id,prev.elem_code,prev.elem_code2,prev.elem_code3,
                prev.bil_id,faseBilElabId,
                enteProprietarioId, dataInizioVal,loginOperazione
    	 from siac_t_bil_elem prev, siac_t_bil_elem gest
	     where prev.ente_proprietario_id=enteProprietarioId
	     and   prev.elem_tipo_id=bilElemPrevTipoId
	     and   prev.bil_id=bilancioId
	     and   gest.ente_proprietario_id=prev.ente_proprietario_id
	     and   gest.bil_id=prev.bil_id
         and   gest.elem_tipo_id=bilElemGestTipoId
    	 and   gest.elem_code=prev.elem_code
	     and   gest.elem_code2=prev.elem_code2
	     and   gest.elem_code3=prev.elem_code3
		 and   prev.data_cancellazione is null
	     and   date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
    	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
	     and   gest.data_cancellazione is null
    	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
	   	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
	   	 and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                  					 where rstato.elem_id=prev.elem_id
				                     and   rstato.elem_stato_id!=bilElemStatoANId
					                 and   rstato.data_cancellazione is null
					                 and   rstato.validita_fine isnull
				                     )
		and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                  					 where rstato.elem_id=gest.elem_id
				                     and   rstato.elem_stato_id!=bilElemStatoANId
					                 and   rstato.data_cancellazione is null
					                 and   rstato.validita_fine isnull
				                     )
    	 order by prev.elem_code::integer,prev.elem_code2::integer,prev.elem_code3
	    );


		codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
	     validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
	    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

        -- capitoli gestione esistenti senza capitolo eq in previsione
    	strMessaggio:='Popolamento fase_bil_t_prev_approva_str_elem_gest_esiste - gestione senza previsione eq esistente.';
	    insert into fase_bil_t_prev_approva_str_elem_gest_esiste
    	(elem_prev_id, elem_gest_id,elem_code,elem_code2, elem_code3,
         bil_id,fase_bil_elab_id,
         ente_proprietario_id,validita_inizio,login_operazione)
	    (select null, gest.elem_id,gest.elem_code,gest.elem_code2,gest.elem_code3,
        	 	gest.bil_id,faseBilElabId,
                enteProprietarioId,dataInizioVal,loginOperazione
    	 from  siac_t_bil_elem gest
	     where gest.ente_proprietario_id=enteProprietarioId
	     and   gest.elem_tipo_id=bilElemGestTipoId
	     and   gest.bil_id=bilancioId
	     --and   gest.ente_proprietario_id=prev.ente_proprietario_id
	     --and   gest.bil_id=prev.bil_id
	     and   gest.data_cancellazione is null
	     and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                  					 where rstato.elem_id=gest.elem_id
				                     and   rstato.elem_stato_id!=bilElemStatoANId
					                 and   rstato.data_cancellazione is null
					                 and   rstato.validita_fine isnull
				                     )
    	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',gest.validita_inizio)
	   	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',gest.validita_fine) or gest.validita_fine is null)
         and   not exists (select  1 from siac_t_bil_elem prev
  						   where  prev.ente_proprietario_id=gest.ente_proprietario_id
                           and    prev.bil_id=gest.bil_id
                           and    prev.elem_tipo_id=bilElemPrevTipoId
                           and    prev.elem_code=gest.elem_code
						   and    prev.elem_code2=gest.elem_code2
					       and    prev.elem_code3=gest.elem_code3
					       and    prev.data_cancellazione is null
					       and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
                  					 where rstato.elem_id=prev.elem_id
				                     and   rstato.elem_stato_id!=bilElemStatoANId
					                 and   rstato.data_cancellazione is null
					                 and   rstato.validita_fine isnull
				                     )
				    	   and    date_trunc('day',dataElaborazione)>=date_trunc('day',prev.validita_inizio)
				      	   and    ( date_trunc('day',dataElaborazione)<=date_trunc('day',prev.validita_fine) or prev.validita_fine is null)
                           order by prev.elem_id limit 1)
    	 order by gest.elem_code::integer,gest.elem_code2::integer,gest.elem_code3
	    );

  	    codResult:=null;
 	    insert into fase_bil_t_elaborazione_log
        (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
        )
	    values
        (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

        if codResult is null then
     	 raise exception ' Errore in inserimento LOG.';
        end if;

	end if;

    codResult:=null;
    strMessaggio:='Popolamento fase_bil_t_prev_approva_str_elem_gest_nuovo.Verifica esistenza capitoli di previsione da approvare.';
    select 1 into codResult
    from fase_bil_t_prev_approva_str_elem_gest_nuovo fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    order by fase.fase_bil_prev_str_nuovo_id limit 1;


    if codResult is not null then
 	-- inserimento nuove strutture
    -- capitoli previsione non esistenti in gestione
     strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||'.';

	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


    for elemBilPrev in
    (select elem_id, elem_code,elem_code2,elem_code3
     from fase_bil_t_prev_approva_str_elem_gest_nuovo
     where ente_proprietario_id=enteProprietarioId
     and   bil_id=bilancioId
     and   fase_bil_elab_id=faseBilElabId
     and   data_cancellazione is NULL
     and   validita_fine is null
     order by elem_code::integer,elem_code2::integer,elem_code3
    )
    loop
    	bilElemIdRet:=null;
        strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			  '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                              ||elemBilPrev.elem_code2||' '
                                              ||elemBilPrev.elem_code3||' : siac_t_bil_elem.' ;
        -- siac_t_bil_elem
    	insert into siac_t_bil_elem
	    (elem_code,elem_code2,elem_code3, elem_desc,elem_desc2,
    	 elem_tipo_id, bil_id,ordine,livello,
	     validita_inizio , ente_proprietario_id,login_operazione)
        (select prev.elem_code,prev.elem_code2,prev.elem_code3,prev.elem_desc, prev.elem_desc2,
	            bilElemGestTipoId,bilancioId,prev.ordine,prev.livello,
                dataInizioVal,prev.ente_proprietario_id,loginOperazione
         from siac_t_bil_elem prev
         where prev.elem_id=elemBilPrev.elem_id)
         returning elem_id into bilElemIdRet;

        if bilElemIdRet is null then raise exception ' Inserimento non effettuato.';  end if;

        codResult:=null;
        strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			  '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                              ||elemBilPrev.elem_code2||' '
                                              ||elemBilPrev.elem_code3||' : siac_r_bil_elem_stato.' ;

        -- siac_r_bil_elem_stato
	    strMessaggio:='Inserimento siac_r_bil_elem_stato.';
	    insert into siac_r_bil_elem_stato
    	(elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,login_operazione)
    	(select bilElemIdRet,stato.elem_stato_id,dataInizioVal,stato.ente_proprietario_id, loginOperazione
         from siac_r_bil_elem_stato stato
         where stato.elem_id=elemBilPrev.elem_id
         and   stato.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio)
	   	 and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',stato.validita_fine) or stato.validita_fine is null)
         )
         returning bil_elem_stato_id into codResult;
         if codResult is null then raise exception ' Inserimento non effettuato.'; end if;

         codResult:=null;
         -- siac_r_bil_elem_categoria
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			   '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                              ||elemBilPrev.elem_code2||' '
                                              ||elemBilPrev.elem_code3||' : siac_r_bil_elem_categoria.' ;

         insert into siac_r_bil_elem_categoria
	     (elem_id,  elem_cat_id, validita_inizio,ente_proprietario_id, login_operazione)
         (select bilElemIdRet, cat.elem_cat_id,dataInizioVal,cat.ente_proprietario_id,loginOperazione
          from siac_r_bil_elem_categoria cat
          where cat.elem_id=elemBilPrev.elem_id
          and   cat.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',cat.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',cat.validita_fine) or cat.validita_fine is null)
         )
         returning bil_elem_r_cat_id into codResult;
         if codResult is null then raise exception ' Inserimento non effettuato.'; end if;


         -- 02.03.2016 Dani: leggo categoria capitolo inserita.
         select d.elem_cat_code into categoriaCapCode
         from siac_r_bil_elem_categoria r, siac_d_bil_elem_categoria d where
         d.elem_cat_id=r.elem_cat_id
         and r.bil_elem_r_cat_id=codResult;

         codResult:=null;
         -- siac_r_bil_elem_attr (escludere FLAG_PER_MEM)
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			   '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                              ||elemBilPrev.elem_code2||' '
                                              ||elemBilPrev.elem_code3||' : siac_r_bil_elem_attr.' ;
         insert into siac_r_bil_elem_attr
         ( elem_id,attr_id, tabella_id,boolean,percentuale,testo,numerico,
           validita_inizio,ente_proprietario_id,login_operazione
         )
         (select bilElemIdRet, attr.attr_id,attr.tabella_id,attr.boolean,attr.percentuale,attr.testo,attr.numerico,
                 dataInizioVal,attr.ente_proprietario_id, loginOperazione
          from siac_r_bil_elem_attr attr
          where attr.elem_id=elemBilPrev.elem_id
          and   attr.attr_id!=flagPerMemAttrId
          and   attr.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine) or attr.validita_fine is null)
          );

          select 1 into codResult
          from siac_r_bil_elem_attr
          where elem_id=bilElemIdRet
          and   data_cancellazione is null
          and   validita_fine is null
          order by elem_id
          limit 1;
          if codResult is null then raise exception ' Nessun attributo inserito.'; end if;

/* 31.07.2017 Sofia - gestione vincoli e atti di legge commentata
         codResult:=null;
         -- siac_r_vincolo_bil_elem
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			   '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                              ||elemBilPrev.elem_code2||' '
                                              ||elemBilPrev.elem_code3||' : siac_r_vincolo_bil_elem.' ;
         insert into siac_r_vincolo_bil_elem
         ( elem_id,vincolo_id, validita_inizio,ente_proprietario_id,login_operazione
         )
         (select bilElemIdRet, v.vincolo_id, dataInizioVal,v.ente_proprietario_id, loginOperazione
          from siac_r_vincolo_bil_elem v
          where v.elem_id=elemBilPrev.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          );

          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : siac_r_vincolo_bil_elem.Verifica inserimento.' ;
          select  1  into codResult
          from 	siac_r_vincolo_bil_elem v
          where v.elem_id=elemBilPrev.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          and   not exists (select 1 from siac_r_vincolo_bil_elem v1
	                        where v1.elem_id= bilElemIdRet
    	                    and   v1.data_cancellazione is null
				            and   date_trunc('day',dataElaborazione)>=date_trunc('day',v1.validita_inizio)
				  	   	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v1.validita_fine) or v1.validita_fine is null)
                            order by v1.elem_id
                            limit 1
                            )
          order by v.elem_id
          limit 1;
          if codResult is not null then raise exception ' Non effettuato.'; end if;

 04.03.2019 Sofia jira siac-6630 - tolto commento  */
        /** 04.03.2019 Sofia jira siac-6630 - inizio - tolto commento **/
         codResult:=null;
         -- siac_r_bil_elem_atto_legge
         strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			   '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                              ||elemBilPrev.elem_code2||' '
                                              ||elemBilPrev.elem_code3||' : siac_r_bil_elem_atto_legge.' ;
         insert into siac_r_bil_elem_atto_legge
         ( elem_id,attolegge_id, descrizione, gerarchia,finanziamento_inizio,finanziamento_fine,
           validita_inizio,ente_proprietario_id,login_operazione
         )
         (select bilElemIdRet, v.attolegge_id, v.descrizione,v.gerarchia,v.finanziamento_inizio,v.finanziamento_fine,
                 dataInizioVal,v.ente_proprietario_id, loginOperazione
          from siac_r_bil_elem_atto_legge v
          where v.elem_id=elemBilPrev.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          );


          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : siac_r_bil_elem_atto_legge.Verifica inserimento.' ;
          select 1  into codResult
          from 	siac_r_bil_elem_atto_legge v
          where v.elem_id=elemBilPrev.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          and   not exists (select 1 from siac_r_bil_elem_atto_legge v1
	                        where v1.elem_id= bilElemIdRet
    	                    and   v1.data_cancellazione is null
				            and   date_trunc('day',dataElaborazione)>=date_trunc('day',v1.validita_inizio)
				  	   	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v1.validita_fine) or v1.validita_fine is null)
                            order by v1.elem_id
                            limit 1
                            )
          order by v.elem_id
          limit 1;
          if codResult is not null then raise exception ' Non effettuato.'; end if;
/*  04.03.2019 Sofia jira siac-6630 - tolto commento
31.07.2017 Sofia - chiusura
*/
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : siac_r_bil_elem_rel_tempo.' ;
 		  insert into siac_r_bil_elem_rel_tempo
          (elem_id, elem_id_old, validita_inizio, ente_proprietario_id,login_operazione)
          (select bilElemIdRet,v.elem_id_old, dataInizioVal,v.ente_proprietario_id, loginOperazione
           from siac_r_bil_elem_rel_tempo v
           where v.elem_id=elemBilPrev.elem_id
	       and   v.data_cancellazione is null
           and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	   and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null));

          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : siac_r_bil_elem_rel_tempo.Verifica inserimento.' ;
          select 1  into codResult
          from 	siac_r_bil_elem_rel_tempo v
          where v.elem_id=elemBilPrev.elem_id
          and   v.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',v.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v.validita_fine) or v.validita_fine is null)
          and   not exists (select 1 from siac_r_bil_elem_rel_tempo v1
	                        where v1.elem_id= bilElemIdRet
    	                    and   v1.data_cancellazione is null
				            and   date_trunc('day',dataElaborazione)>=date_trunc('day',v1.validita_inizio)
				  	   	    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',v1.validita_fine) or v1.validita_fine is null)
                            order by v1.elem_id
                            limit 1
                            )
          order by v.elem_id
          limit 1;
          if codResult is not null then raise exception ' Non effettuato.'; end if;


	      codResult:=null;
	      -- siac_r_bil_elem_class
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : siac_r_bil_elem_class.' ;
		/*
         insert into siac_r_bil_elem_class
         (elem_id,classif_id, validita_inizio, ente_proprietario_id,login_operazione)
         (select bilElemIdRet, class.classif_id,dataInizioVal,class.ente_proprietario_id,loginOperazione
          from siac_r_bil_elem_class class ,
          where class.elem_id=elemBilPrev.elem_id
          and   class.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine) or class.validita_fine is null));
          */

          /** JIRA-SIAC-4167 - aggiunto controllo su validita classificatore **/
         insert into siac_r_bil_elem_class
         (elem_id,classif_id, validita_inizio, ente_proprietario_id,login_operazione)
         (select bilElemIdRet, class.classif_id,dataInizioVal,class.ente_proprietario_id,loginOperazione
          from siac_r_bil_elem_class class,siac_t_class c
          where class.elem_id=elemBilPrev.elem_id
          and   c.classif_id=class.classif_id
          and   class.data_cancellazione is null
          and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	   	  and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine) or class.validita_fine is null)
          and   c.data_cancellazione is null
          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null));





          select 1 into codResult
          from siac_r_bil_elem_class
          where elem_id=bilElemIdRet
          and   data_cancellazione is null
          and   validita_fine is null
          order by elem_id
          limit 1;
          if codResult is null then raise exception ' Nessun classificatore inserito.'; end if;

          -- controlli sui classificatori obbligatori
          -- CL_CDC, CL_CDR
          codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_CDC||' '||CL_CDR||'.' ;
           /*
          select 1 into codResult
          from siac_r_bil_elem_class r, siac_t_class c
          where r.elem_id=bilElemIdRet
          and   c.classif_id=r.classif_id
          and   c.classif_tipo_id in (cdcTipoId, cdrTipoId)
          and   c.data_cancellazione is null
          and   c.validita_fine is null
          order by r.elem_id
          limit 1;
          if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
			*/

            /** JIRA-SIAC-4167  **/
		  select 1 into codResult
          from siac_r_bil_elem_class r, siac_t_class c
          where r.elem_id=bilElemIdRet
          and   c.classif_id=r.classif_id
          and   c.classif_tipo_id in (cdcTipoId, cdrTipoId)
          and   c.data_cancellazione is null
          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
          order by r.elem_id
          limit 1;

          if codResult is null then
           strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
           insert into fase_bil_t_prev_apertura_segnala
           (elem_id,
	        elem_code,
			elem_code2,
			elem_code3,
		    bil_id,
		    fase_bil_elab_id,
		    segnala_codice,
			segnala_desc,
			validita_inizio,
			ente_proprietario_id,
		    login_operazione)
           (select capitolo.elem_id,
                   capitolo.elem_code,
                   capitolo.elem_code2,
                   capitolo.elem_code3,
                   capitolo.bil_id,
                   faseBilElabId,
                   'SAC',
                   'Sac mancante',
                   dataInizioVal,
                   capitolo.ente_proprietario_id,
                   loginOperazione
            from siac_t_bil_elem capitolo
            where  capitolo.elem_id=bilElemIdRet
            )
            returning fase_bil_prev_ape_seg_id into codresult;

            if codResult is null then raise exception 'Nessuno inserimento effettuato.'; end if;
          end if;


   	      -- CL_PDC_FIN_QUINTO, CL_PDC_FIN_QUARTO
		  codResult:=null;
          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_PDC_FIN_QUARTO||' '||CL_PDC_FIN_QUINTO||'.' ;

          /*
          select 1 into codResult
          from siac_r_bil_elem_class r, siac_t_class c
          where r.elem_id=bilElemIdRet
          and   c.classif_id=r.classif_id
          and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
          and   c.data_cancellazione is null
          and   c.validita_fine is null
          order by r.elem_id
          limit 1;

          -- 02.03.2016 Dani. l'obbligatorieta del classificatore vale solo per capitolo STANDARD
		  if categoriaCapCode = CATEGORIA_STD then
	          if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
          end if;
			*/

/** JIRA-SIAC-4167 **/
          select 1 into codResult
          from siac_r_bil_elem_class r, siac_t_class c
          where r.elem_id=bilElemIdRet
          and   c.classif_id=r.classif_id
          and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
          and   c.data_cancellazione is null
          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
          order by r.elem_id
          limit 1;



          -- Obbligatorieta del classificatore vale solo per capitolo STANDARD
		  if categoriaCapCode = CATEGORIA_STD then
	      --  JIRA-SIAC-4167  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
           if codResult is null then
          	strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
            insert into fase_bil_t_prev_apertura_segnala
            (elem_id,
	         elem_code,
		 	 elem_code2,
			 elem_code3,
		     bil_id,
		     fase_bil_elab_id,
		     segnala_codice,
			 segnala_desc,
			 validita_inizio,
			 ente_proprietario_id,
		     login_operazione)
            (select capitolo.elem_id,
                    capitolo.elem_code,
                    capitolo.elem_code2,
                    capitolo.elem_code3,
                    capitolo.bil_id,
                    faseBilElabId,
                    'PDCFIN',
                    'PdcFin mancante',
                    dataInizioVal,
                    capitolo.ente_proprietario_id,
                    loginOperazione
             from siac_t_bil_elem capitolo
             where  capitolo.elem_id=bilElemIdRet
             )
             returning fase_bil_prev_ape_seg_id into codresult;

             if codResult is null then raise exception 'Nessuno inserimento effettuato.'; end if;
           end if;
          end if;

          if euElemTipo=TIPO_ELEM_EU then
	          -- CL_PROGRAMMA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_PROGRAMMA||'.' ;
	          /*
              select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=programmaTipoId
              and   c.data_cancellazione is null
         	  and   c.validita_fine is null
              order by r.elem_id
        	  limit 1;
              -- 02.03.2016 Dani. l'obbligatorieta del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
                  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;
				*/
/** JIRA-SIAC-4167 **/
			  select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=programmaTipoId
              and   c.data_cancellazione is null
         	  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              order by r.elem_id
        	  limit 1;



              -- Obbligatorieta del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
                  -- JIRA-SIAC-4167 if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
                  if codResult is null then

                   strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_PROGRAMMA,
     	                   CL_PROGRAMMA||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

            	   if codResult is null then raise exception 'Nessuno inserimento effettuato.'; end if;
                  end if;
              end if;



    	      -- CL_MACROAGGREGATO
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_MACROAGGREGATO||'.' ;
	          /*
              select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=macroAggrTipoId
              and   c.data_cancellazione is null
          	  and   c.validita_fine is null
              order by r.elem_id
        	  limit 1;
          -- 02.03.2016 Dani. l'obbligatorieta del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
		          if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;
				*/

                /** JIRA-SIAC-4167 **/
              select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=macroAggrTipoId
              and   c.data_cancellazione is null
          	  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              order by r.elem_id
        	  limit 1;

              -- Obbligatorieta del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
		          -- JIRA-SIAC-4167 if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
                  if codResult is null then

                   strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_MACROAGGREGATO,
     	                   CL_MACROAGGREGATO||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

            	   if codResult is null then raise exception 'Nessuno inserimento effettuato.';  end if;

                  end if;
              end if;

			  -- CL_COFOG
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_COFOG||'.' ;

			  -- 02.03.2016 Dani: definizione classificatore neseccaria solo se presente in previsione
              /*
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=cofogTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=cofogTipoId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
				*/

                select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=cofogTipoId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
	   	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
		      and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=cofogTipoId
					             and   c.data_cancellazione is null
							     and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
				  	   	         and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                                 )
			  order by r.elem_id limit 1;

              -- --JIRA-SIAC-4167 14.11.2016 Sofia
	          if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_COFOG,
     	                   CL_COFOG||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;

              end if;



        	  -- CL_RICORRENTE_SPESA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_RICORRENTE_SPESA||'.' ;
			  -- 02.03.2016 Dani: definizione classificatore neseccaria solo se presente in previsione
              /*
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=ricorrenteSpesaId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=ricorrenteSpesaId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
				*/
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=ricorrenteSpesaId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
	   	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
		      and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
	   	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=ricorrenteSpesaId
					             and   c.data_cancellazione is null
							     and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
					   	         and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                                )
			  order by r.elem_id limit 1;

              -- JIRA-SIAC-4167 14.11.2016 Sofia
      		  if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_RICORRENTE_SPESA,
     	                   CL_RICORRENTE_SPESA||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;

	          -- CL_SIOPE_SPESA_TERZO
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_SIOPE_SPESA_TERZO||'.' ;
				/*
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=siopeSpesaTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=siopeSpesaTipoId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
--                                 order by r.elem_id
--                                 limit 1
                                 )
			  order by r.elem_id
              limit 1;

	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
				*/

                select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=siopeSpesaTipoId
              and   r.data_cancellazione is null
              and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
  	   	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  	   	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=siopeSpesaTipoId
					             and   c.data_cancellazione is null
							     and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
				  	   	         and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                               )
			  order by r.elem_id
              limit 1;

              -- JIRA-SIAC-4167 14.11.2016 Sofia
              if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_SIOPE_SPESA_TERZO,
     	                   CL_SIOPE_SPESA_TERZO||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;


    	      -- CL_TRANSAZIONE_UE_SPESA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_TRANSAZIONE_UE_SPESA||'.' ;

			  -- 02.03.2016 Dani: definizione classificatore neseccaria solo se presente in previsione
              /*
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=transazioneUeSpesaId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=transazioneUeSpesaId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
              */
select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=transazioneUeSpesaId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
  	   	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
		      and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  	   	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=transazioneUeSpesaId
					             and   c.data_cancellazione is null
							     and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
					     	     and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                               )
			  order by r.elem_id limit 1;

			  -- JIRA-SIAC-4167 14.11.2016 Sofia
              if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_TRANSAZIONE_UE_SPESA,
     	                   CL_TRANSAZIONE_UE_SPESA||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;
          else

    	      -- CL_CATEGORIA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_CATEGORIA||'.' ;
	          /*
              select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=categoriaTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              order by r.elem_id
        	  limit 1;
          -- 02.03.2016 Dani. l'obbligatorieta del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
				  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;
				*/
              select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=bilElemIdRet
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=categoriaTipoId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
    	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
		      and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
    	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              order by r.elem_id
        	  limit 1;

              -- Obbligatorieta del classificatore vale solo per capitolo STANDARD
              if categoriaCapCode = CATEGORIA_STD then
                  -- JIRA-SIAC-4167 14.11.2016 Sofia
				  -- if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
                  if codResult is null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_CATEGORIA,
     	                   CL_CATEGORIA||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;
              end if;


        	  -- CL_RICORRENTE_ENTRATA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_RICORRENTE_ENTRATA||'.' ;
			  -- 02.03.2016 Dani: definizione classificatore neseccaria solo se presente in previsione
              /*
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=ricorrenteEntrataId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=ricorrenteEntrataId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
				*/
                select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=ricorrenteEntrataId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
    	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
    	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=ricorrenteEntrataId
					             and   c.data_cancellazione is null
							     and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
					   	         and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                                )
			  order by r.elem_id limit 1;

              -- JIRA-SIAC-4167 14.11.2016 Sofia
              if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_RICORRENTE_ENTRATA,
     	                   CL_RICORRENTE_ENTRATA||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;



	          -- CL_SIOPE_ENTRATA_TERZO
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_SIOPE_ENTRATA_TERZO||'.' ;
				/*
	          select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=siopeEntrataTipoId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists (select 1
				      	        from siac_r_bil_elem_class r, siac_t_class c
				        	    where r.elem_id=bilElemIdRet
					            and   c.classif_id=r.classif_id
					   	        and   c.classif_tipo_id=siopeEntrataTipoId
			                    and   c.data_cancellazione is null
							    and   c.validita_fine is null
                                order by r.elem_id
                                limit 1)
			  order by r.elem_id
              limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
				*/

select 1 into codResult
    	      from siac_r_bil_elem_class r, siac_t_class c
        	  where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=siopeEntrataTipoId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
    	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
		      and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
    	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists (select 1
				      	        from siac_r_bil_elem_class r, siac_t_class c
				        	    where r.elem_id=bilElemIdRet
					            and   c.classif_id=r.classif_id
					   	        and   c.classif_tipo_id=siopeEntrataTipoId
			                    and   c.data_cancellazione is null
							    and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
    	      				    and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                                order by r.elem_id
                                limit 1)
			  order by r.elem_id
              limit 1;

              -- JIRA-SIAC-4167 14.11.2016 Sofia
              if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_SIOPE_ENTRATA_TERZO,
     	                   CL_SIOPE_ENTRATA_TERZO||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;

    	      -- CL_TRANSAZIONE_UE_ENTRATA
              codResult:=null;
        	  strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        				    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                	                               ||elemBilPrev.elem_code2||' '
                    	                           ||elemBilPrev.elem_code3||' : verifica classificatore '||CL_TRANSAZIONE_UE_ENTRATA||'.' ;

			  -- 02.03.2016 Dani: definizione classificatore neseccaria solo se presente in previsione
          /*
              select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=transazioneUeEntrataId
              and   c.data_cancellazione is null
		      and   c.validita_fine is null
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=transazioneUeEntrataId
					             and   c.data_cancellazione is null
							     and   c.validita_fine is null
                                 )
			  order by r.elem_id limit 1;
	          if codResult is not null then raise exception ' Nessuno inserimento effettuato.'; end if;
          end if;
			*/

            select 1 into codResult
              from  siac_r_bil_elem_class r, siac_t_class c
              where r.elem_id=elemBilPrev.elem_id
	          and   c.classif_id=r.classif_id
    	      and   c.classif_tipo_id=transazioneUeEntrataId
              and   r.data_cancellazione is null
		      and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
    	      and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine) or r.validita_fine is null)
              and   c.data_cancellazione is null
              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
    	      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              and   not exists ( select distinct 1
					    	     from siac_r_bil_elem_class r, siac_t_class c
					       	     where r.elem_id=bilElemIdRet
						         and   c.classif_id=r.classif_id
					   	         and   c.classif_tipo_id=transazioneUeEntrataId
					             and   c.data_cancellazione is null
							     and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
				    	         and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                                )
			  order by r.elem_id limit 1;

              -- JIRA-SIAC-4167 14.11.2016 Sofia
              if codResult is not null then
                   codResult:=null;
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select capitolo.elem_id,
                           capitolo.elem_code,
                           capitolo.elem_code2,
                           capitolo.elem_code3,
	                       capitolo.bil_id,
     	                   faseBilElabId,
	                       CL_TRANSAZIONE_UE_ENTRATA,
     	                   CL_TRANSAZIONE_UE_ENTRATA||' mancante',
         	               dataInizioVal,
             	           capitolo.ente_proprietario_id,
	                       loginOperazione
	                from siac_t_bil_elem capitolo
	                where  capitolo.elem_id=bilElemIdRet
                   )
	               returning fase_bil_prev_ape_seg_id into codresult;

              	   if codResult is  null then raise exception ' Nessuno inserimento effettuato.'; end if;
              end if;

          end if;

          strMessaggio:='Inserimento nuove strutture per tipo='||bilElemGestTipo||
        			    '.Elemento di bilancio '||elemBilPrev.elem_code||' '
                                               ||elemBilPrev.elem_code2||' '
                                               ||elemBilPrev.elem_code3||' : aggiornamento relazione tra elem_id_prev e elem_id_gest.' ;
          update fase_bil_t_prev_approva_str_elem_gest_nuovo set elem_gest_id=bilElemIdRet
          where elem_id=elemBilPrev.elem_id
          and   fase_bil_elab_id=faseBilElabId;

  end loop;

  strMessaggio:='Conclusione inserimento nuove strutture per tipo='||bilElemGestTipo||'.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;

  if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
  end if;

 end if;

 if checkGest=true then

 	codResult:=null;
    strMessaggio:='Verifica esistenza elementi di bilancio di gestione equivalenti da aggiornare da previsione.';
	select 1 into codResult
    from fase_bil_t_prev_approva_str_elem_gest_esiste fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.elem_prev_id is not null
    order by fase.fase_bil_prev_str_esiste_id
    limit 1;
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
	   validita_inizio, login_operazione, ente_proprietario_id
    )
 	values
	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	 returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
	end if;

    if codResult is not null then
    -- popolamento tabelle bck per salvataggio precedenti strutture
    -- siac_t_bil_elem
	  codResult:=null;
      strMessaggio:='Backup vecchie struttura per capitoli di gestione equivalente esistenti - INIZIO.';
	  insert into fase_bil_t_elaborazione_log
	  (fase_bil_elab_id,fase_bil_elab_log_operazione,
	   validita_inizio, login_operazione, ente_proprietario_id
	  )
	  values
	  (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	  returning fase_bil_elab_log_id into codResult;

	  if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
	  end if;

    strMessaggio:='Backup vecchia struttura [siac_t_bil_elem] per capitoli di gestione equivalente.';
    insert into bck_fase_bil_t_prev_approva_bil_elem
    (elem_prev_id, elem_bck_id,elem_bck_code,elem_bck_code2, elem_bck_code3,
     elem_bck_desc,elem_bck_desc2, elem_bck_bil_id, elem_bck_id_padre, elem_bck_tipo_id, elem_bck_livello,
     elem_bck_ordine, elem_bck_data_creazione, elem_bck_data_modifica, elem_bck_login_operazione,
     elem_bck_validita_inizio, elem_bck_validita_fine,fase_bil_elab_id,
     ente_proprietario_id, login_operazione,validita_inizio)
    (select fase.elem_prev_id,elem.elem_id, elem.elem_code,elem.elem_code2,elem.elem_code3,
            elem.elem_desc,elem.elem_desc2, elem.bil_id, elem.elem_id_padre, elem.elem_tipo_id, elem.livello,
            elem.ordine, elem.data_creazione, elem.data_modifica, elem.login_operazione,
            elem.validita_inizio, elem.validita_fine,faseBilElabId,
            elem.ente_proprietario_id, loginOperazione,dataInizioVal
	 from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem elem
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   elem.elem_id=fase.elem_gest_id
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   fase.elem_prev_id is not null
     );

     codResult:=null;
     strMessaggio:=strMessaggio||' Verifica inserimento.';
     select 1 into codResult
     from fase_bil_t_prev_approva_str_elem_gest_esiste fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.elem_gest_id is not null
     and   fase.elem_prev_id is not null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem bck
                       where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                       and   bck.elem_bck_id=fase.elem_gest_id
                       and   bck.data_cancellazione is null
                       and   bck.validita_fine is null);
     if codResult is not null then raise exception ' Elementi mancanti di backup.'; end if;


--- 29.06.2016 Sofia gestione backup per stato, classificatori, attributi e categoria
--  che non devono essere cancallati ma sovrascritti
	  -- bck per attributi e classificatori, stato e categoria
     strMessaggio:='Backup vecchia struttura [siac_r_bil_elem_stato] per capitoli di gestione equivalente.';
     insert into bck_fase_bil_t_prev_approva_bil_elem_stato
     (elem_bck_id,elem_bck_stato_id,
      elem_bck_data_creazione, elem_bck_data_modifica, elem_bck_login_operazione,
      elem_bck_validita_inizio, elem_bck_validita_fine,fase_bil_elab_id,
      ente_proprietario_id, login_operazione,validita_inizio)
     (select elem.elem_id, elem.elem_stato_id,
			 elem.data_creazione, elem.data_modifica, elem.login_operazione,
             elem.validita_inizio, elem.validita_fine,faseBilElabId,
             elem.ente_proprietario_id, loginOperazione,dataInizioVal
	  from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_stato elem
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   elem.elem_id=fase.elem_gest_id
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   fase.elem_prev_id is not null
      );

      codResult:=null;
      strMessaggio:=strMessaggio||' Verifica inserimento.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_stato bck
                        where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                        and   bck.elem_bck_id=fase.elem_gest_id
                        and   bck.data_cancellazione is null
                        and   bck.validita_fine is null);
      if codResult is not null then raise exception ' Elementi mancanti di backup.'; end if;


      strMessaggio:='Backup vecchia struttura [siac_r_bil_elem_attr] per capitoli di gestione equivalente.';
      insert into bck_fase_bil_t_prev_approva_bil_elem_attr
      (elem_bck_id,elem_bck_attr_id,elem_bck_tabella_id,
       elem_bck_boolean,elem_bck_percentuale,
       elem_bck_testo,elem_bck_numerico,
       elem_bck_data_creazione, elem_bck_data_modifica, elem_bck_login_operazione,
       elem_bck_validita_inizio, elem_bck_validita_fine,fase_bil_elab_id,
       ente_proprietario_id, login_operazione,validita_inizio)
      (select fase.elem_gest_id, elem.attr_id, elem.tabella_id,
      		  elem."boolean",elem.percentuale, elem.testo, elem.numerico,
			  elem.data_creazione, elem.data_modifica, elem.login_operazione,
              elem.validita_inizio, elem.validita_fine,faseBilElabId,
              elem.ente_proprietario_id, loginOperazione,dataInizioVal
	   from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_attr elem
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   elem.elem_id=fase.elem_gest_id
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   fase.elem_prev_id is not null
      );

      codResult:=null;
      strMessaggio:=strMessaggio||' Verifica inserimento.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_attr bck
                        where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                        and   bck.elem_bck_id=fase.elem_gest_id
                        and   bck.data_cancellazione is null
                        and   bck.validita_fine is null);
      if codResult is not null then raise exception ' Elementi mancanti di backup.'; end if;

      strMessaggio:='Backup vecchia struttura [siac_r_bil_elem_class] per capitoli di gestione equivalente.';
      insert into bck_fase_bil_t_prev_approva_bil_elem_class
      (elem_bck_id,elem_bck_classif_id,
       elem_bck_data_creazione, elem_bck_data_modifica, elem_bck_login_operazione,
       elem_bck_validita_inizio, elem_bck_validita_fine,fase_bil_elab_id,
       ente_proprietario_id, login_operazione,validita_inizio)
      (select fase.elem_gest_id, elem.classif_id,
			  elem.data_creazione, elem.data_modifica, elem.login_operazione,
              elem.validita_inizio, elem.validita_fine,faseBilElabId,
              elem.ente_proprietario_id, loginOperazione,dataInizioVal
	   from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_class elem
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   elem.elem_id=fase.elem_gest_id
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   fase.elem_prev_id is not null
      );

      codResult:=null;
      strMessaggio:=strMessaggio||' Verifica inserimento.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_class bck
                        where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                        and   bck.elem_bck_id=fase.elem_gest_id
                        and   bck.data_cancellazione is null
                        and   bck.validita_fine is null);
      if codResult is not null then raise exception ' Elementi mancanti di backup.'; end if;

      strMessaggio:='Backup vecchia struttura [siac_r_bil_elem_categoria] per capitoli di gestione equivalente.';
      insert into bck_fase_bil_t_prev_approva_bil_elem_categ
      (elem_bck_id,elem_bck_cat_id,
       elem_bck_data_creazione, elem_bck_data_modifica, elem_bck_login_operazione,
       elem_bck_validita_inizio, elem_bck_validita_fine,fase_bil_elab_id,
       ente_proprietario_id, login_operazione,validita_inizio)
      (select fase.elem_gest_id, elem.elem_cat_id,
			  elem.data_creazione, elem.data_modifica, elem.login_operazione,
              elem.validita_inizio, elem.validita_fine,faseBilElabId,
              elem.ente_proprietario_id, loginOperazione,dataInizioVal
	   from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_categoria elem
      where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   elem.elem_id=fase.elem_gest_id
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   fase.elem_gest_id is not null
       and   fase.elem_prev_id is not null
      );

      codResult:=null;
      strMessaggio:=strMessaggio||' Verifica inserimento.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_gest_id is not null
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_categ bck
                        where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                        and   bck.elem_bck_id=fase.elem_gest_id
                        and   bck.data_cancellazione is null
                        and   bck.validita_fine is null);
      if codResult is not null then raise exception ' Elementi mancanti di backup.'; end if;

---------

     codResult:=null;
     strMessaggio:='Backup vecchie struttura per capitoli di gestione equivalente esistenti - FINE.';
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


	 codResult:=null;
     strMessaggio:='Inizio cancellazione logica vecchie strutture gestione esistenti.';
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- cancellazione logica precendenti relazioni
     -- siac_r_bil_elem_stato
/*     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_bil_elem_stato].';
     update siac_r_bil_elem_stato canc  set
      data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

     -- siac_r_bil_elem_categoria
     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_bil_elem_categoria].';
     update  siac_r_bil_elem_categoria canc set
          data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);
     -- siac_r_bil_elem_attr
     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_bil_elem_attr].';
     update siac_r_bil_elem_attr canc set
          data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

     -- siac_r_bil_elem_class
     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_bil_elem_class].';
     update siac_r_bil_elem_class canc set
              data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);*/
/* 31.07.2017 Sofia - gestione vincoli atti di legge commentata
     -- siac_r_vincolo_bil_elem
     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_vincolo_bil_elem].';
     update siac_r_vincolo_bil_elem canc set
              data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from  fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);
  04.03.2019 Sofia jira siac-6630 - tolto commento  **/
     /**  04.03.2019 Sofia jira siac-6630 - inizio   tolto commento **/

     -- siac_r_bil_elem_atto_legge
     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_bil_elem_atto_legge].';
     update siac_r_bil_elem_atto_legge canc set
              data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
     where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);
/*  04.03.2019 Sofia jira siac-6630 - tolto commento
31.07.2017 Sofia - chiusura
*/
	 -- siac_r_bil_elem_rel_tempo
     strMessaggio:='Cancellazione logica vecchie strutture gestione esistenti [siac_r_bil_elem_rel_tempo].';
	 update 	siac_r_bil_elem_rel_tempo canc set
		    data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
	 where canc.ente_proprietario_id=enteProprietarioId
     and   canc.data_cancellazione is null and canc.validita_fine is null
     and   exists (select 1 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
                   where fase.ente_proprietario_id=enteProprietarioId
                   and   fase.bil_id=bilancioId
                   and   fase.fase_bil_elab_id=faseBilElabId
                   and   fase.elem_gest_id=canc.elem_id
                   and   fase.elem_prev_id is not null
                   and   fase.data_cancellazione is null
                   order by fase.fase_bil_prev_str_esiste_id
                   limit 1);

	 codResult:=null;
     strMessaggio:='Fine cancellazione logica vecchie strutture gestione esistenti.';
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- cancellazione logica precendenti relazioni

     -- aggiornamento siac_t_bil_elem
     strMessaggio:='Aggiornamento nuova struttura gestione esistente da previsione equivalente [siac_t_bil_elem].';
     update siac_t_bil_elem gest set
     (elem_desc, elem_desc2, ordine, livello, login_operazione)=
     (prev.elem_desc,prev.elem_desc2,prev.ordine,prev.livello,loginOperazione)
     from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem prev
     where  gest.ente_proprietario_id=enteProprietarioId
     and    gest.elem_id=fase.elem_gest_id
     and    prev.elem_id=fase.elem_prev_id
     and    fase.ente_proprietario_id=enteProprietarioid
     and    fase.bil_id=bilancioId
     and    fase.fase_bil_elab_id=faseBilElabId
     and    fase.data_cancellazione is null
     and    fase.elem_prev_id is not null;

	 codResult:=null;
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     codResult:=null;
     strMessaggio:='Inizio inserimento nuove strutture gestione esistenti da previsione equivalente.';
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- inserimento nuove relazioni
     -- siac_r_bil_elem_stato
     /*strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_stato].';
     insert into siac_r_bil_elem_stato
     (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,login_operazione)
     (select fase.elem_gest_id, stato.elem_stato_id , dataInizioVal, stato.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_stato stato, fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where stato.elem_id=fase.elem_prev_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_prev_id is not null
      and   stato.data_cancellazione is null
      and   stato.validita_fine is null);*/

      strMessaggio:='Aggiornamento strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_stato].';
      update siac_r_bil_elem_stato statoCor
      set elem_stato_id=stato.elem_stato_id,
          data_modifica=dataInizioVal,
          login_operazione=loginOperazione
      from siac_r_bil_elem_stato stato, fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where stato.elem_id=fase.elem_prev_id
      and   statoCor.elem_id=fase.elem_gest_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_prev_id is not null
      and   stato.data_cancellazione is null
      and   stato.validita_fine is null
      and   statoCor.data_cancellazione is null
      and   statoCor.validita_fine is null;

     -- siac_r_bil_elem_attr ( escludere FLAG_PER_MEM )
     -- devo cancellare e reinserire
     strMessaggio:='Cancellazione strutture gestione esistenti per reinserimento da previsione equivalente [siac_r_bil_elem_attr].';
     delete from siac_r_bil_elem_attr attr
     using  fase_bil_t_prev_approva_str_elem_gest_esiste fase
     where attr.elem_id=fase.elem_gest_id
     and   fase.ente_proprietario_id=enteProprietarioid
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.data_cancellazione is null
     and   fase.elem_prev_id is not null
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;

     strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_attr].';
     insert into siac_r_bil_elem_attr
     (elem_id,attr_id,tabella_id,boolean,percentuale,
      testo,numerico,validita_inizio,
      ente_proprietario_id,login_operazione)
     (select fase.elem_gest_id, attr.attr_id , attr.tabella_id,attr.boolean,attr.percentuale,
            attr.testo,attr.numerico,
            dataInizioVal, attr.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_attr attr, fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where attr.elem_id=fase.elem_prev_id
      and   attr.attr_id!=flagPerMemAttrId
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_prev_id is not null
      and   attr.data_cancellazione is null
      and   attr.validita_fine is null);

     -- siac_r_bil_elem_categoria
/*     strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_categoria].';
     insert into siac_r_bil_elem_categoria
     (elem_id,elem_cat_id,validita_inizio,ente_proprietario_id,login_operazione)
     (select fase.elem_gest_id, cat.elem_cat_id , dataInizioVal, cat.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_categoria cat, fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where cat.elem_id=fase.elem_prev_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_prev_id is not null
      and   cat.data_cancellazione is null
      and   cat.validita_fine is null);*/

      strMessaggio:='Aggiornamento strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_categoria].';
      update siac_r_bil_elem_categoria catCor
      set elem_cat_id=cat.elem_cat_id,
          data_modifica=dataInizioVal,
          login_operazione=loginOperazione
      from siac_r_bil_elem_categoria cat, fase_bil_t_prev_approva_str_elem_gest_esiste fase
      where cat.elem_id=fase.elem_prev_id
      and   catCor.elem_id=fase.elem_gest_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.elem_prev_id is not null
      and   cat.data_cancellazione is null
      and   cat.validita_fine is null
      and   catCor.data_cancellazione is null
      and   catCor.validita_fine is null;


     -- siac_r_bil_elem_class
     -- cancellare e reinserire
     strMessaggio:='Cancellazione strutture gestione esistenti [siac_r_bil_elem_class].';
     delete from siac_r_bil_elem_class class
     using fase_bil_t_prev_approva_str_elem_gest_esiste fase
     where class.elem_id=fase.elem_gest_id
     and   fase.ente_proprietario_id=enteProprietarioid
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.data_cancellazione is null
     and   fase.elem_prev_id is not null
     and   class.data_cancellazione is null
     and   class.validita_fine is null;

     strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].';
	 insert into siac_r_bil_elem_class
     (elem_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
     (select fase.elem_gest_id, class.classif_id , dataInizioVal, class.ente_proprietario_id, loginOperazione
      from siac_r_bil_elem_class class, fase_bil_t_prev_approva_str_elem_gest_esiste fase,siac_t_class c
      where class.elem_id=fase.elem_prev_id
      and   fase.ente_proprietario_id=enteProprietarioid
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      -- JIRA-SIAC-4167 14.11.2016 Anto
      and   c.classif_id=class.classif_id
      and   c.data_cancellazione is null
      and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
      and   fase.data_cancellazione is null
      and   fase.elem_prev_id is not null
      and   class.data_cancellazione is null
      and   class.validita_fine is null);

/* 31.07.2017 Sofia - gestione vincoli atti di legge commentata

      -- siac_r_vincolo_bil_elem
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_vincolo_bil_elem].';
 	  insert into siac_r_vincolo_bil_elem
      ( elem_id,vincolo_id, validita_inizio,ente_proprietario_id,login_operazione)
      (select fase.elem_gest_id, v.vincolo_id, dataInizioVal,v.ente_proprietario_id, loginOperazione
       from siac_r_vincolo_bil_elem v,fase_bil_t_prev_approva_str_elem_gest_esiste fase
       where v.elem_id=fase.elem_prev_id
	   and   fase.ente_proprietario_id=enteProprietarioid
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
	   and   fase.data_cancellazione is null
       and   fase.elem_prev_id is not null
       and   v.data_cancellazione is null
       and   v.validita_fine is null
       );
 04.03.2019 Sofia jira siac-6630 - tolto commento  */

       /**  04.03.2019 Sofia jira siac-6630 - inizio  - tolto commento **/
       -- siac_r_bil_elem_atto_legge
       strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_atto_legge].';
       insert into siac_r_bil_elem_atto_legge
       ( elem_id,attolegge_id, descrizione, gerarchia,finanziamento_inizio,finanziamento_fine,
         validita_inizio,ente_proprietario_id,login_operazione
       )
       ( select fase.elem_gest_id,v.attolegge_id,v.descrizione, v.gerarchia,v.finanziamento_inizio,v.finanziamento_fine,
               dataInizioVal,v.ente_proprietario_id, loginOperazione
         from   siac_r_bil_elem_atto_legge v,fase_bil_t_prev_approva_str_elem_gest_esiste fase
         where v.elem_id=fase.elem_prev_id
	     and   fase.ente_proprietario_id=enteProprietarioid
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
  	     and   fase.data_cancellazione is null
         and   fase.elem_prev_id is not null
         and   v.data_cancellazione is null
         and   v.validita_fine is null
       );

/*31.07.2017 Sofia - chiusura -  04.03.2019 Sofia jira siac-6630 - inizio  tolto commento
*/
       -- siac_r_bil_elem_rel_tempo
       strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_rel_tempo].';
       insert into siac_r_bil_elem_rel_tempo
       (elem_id, elem_id_old, validita_inizio, ente_proprietario_id,login_operazione)
       ( select fase.elem_gest_id,v.elem_id_old,
               dataInizioVal,v.ente_proprietario_id, loginOperazione
         from   siac_r_bil_elem_rel_tempo v,fase_bil_t_prev_approva_str_elem_gest_esiste fase
         where v.elem_id=fase.elem_prev_id
	     and   fase.ente_proprietario_id=enteProprietarioid
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
  	     and   fase.data_cancellazione is null
         and   fase.elem_prev_id is not null
         and   v.data_cancellazione is null
         and   v.validita_fine is null
       );

       codResult:=null;
       strMessaggio:='Fine inserimento nuove strutture gestione esistenti da previsione equivalente.';
       insert into fase_bil_t_elaborazione_log
       (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
       )
       values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

       if codResult is null then
      	raise exception ' Errore in inserimento LOG.';
       end if;

       -- verifica dati inseriti
       codResult:=null;
       strMessaggio:='Inizio verifica inserimento nuove strutture gestione esistenti da previsione equivalente.';
       insert into fase_bil_t_elaborazione_log
       (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
       )
       values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
        returning fase_bil_elab_log_id into codResult;

       if codResult is null then
      	raise exception ' Errore in inserimento LOG.';
       end if;

       codResult:=null;
       strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_stato].Verifica esistenza relazione stati.';
       select 1 into codResult
       from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
       where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.elem_prev_id is not null
       and   fase.data_cancellazione is null
       and   not exists (select 1 from siac_r_bil_elem_stato stato
                 		 where stato.elem_id=fase.elem_gest_id--elem.elem_id
                         and   stato.data_cancellazione is null
                         and   stato.validita_fine is null
                         order by stato.elem_id
                         limit 1)
       order by fase.fase_bil_prev_str_esiste_id
       limit 1;

       if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
       end if;

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_attr].Verifica esistenza attributi.';
      select 1 into codResult
      from  fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   not exists (select 1 from siac_r_bil_elem_attr attr
     		 		    where attr.elem_id=fase.elem_gest_id--elem.elem_id
					    and   attr.attr_id!=flagPerMemAttrId
                        and   attr.data_cancellazione is null
                        and   attr.validita_fine is null
                        order by attr.elem_id
                        limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;

      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni classificatori.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   not exists ( select 1 from siac_r_bil_elem_class class,siac_t_class c
      				     where class.elem_id=fase.elem_gest_id--elem.elem_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null

                               -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   c.classif_id=class.classif_id
                          and   c.data_cancellazione is null
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)

                         order by class.elem_id
                         limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

      codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_categoria].Verifica esistenza relazioni categoria.';
      select distinct 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   not exists ( select 1 from siac_r_bil_elem_categoria class
                         where class.elem_id=fase.elem_gest_id--elem.elem_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null);


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;

	  -- verifica se esistono elementi senza classificatori obbligatori (**)
      -- controlli sui classificatori obbligatori
      -- CL_CDC, CL_CDR
      codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni struttura amministrativa.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   fase.elem_prev_id is not null
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                       where class.elem_id=fase.elem_gest_id--elem.elem_id
                       and   c.classif_id=class.classif_id
                       and   c.classif_tipo_id in (cdcTipoId, cdrTipoId)
                       and   class.data_cancellazione is null
                       and   class.validita_fine is null
                       and   c.data_cancellazione is null
                       and   c.validita_fine is null
                       order by class.elem_id
                       limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;
		/*
      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;
		*/

        if codResult is not null then
           strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
           insert into fase_bil_t_prev_apertura_segnala
           (elem_id,
	        elem_code,
			elem_code2,
			elem_code3,
		    bil_id,
		    fase_bil_elab_id,
		    segnala_codice,
			segnala_desc,
			validita_inizio,
			ente_proprietario_id,
		    login_operazione)
           (select fase.elem_gest_id,
                   fase.elem_code,
                   fase.elem_code2,
                   fase.elem_code3,
                   fase.bil_id,
                   faseBilElabId,
                   'SAC',
                   'Sac mancante',
                   dataInizioVal,
                   fase.ente_proprietario_id,
                   loginOperazione
             from fase_bil_t_prev_approva_str_elem_gest_esiste fase
             where fase.ente_proprietario_id=enteProprietarioId
             and   fase.elem_prev_id is not null
             and   fase.bil_id=bilancioId
             and   fase.fase_bil_elab_id=faseBilElabId
             and   fase.data_cancellazione is null
             and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                                where class.elem_id=fase.elem_gest_id
                                and   c.classif_id=class.classif_id
                                and   c.classif_tipo_id in (cdcTipoId, cdrTipoId)
                                and   class.data_cancellazione is null
                                and   class.validita_fine is null
                                and   c.data_cancellazione is null
                                and   c.validita_fine is null
                                order by class.elem_id
                                limit 1)
            );
          end if;



      -- CL_PDC_FIN_QUINTO, CL_PDC_FIN_QUARTO
      codResult:=null;
	  strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_PDC_FIN_QUARTO||' '||CL_PDC_FIN_QUINTO||'.';

      --02.03.2016 Dani Il classificatore deve essere obbligatoriamente presente solo se capitolo gestione STD
	  select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase
      , siac_r_bil_elem_categoria rcat
	  , siac_d_bil_elem_categoria cat
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   rcat.elem_id=fase.elem_gest_id
      and   rcat.data_cancellazione is null
      and   rcat.validita_fine is null
      and   rcat.elem_cat_id=cat.elem_cat_id
      and   cat.elem_cat_code = CATEGORIA_STD
/*      and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                     where class.elem_id=fase.elem_prev_id
                     and   c.classif_id=class.classif_id
                     and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
                     and   class.data_cancellazione is null
                     and   class.validita_fine is null
                     and   c.data_cancellazione is null
                     and   c.validita_fine is null
                     order by class.elem_id
                     limit 1)*/
      and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                       where class.elem_id=fase.elem_gest_id
                       and   c.classif_id=class.classif_id
                       and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
                       and   class.data_cancellazione is null
                       and   class.validita_fine is null
                       and   c.data_cancellazione is null
                       and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)

                       order by class.elem_id
                       limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;

      /*
      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;
		*/
     --  JIRA-SIAC-4167  if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
      if codResult is not null then
          	strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
            insert into fase_bil_t_prev_apertura_segnala
             (elem_id,
	         elem_code,
		 	 elem_code2,
			 elem_code3,
		     bil_id,
		     fase_bil_elab_id,
		     segnala_codice,
			 segnala_desc,
			 validita_inizio,
			 ente_proprietario_id,
		     login_operazione)
            (select fase.elem_gest_id,
                    fase.elem_code,
                    fase.elem_code2,
                    fase.elem_code3,
                    fase.bil_id,
                    faseBilElabId,
                    'PDCFIN',
                    'PdcFin mancante',
                    dataInizioVal,
                    fase.ente_proprietario_id,
                    loginOperazione
              from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
                   siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
              where fase.ente_proprietario_id=enteProprietarioId
              and   fase.bil_id=bilancioId
              and   fase.fase_bil_elab_id=faseBilElabId
              and   fase.elem_prev_id is not null
              and   fase.data_cancellazione is null
              and   rcat.elem_id=fase.elem_gest_id
              and   rcat.data_cancellazione is null
              and   rcat.validita_fine is null
              and   rcat.elem_cat_id=cat.elem_cat_id
              and   cat.elem_cat_code = CATEGORIA_STD
              and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
                                 where class.elem_id=fase.elem_gest_id
                                 and   c.classif_id=class.classif_id
                                 and   c.classif_tipo_id in (pdcFinIVId, pdcFinVId)
                                 and   class.data_cancellazione is null
                                 and   class.validita_fine is null
                                 and   c.data_cancellazione is null
                                 and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                                 and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                                 and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
             );
      end if;

/* 31.07.2017 Sofia gestione vincoli  atti legge commentata
	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_vincolo_bil_elem].Verifica esistenza relazioni vincoli.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase, -- siac_t_bil_elem elem,
           siac_r_vincolo_bil_elem v
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   v.elem_id=fase.elem_prev_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   v.data_cancellazione is null
      and   v.validita_fine is null
      and   not exists ( select 1 from siac_r_vincolo_bil_elem class
                         where class.elem_id=fase.elem_gest_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1
                       )
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;
 04.03.2019 Sofia jira siac-6630 - tolto commento */
      /**  04.03.2019 Sofia jira siac-6630 - inizio  - tolto commento **/
	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_atto_legge].Verifica esistenza relazioni atti di legge.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase, --siac_t_bil_elem elem,
           siac_r_bil_elem_atto_legge v
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   v.elem_id=fase.elem_prev_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   v.data_cancellazione is null
      and   v.validita_fine is null
      and   not exists ( select 1 from siac_r_bil_elem_atto_legge class
                         where class.elem_id=fase.elem_gest_id--elem.elem_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;
/*  04.03.2019 Sofia jira siac-6630 - tolto commento
31.07.2017 Sofia - chiusura
*/

	  codResult:=null;
      strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_rel_tempo].Verifica esistenza relazioni.';
      select 1 into codResult
      from fase_bil_t_prev_approva_str_elem_gest_esiste fase, --siac_t_bil_elem elem,
           siac_r_bil_elem_rel_tempo v
      where fase.ente_proprietario_id=enteProprietarioId
--    and   fase.elem_gest_id=elem.elem_id
      and   v.elem_id=fase.elem_prev_id
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_prev_id is not null
      and   fase.data_cancellazione is null
      and   v.data_cancellazione is null
      and   v.validita_fine is null
      and   not exists ( select 1 from siac_r_bil_elem_rel_tempo class
                         where class.elem_id=fase.elem_gest_id--elem.elem_id
                         and   class.data_cancellazione is null
                         and   class.validita_fine is null
                         order by class.elem_id
                         limit 1)
	  order by fase.fase_bil_prev_str_esiste_id
      limit 1;


      if codResult is not null then
    	raise exception ' Elementi di bilancio assenti di relazione.';
      end if;


	  if euElemTipo=TIPO_ELEM_EU then

		-- 02.03.2016 Dani Classificatore necessario solo per capitolo di categoria STD

		-- CL_PROGRAMMA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_PROGRAMMA||'.';
        select 1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    	where fase.ente_proprietario_id=enteProprietarioId
---	    and   fase.elem_gest_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        and   rcat.elem_id=fase.elem_gest_id
        and   rcat.data_cancellazione is null
        and   rcat.validita_fine is null
        and   rcat.elem_cat_id=cat.elem_cat_id
        and   cat.elem_cat_code = CATEGORIA_STD
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=programmaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           --order by class.elem_id
                           limit 1)
		--order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
		/*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
		*/

        if codResult is not null then

         strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
         insert into fase_bil_t_prev_apertura_segnala
		 (elem_id,
		  elem_code,
		  elem_code2,
		  elem_code3,
		  bil_id,
		  fase_bil_elab_id,
		  segnala_codice,
		  segnala_desc,
		  validita_inizio,
		  ente_proprietario_id,
	  	  login_operazione)
	      (select fase.elem_gest_id,
                  fase.elem_code,
                  fase.elem_code2,
                  fase.elem_code3,
                  fase.bil_id,
                  faseBilElabId,
                  CL_PROGRAMMA,
                  CL_PROGRAMMA||' mancante',
 	              dataInizioVal,
             	  fase.ente_proprietario_id,
	              loginOperazione
           from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    	   where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.elem_prev_id is not null
	       and   fase.data_cancellazione is null
           and   rcat.elem_id=fase.elem_gest_id
           and   rcat.data_cancellazione is null
           and   rcat.validita_fine is null
           and   rcat.elem_cat_id=cat.elem_cat_id
           and   cat.elem_cat_code = CATEGORIA_STD
    	   and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
          	                  where class.elem_id=fase.elem_gest_id
            	              and   c.classif_id=class.classif_id
                	          and   c.classif_tipo_id=programmaTipoId
                    	      and   class.data_cancellazione is null
	                          and   class.validita_fine is null
    	                      and   c.data_cancellazione is null
        	                  and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                              and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           --order by class.elem_id
                           limit 1)
	        );
        end if;


		-- 02.03.2016 Dani Classificatore necessario solo per capitolo di categoria STD
        -- CL_MACROAGGREGATO
        codResult:=null;
	    strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_MACROAGGREGATO||'.';
        select 1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
        , siac_r_bil_elem_categoria rcat
        , siac_d_bil_elem_categoria cat
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        and   rcat.elem_id=fase.elem_gest_id
        and   rcat.data_cancellazione is null
        and   rcat.validita_fine is null
        and   rcat.elem_cat_id=cat.elem_cat_id
        and   cat.elem_cat_code = CATEGORIA_STD
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=macroAggrTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)

                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
		*/
       if codResult is not null then

      	strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
        insert into fase_bil_t_prev_apertura_segnala
		(elem_id,
	     elem_code,
	     elem_code2,
	     elem_code3,
	     bil_id,
	     fase_bil_elab_id,
	     segnala_codice,
	     segnala_desc,
	     validita_inizio,
	     ente_proprietario_id,
	     login_operazione)
	    (select fase.elem_gest_id,
                fase.elem_code,
                fase.elem_code2,
                fase.elem_code3,
                fase.bil_id,
                faseBilElabId,
                CL_MACROAGGREGATO,
                CL_MACROAGGREGATO||' mancante',
                dataInizioVal,
  	            fase.ente_proprietario_id,
	            loginOperazione
	      from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
               siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.elem_prev_id is not null
	      and   fase.data_cancellazione is null
          and   rcat.elem_id=fase.elem_gest_id
          and   rcat.data_cancellazione is null
          and   rcat.validita_fine is null
          and   rcat.elem_cat_id=cat.elem_cat_id
          and   cat.elem_cat_code = CATEGORIA_STD
    	  and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	                 where class.elem_id=fase.elem_gest_id
            	             and   c.classif_id=class.classif_id
                             and   c.classif_tipo_id=macroAggrTipoId
                    	     and   class.data_cancellazione is null
	                         and   class.validita_fine is null
    	                     and   c.data_cancellazione is null
        	                 and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                             and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                             and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                             order by class.elem_id
                             limit 1)
         );
      end if;


  	    -- CL_COFOG
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_COFOG||'.';
        select 1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
--	    and   fase.elem_gest_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        -- 02.03.2016 Dani se classificatore definito in previsione deve essere stato ribaltato su gestione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=cofogTipoId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=cofogTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
/*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
*/

		if codResult is not null then
           strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
       	   insert into fase_bil_t_prev_apertura_segnala
           (elem_id,
            elem_code,
	 	    elem_code2,
	        elem_code3,
		    bil_id,
		    fase_bil_elab_id,
		    segnala_codice,
		    segnala_desc,
		    validita_inizio,
		    ente_proprietario_id,
	  	    login_operazione)
	       (select fase.elem_gest_id,
                   fase.elem_code,
                   fase.elem_code2,
                   fase.elem_code3,
	               fase.bil_id,
     	           faseBilElabId,
	               CL_COFOG,
     	           CL_COFOG||' mancante',
                   dataInizioVal,
                   fase.ente_proprietario_id,
	               loginOperazione
	        from fase_bil_t_prev_approva_str_elem_gest_esiste fase
    	    where fase.ente_proprietario_id=enteProprietarioId
            and   fase.bil_id=bilancioId
            and   fase.fase_bil_elab_id=faseBilElabId
    	    and   fase.elem_prev_id is not null
	        and   fase.data_cancellazione is null
            and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
           	               where class.elem_id=fase.elem_prev_id
                           and   c.classif_id=class.classif_id
               	           and    c.classif_tipo_id=cofogTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                           and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                           and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
      	   and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
         	                  where class.elem_id=fase.elem_gest_id
            	              and   c.classif_id=class.classif_id
                	          and   c.classif_tipo_id=cofogTipoId
                    	      and   class.data_cancellazione is null
	                          and   class.validita_fine is null
    	                      and   c.data_cancellazione is null
        	                  and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                              and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
                           limit 1)
           );
        end if;

 	    -- CL_RICORRENTE_SPESA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_RICORRENTE_SPESA||'.';
        select  1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
--	    and   fase.elem_gest_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        -- 02.03.2016 Dani se classificatore definito in previsione deve essere stato ribaltato su gestione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=ricorrenteSpesaId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=ricorrenteSpesaId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
/*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
*/

          if codResult is not null then
              strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
       	      insert into fase_bil_t_prev_apertura_segnala
		      (elem_id,
			   elem_code,
			   elem_code2,
			   elem_code3,
			   bil_id,
			   fase_bil_elab_id,
			   segnala_codice,
		 	   segnala_desc,
			   validita_inizio,
			   ente_proprietario_id,
	  		   login_operazione)
	          (select fase.elem_gest_id,
                      fase.elem_code,
                      fase.elem_code2,
                      fase.elem_code3,
                      fase.bil_id,
 	                  faseBilElabId,
	                  CL_RICORRENTE_SPESA,
     	              CL_RICORRENTE_SPESA||' mancante',
         	          dataInizioVal,
             	      fase.ente_proprietario_id,
	                  loginOperazione
               from fase_bil_t_prev_approva_str_elem_gest_esiste fase
       	       where fase.ente_proprietario_id=enteProprietarioId
               and   fase.bil_id=bilancioId
               and   fase.fase_bil_elab_id=faseBilElabId
       	       and   fase.elem_prev_id is not null
	           and   fase.data_cancellazione is null
               and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	                  where class.elem_id=fase.elem_prev_id
                              and   c.classif_id=class.classif_id
                   	          and   c.classif_tipo_id=ricorrenteSpesaId
                  	          and   class.data_cancellazione is null
	                          and   class.validita_fine is null
    	                      and   c.data_cancellazione is null
        	                  and   c.validita_fine is null
                              -- JIRA-SIAC-4167 14.11.2016 Anto
                              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                              and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                              order by class.elem_id
                              limit 1)
    	      and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	                     where class.elem_id=fase.elem_gest_id--elem.elem_id
            	                 and   c.classif_id=class.classif_id
                	             and   c.classif_tipo_id=ricorrenteSpesaId
                    	         and   class.data_cancellazione is null
	                             and   class.validita_fine is null
    	                         and   c.data_cancellazione is null
        	                     and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                                 and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                                 and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                                 order by class.elem_id
                                 limit 1)
              );
        end if;


        -- CL_SIOPE_SPESA_TERZO
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_SIOPE_SPESA_TERZO||'.';
        select  1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
--	    and   fase.elem_prev_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        and exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	         where class.elem_id=fase.elem_prev_id--elem.elem_id
                     and   c.classif_id=class.classif_id
                     and   c.classif_tipo_id=siopeSpesaTipoId
                     and   class.data_cancellazione is null
	                 and   class.validita_fine is null
    	             and   c.data_cancellazione is null
        	         and   c.validita_fine is null
                          -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                     order by class.elem_id
                     limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=siopeSpesaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
		*/
        if codResult is not null then
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select fase.elem_gest_idd,
                           fase.elem_code,
                           fase.elem_code2,
                           fase.elem_code3,
	                       fase.bil_id,
     	                   faseBilElabId,
	                       CL_SIOPE_SPESA_TERZO,
     	                   CL_SIOPE_SPESA_TERZO||' mancante',
         	               dataInizioVal,
             	           fase.ente_proprietario_id,
	                       loginOperazione
	                from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    				where fase.ente_proprietario_id=enteProprietarioId
			        and   fase.bil_id=bilancioId
			        and   fase.fase_bil_elab_id=faseBilElabId
				   	and   fase.elem_prev_id is not null
				    and   fase.data_cancellazione is null
			        and exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				         where class.elem_id=fase.elem_prev_id--elem.elem_id
			                     and   c.classif_id=class.classif_id
				                 and   c.classif_tipo_id=siopeSpesaTipoId
			                     and   class.data_cancellazione is null
				                 and   class.validita_fine is null
			    	             and   c.data_cancellazione is null
			        	         and   c.validita_fine is null
            		              -- JIRA-SIAC-4167 14.11.2016 Anto
		                         and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
        		                 and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                			     order by class.elem_id
			                     limit 1)
			    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				               where class.elem_id=fase.elem_gest_id
            	        			   and   c.classif_id=class.classif_id
			                	       and   c.classif_tipo_id=siopeSpesaTipoId
			                    	   and   class.data_cancellazione is null
				                       and   class.validita_fine is null
			    	                   and   c.data_cancellazione is null
			        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
            				           and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
				                       and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
			                           order by class.elem_id
            				          limit 1)
                   );

              end if;

 	    -- CL_TRANSAZIONE_UE_SPESA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_TRANSAZIONE_UE_SPESA||'.';
        select  1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
--	    and   fase.elem_gest_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        -- 02.03.2016 Dani se classificatore definito in previsione deve essere stato ribaltato su gestione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=transazioneUeSpesaId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=transazioneUeSpesaId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
        */
        if codResult is not null then
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select fase.elem_gest_id,
                           fase.elem_code,
                           fase.elem_code2,
                           fase.elem_code3,
	                       fase.bil_id,
     	                   faseBilElabId,
	                       CL_TRANSAZIONE_UE_SPESA,
     	                   CL_TRANSAZIONE_UE_SPESA||' mancante',
         	               dataInizioVal,
             	           fase.ente_proprietario_id,
	                       loginOperazione
	                from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    				where fase.ente_proprietario_id=enteProprietarioId
			        and   fase.bil_id=bilancioId
			        and   fase.fase_bil_elab_id=faseBilElabId
			    	and   fase.elem_prev_id is not null
				    and   fase.data_cancellazione is null
			        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				           where class.elem_id=fase.elem_prev_id
			                       and   c.classif_id=class.classif_id
            			   	       and   c.classif_tipo_id=transazioneUeSpesaId
			                  	   and   class.data_cancellazione is null
	        			           and   class.validita_fine is null
			    	               and   c.data_cancellazione is null
			        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
            		               and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
		                           and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
			                       order by class.elem_id
			                       limit 1)
			    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	        			   and   c.classif_id=class.classif_id
			                	       and   c.classif_tipo_id=transazioneUeSpesaId
            			        	   and   class.data_cancellazione is null
	                    			   and   class.validita_fine is null
			    	                   and   c.data_cancellazione is null
        				               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                        			  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
			                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
            			              order by class.elem_id
                        			   limit 1)
                   );
              end if;





     else
        -- CL_CATEGORIA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_CATEGORIA||'.';

        --02.03.2016 Dani Il classificatore deve essere obbligatoriamente presente solo se capitolo STD
        select distinct 1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        and   rcat.elem_id=fase.elem_gest_id
        and   rcat.data_cancellazione is null
        and   rcat.validita_fine is null
        and   rcat.elem_cat_id=cat.elem_cat_id
        and   cat.elem_cat_code = CATEGORIA_STD
/*        and   exists (    select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_prev_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=categoriaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
--                           order by class.elem_id
                           limit 1)*/
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=categoriaTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
--                           order by class.elem_id
                           limit 1)
--		order by fase.fase_bil_prev_str_esiste_id
--	    limit 1
        ;

        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
		*/
       -- JIRA-SIAC-4167 14.11.2016 Sofia
       -- if codResult is null then raise exception ' Nessuno inserimento effettuato.'; end if;
       if codResult is not null then
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select fase.elem_gest_id,
                           fase.elem_code,
                           fase.elem_code2,
                           fase.elem_code3,
	                       fase.bil_id,
     	                   faseBilElabId,
	                       CL_CATEGORIA,
     	                   CL_CATEGORIA||' mancante',
         	               dataInizioVal,
             	           fase.ente_proprietario_id,
	                       loginOperazione
	                from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_r_bil_elem_categoria rcat, siac_d_bil_elem_categoria cat
    				where fase.ente_proprietario_id=enteProprietarioId
			        and   fase.bil_id=bilancioId
			        and   fase.fase_bil_elab_id=faseBilElabId
			    	and   fase.elem_prev_id is not null
				    and   fase.data_cancellazione is null
			        and   rcat.elem_id=fase.elem_gest_id
			        and   rcat.data_cancellazione is null
			        and   rcat.validita_fine is null
			        and   rcat.elem_cat_id=cat.elem_cat_id
			        and   cat.elem_cat_code = CATEGORIA_STD
			    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				               where class.elem_id=fase.elem_gest_id
			            	           and   c.classif_id=class.classif_id
				               	       and   c.classif_tipo_id=categoriaTipoId
			                    	   and   class.data_cancellazione is null
				                       and   class.validita_fine is null
			    	                   and   c.data_cancellazione is null
				       	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
			                           and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
            			               and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
   									 )
                   );

        end if;

     	-- CL_RICORRENTE_ENTRATA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_RICORRENTE_ENTRATA||'.';
        select  1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
--	    and   fase.elem_gest_id=elem.elem_id --Dani 19.02.2016
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        -- 02.03.2016 Dani se classificatore definito in previsione deve essere stato ribaltato su gestione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=ricorrenteEntrataId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=ricorrenteEntrataId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
                           limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
		*/
        if codResult is not null then
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select fase.elem_gest_id,
                           fase.elem_code,
                           fase.elem_code2,
                           fase.elem_code3,
	                       fase.bil_id,
     	                   faseBilElabId,
	                       CL_RICORRENTE_ENTRATA,
     	                   CL_RICORRENTE_ENTRATA||' mancante',
         	               dataInizioVal,
             	           fase.ente_proprietario_id,
	                       loginOperazione
	                from fase_bil_t_prev_approva_str_elem_gest_esiste fase
			    	where fase.ente_proprietario_id=enteProprietarioId
				    and   fase.bil_id=bilancioId
			        and   fase.fase_bil_elab_id=faseBilElabId
			    	and   fase.elem_prev_id is not null
				    and   fase.data_cancellazione is null
			        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				           where class.elem_id=fase.elem_prev_id
			                       and   c.classif_id=class.classif_id
			               	       and   c.classif_tipo_id=ricorrenteEntrataId
			                  	   and   class.data_cancellazione is null
				                   and   class.validita_fine is null
			    	               and   c.data_cancellazione is null
			        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
            		              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
		                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
        			               order by class.elem_id
                    			   limit 1)
				  	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	    			           where class.elem_id=fase.elem_gest_id
            	    				   and   c.classif_id=class.classif_id
			                	       and   c.classif_tipo_id=ricorrenteEntrataId
            			        	   and   class.data_cancellazione is null
	                    			   and   class.validita_fine is null
			    	                   and   c.data_cancellazione is null
        				               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                        			   and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
			                           and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
              				           order by class.elem_id
                           			limit 1)
                   );

          end if;



	    -- CL_SIOPE_ENTRATA_TERZO
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_SIOPE_ENTRATA_TERZO||'.';
        select  1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
--	    and   fase.elem_prev_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=siopeEntrataTipoId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=siopeEntrataTipoId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
	                       limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;
        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
		*/
        if codResult is not null then
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select fase.elem_gest_id,
                           fase.elem_code,
                           fase.elem_code2,
                           fase.elem_code3,
	                       fase.bil_id,
     	                   faseBilElabId,
	                       CL_SIOPE_ENTRATA_TERZO,
     	                   CL_SIOPE_ENTRATA_TERZO||' mancante',
         	               dataInizioVal,
             	           fase.ente_proprietario_id,
	                       loginOperazione
	                from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    				where fase.ente_proprietario_id=enteProprietarioId
			        and   fase.bil_id=bilancioId
			        and   fase.fase_bil_elab_id=faseBilElabId
			    	and   fase.elem_prev_id is not null
				    and   fase.data_cancellazione is null
			        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				           where class.elem_id=fase.elem_prev_id
			                       and   c.classif_id=class.classif_id
			               	       and   c.classif_tipo_id=siopeEntrataTipoId
			                  	   and   class.data_cancellazione is null
				                   and   class.validita_fine is null
			    	               and   c.data_cancellazione is null
			        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
            		              and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                    		      and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
			                       order by class.elem_id
            			           limit 1)
			    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
			        	               where class.elem_id=fase.elem_gest_id
            				           and   c.classif_id=class.classif_id
			                	       and   c.classif_tipo_id=siopeEntrataTipoId
            			        	   and   class.data_cancellazione is null
				                       and   class.validita_fine is null
			    	                   and   c.data_cancellazione is null
        				               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
				                       and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
 	              				       and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
			                           order by class.elem_id
	        			               limit 1)
                   );
              end if;

	    -- CL_TRANSAZIONE_UE_ENTRATA
        codResult:=null;
        strMessaggio:='Inserimento nuove strutture gestione esistenti da previsione equivalente [siac_r_bil_elem_class].Verifica esistenza relazioni '||CL_TRANSAZIONE_UE_ENTRATA||'.';
        select 1 into codResult
	    from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    	where fase.ente_proprietario_id=enteProprietarioId
--	    and   fase.elem_gest_id=elem.elem_id
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_prev_id is not null
	    and   fase.data_cancellazione is null
        -- 02.03.2016 Dani se classificatore definito in previsione deve essere stato ribaltato su gestione
        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	           where class.elem_id=fase.elem_prev_id
                       and   c.classif_id=class.classif_id
               	       and   c.classif_tipo_id=transazioneUeEntrataId
                  	   and   class.data_cancellazione is null
	                   and   class.validita_fine is null
    	               and   c.data_cancellazione is null
        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                       order by class.elem_id
                       limit 1)
    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        	               where class.elem_id=fase.elem_gest_id--elem.elem_id
            	           and   c.classif_id=class.classif_id
                	       and   c.classif_tipo_id=transazioneUeEntrataId
                    	   and   class.data_cancellazione is null
	                       and   class.validita_fine is null
    	                   and   c.data_cancellazione is null
        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
                          and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
                          and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                           order by class.elem_id
	                       limit 1)
		order by fase.fase_bil_prev_str_esiste_id
	    limit 1;

        if codResult is not null then
	               strMessaggio:=strMessaggio||' Inserimento segnalazione mancanza classif.';
              	   insert into fase_bil_t_prev_apertura_segnala
		           (elem_id,
			        elem_code,
			 	    elem_code2,
				    elem_code3,
				    bil_id,
				    fase_bil_elab_id,
			        segnala_codice,
		 		    segnala_desc,
				    validita_inizio,
				    ente_proprietario_id,
	  		        login_operazione)
	               (select fase.elem_gest_id,
                           fase.elem_code,
                           fase.elem_code2,
                           fase.elem_code3,
	                       fase.bil_id,
     	                   faseBilElabId,
	                       CL_TRANSAZIONE_UE_ENTRATA,
     	                   CL_TRANSAZIONE_UE_ENTRATA||' mancante',
         	               dataInizioVal,
             	           fase.ente_proprietario_id,
	                       loginOperazione
	                from fase_bil_t_prev_approva_str_elem_gest_esiste fase--, siac_t_bil_elem elem
    				where fase.ente_proprietario_id=enteProprietarioId
			        and   fase.bil_id=bilancioId
			        and   fase.fase_bil_elab_id=faseBilElabId
			        and   fase.elem_prev_id is not null
				    and   fase.data_cancellazione is null
			        and   exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				           where class.elem_id=fase.elem_prev_id
			                       and   c.classif_id=class.classif_id
			               	       and   c.classif_tipo_id=transazioneUeEntrataId
			                  	   and   class.data_cancellazione is null
				                   and   class.validita_fine is null
			    	               and   c.data_cancellazione is null
			        	           and   c.validita_fine is null
                            -- JIRA-SIAC-4167 14.11.2016 Anto
			                       and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
			                       and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
			                       order by class.elem_id
			                       limit 1)
			    	and   not exists ( select 1 from siac_r_bil_elem_class class , siac_t_class c
        				               where class.elem_id=fase.elem_gest_id
			            	           and   c.classif_id=class.classif_id
			                	       and   c.classif_tipo_id=transazioneUeEntrataId
			                    	   and   class.data_cancellazione is null
				                       and   class.validita_fine is null
			    	                   and   c.data_cancellazione is null
			        	               and   c.validita_fine is null
                                -- JIRA-SIAC-4167 14.11.2016 Anto
            				           and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
				                       and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
                			           order by class.elem_id
				                       limit 1)
                   );
         end if;

        /*
	    if codResult is not null then
    		raise exception ' Elementi di bilancio assenti di relazione.';
	    end if;
        */
     end if;

     codResult:=null;
     strMessaggio:='Fine verifica inserimento nuove strutture gestione esistenti da previsione equivalente.';
     insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

   end if;

 end if;

 strMessaggio:='Aggiornamento fase elaborazione [fase_bil_t_elaborazione].';
 update fase_bil_t_elaborazione set
      fase_bil_elab_esito='IN2',
      fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APPROVA_PREV_SU_GEST||' IN CORSO : AGGIORNAMENTO STRUTTURE COMPLETATO.'
 where fase_bil_elab_id=faseBilElabId;

 codResult:=null;
 insert into fase_bil_t_elaborazione_log
 (fase_bil_elab_id,fase_bil_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;

  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;


 faseBilElabIdRet:= faseBilElabId;
 messaggioRisultato:=strMessaggioFinale||'OK .';
return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--- siac-6630 - Sofia fine
