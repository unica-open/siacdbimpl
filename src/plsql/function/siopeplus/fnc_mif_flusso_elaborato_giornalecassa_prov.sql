/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_giornalecassa_prov
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