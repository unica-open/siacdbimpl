/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_splus (
  enteproprietarioid integer,
  nomeente varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  mifordritrasmelabid integer,
  out flussoelabmifdistoilid integer,
  out flussoelabmifid integer,
  out numeroordinativitrasm integer,
  out nomefilemif varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 strExecSql VARCHAR(1500):='';

 mifOrdinativoIdRec record;

 mifFlussoOrdinativoRec  mif_t_ordinativo_spesa%rowtype;


 mifFlussoElabMifArr flussoElabMifRecType[];



 mifCountRec integer:=1;
 mifCountTmpRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 attoAmmRec record;
 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 soggettoSedeRec record;
 soggettoQuietRec record;
 soggettoQuietRifRec record;
 MDPRec record;
 codAccreRec record;
 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;


 tipoPagamRec record;
 ritenutaRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;
 ordRec record;


 isIndirizzoBenef boolean:=false;
 isIndirizzoBenQuiet boolean:=false;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;

 ordNumero numeric:=null;
 ordAnno  integer:=null;
 attoAmmTipoSpr varchar(50):=null;
 attoAmmTipoAll varchar(50):=null;
 attoAmmTipoAllAll varchar(50):=null;

 attoAmmStrTipoRag  varchar(50):=null;
 attoAmmTipoAllRag varchar(50):=null;


 tipoMDPCbi varchar(50):=null;
 tipoMDPCsi varchar(50):=null;
 tipoMDPCo  varchar(50):=null;
 tipoMDPCCP varchar(50):=null;
 tipoMDPCB  varchar(50):=null;
 tipoPaeseCB varchar(50):=null;
 avvisoTipoMDPCo varchar(50):=null;
 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 soggettoSedeSecId integer:=null;
 soggettoQuietId integer:=null;
 soggettoQuietRifId integer:=null;
 accreditoGruppoCode varchar(15):=null;




 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;
 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;


 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;

 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;
 ordDetTsTipoId integer :=null;

 ordSedeSecRelazTipoId integer:=null;
 ordRelazCodeTipoId integer :=null;
 ordCsiRelazTipoId  integer:=null;

 noteOrdAttrId integer:=null;

 movgestTsTipoSubId integer:=null;


 famTitSpeMacroAggrCodeId integer:=null;
 titoloUscitaCodeTipoId integer :=null;
 programmaCodeTipoId integer :=null;
 programmaCodeTipo varchar(50):=null;
 famMissProgrCode VARCHAR(50):=null;
 famMissProgrCodeId integer:=null;
 programmaId integer :=null;
 titoloUscitaId integer:=null;



 isPaeseSepa integer:=null;
 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 ordDataScadenza timestamp:=null;

 ordCsiRelazTipo varchar(20):=null;
 ordCsiCOTipo varchar(50):=null;


 ambitoFinId integer:=null;
 anagraficaBenefCBI varchar(500):=null;

 isDefAnnoRedisuo  varchar(5):=null;


 -- ritenute
 tipoRelazRitOrd varchar(10):=null;
 tipoRelazSprOrd varchar(10):=null;
 tipoRelazSubOrd varchar(10):=null;
 tipoRitenuta varchar(10):='R';
 progrRitenuta  varchar(10):=null;
 isRitenutaAttivo boolean:=false;
 tipoOnereIrpefId integer:=null;
 tipoOnereInpsId integer:=null;
 tipoOnereIrpef varchar(10):=null;
 tipoOnereInps varchar(10):=null;

 tipoOnereIrpegId integer:=null;
 tipoOnereIrpeg varchar(10):=null;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;
 codiceCofogCodeTipo  VARCHAR(50):=null;
 codiceCofogCodeTipoId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;

 classifTipoCodeFraz    varchar(50):=null;
 classifTipoCodeFrazVal varchar(50):=null;
 classifTipoCodeFrazId   integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;
 valFruttiferoClassCode   varchar(100):=null;
 valFruttiferoClassCodeId INTEGER:=null;
 valFruttiferoClassCodeSI varchar(100):=null;
 valFruttiferoCodeSI varchar(100):=null;
 valFruttiferoClassCodeNO varchar(100):=null;
 valFruttiferoCodeNO varchar(100):=null;

 cigCausAttrId INTEGER:=null;
 cupCausAttrId INTEGER:=null;
 cigCausAttr   varchar(10):=null;
 cupCausAttr   varchar(10):=null;


 codicePaeseIT varchar(50):=null;
 codiceAccreCB varchar(50):=null;
 codiceAccreCO varchar(50):=null;
 codiceAccreREG varchar(50):=null;
 codiceSepa     varchar(50):=null;
 codiceExtraSepa varchar(50):=null;
 codiceGFB  varchar(50):=null;

 sepaCreditTransfer boolean:=false;
 accreditoGruppoSepaTr varchar(10):=null;
 SepaTr varchar(10):=null;
 paeseSepaTr varchar(10):=null;


 numeroDocs varchar(10):=null;
 tipoDocs varchar(50):=null;
 tipoDocsComm varchar(50):=null;
 tipoGruppoDocs varchar(50):=null;

 tipoEsercizio varchar(50):=null;
 statoBeneficiario boolean :=false;
 bavvioFrazAttr boolean :=false;
 dataAvvioFrazAttr timestamp:=null;
 attrfrazionabile VARCHAR(50):=null;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 tipoPagamPostA VARCHAR(100):=null;
 tipoPagamPostB VARCHAR(100):=null;

 cupAttrCodeId INTEGER:=null;
 cupAttrCode   varchar(10):=null;
 cigAttrCodeId INTEGER:=null;
 cigAttrCode   varchar(10):=null;
 ricorrenteCodeTipo varchar(50):=null;
 ricorrenteCodeTipoId integer:=null;

 codiceBolloPlusEsente boolean:=false;
 codiceBolloPlusDesc   varchar(100):=null;

 statoDelegatoCredEff boolean :=false;

 comPccAttrId integer:=null;
 pccOperazTipoId integer:=null;


 -- Transazione elementare
 programmaTbr varchar(50):=null;
 codiceFinVTbr varchar(50):=null;
 codiceEconPatTbr varchar(50):=null;
 cofogTbr varchar(50):=null;
 transazioneUeTbr varchar(50):=null;
 siopeTbr varchar(50):=null;
 cupTbr varchar(50):=null;
 ricorrenteTbr varchar(50):=null;
 aslTbr varchar(50):=null;
 progrRegUnitTbr varchar(50):=null;

 codiceFinVTipoTbrId integer:=null;
 cupAttrId integer:=null;
 ricorrenteTipoTbrId integer:=null;
 aslTipoTbrId integer:=null;
 progrRegUnitTipoTbrId integer:=null;

 codiceFinVCodeTbr varchar(50):=null;
 contoEconCodeTbr varchar(50):=null;
 cofogCodeTbr varchar(50):=null;
 codiceUeCodeTbr varchar(50):=null;
 siopeCodeTbr varchar(50):=null;
 cupAttrTbr varchar(50):=null;
 ricorrenteCodeTbr varchar(50):=null;
 aslCodeTbr  varchar(50):=null;
 progrRegUnitCodeTbr varchar(50):=null;



 isGestioneQuoteOK boolean:=false;
 isGestioneFatture boolean:=false;
 isRicevutaAttivo boolean:=false;
 isTransElemAttiva boolean:=false;
 isMDPCo boolean:=false;
 isOrdPiazzatura boolean:=false;

 docAnalogico    varchar(100):=null;
 titoloCorrente   varchar(100):=null;
 descriTitoloCorrente varchar(100):=null;
 titoloCapitale   varchar(100):=null;
 descriTitoloCapitale varchar(100):=null;

 -- 20.02.2018 Sofia jira siac-5849
 defNaturaPag  varchar(100):=null;

 attrCodeDataScad varchar(100):=null;
 titoloCap  varchar(100):=null;

 isOrdCommerciale boolean:=false;
 -- 20.03.2018 Sofia SIAC-5968
 tipoPdcIVA VARCHAR(100):=null;
 codePdcIVA VARCHAR(100):=null;

 NVL_STR               CONSTANT VARCHAR:='';


 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TIPO_A CONSTANT  varchar :='A';

 ORD_RELAZ_SEDE_SEC CONSTANT  varchar :='SEDE_SECONDARIA';
 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';


 PROGRAMMA               CONSTANT varchar:='PROGRAMMA';
 TITOLO_SPESA            CONSTANT varchar:='TITOLO_SPESA';
 FAM_TIT_SPE_MACROAGGREG CONSTANT varchar:='Spesa - TitoliMacroaggregati';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO'; -- inserimenti
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE'; -- sostituzioni senza trasmissione
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO'; -- annullamenti prima di trasmissione

 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO'; -- annullamenti dopo trasmissione
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE'; -- spostamenti dopo trasmissione


 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 NUM_DODICI CONSTANT integer:=12;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF_SPLUS';


 COM_PCC_ATTR  CONSTANT  varchar :='flagComunicaPCC';
 PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';

 SEPARATORE     CONSTANT  varchar :='|';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12; -- riferimento_ente

 FLUSSO_MIF_ELAB_INIZIO_ORD     CONSTANT integer:=13;  -- tipo_operazione

 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=53;  -- fattura_siope_codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC   CONSTANT integer:=58;  -- fattura_siope_codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG CONSTANT integer:=62; -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG CONSTANT integer:=64; -- natura_spesa_siope
 FLUSSO_MIF_ELAB_NUM_SOSPESO    CONSTANT integer:=122; -- numero_provvisorio
 FLUSSO_MIF_ELAB_RITENUTA       CONSTANT integer:=124; -- importo_ritenuta
 FLUSSO_MIF_ELAB_RITENUTA_PRG   CONSTANT integer:=126; -- progressivo_versante


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Dare';



BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di spesa SIOPE PLUS.';


    -- enteOilRec
    strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
    select * into strict enteOilRec
    from siac_t_ente_oil ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   ente.data_cancellazione is null
    and   ente.validita_fine is null;

    if enteOilRec is null then
    	raise exception ' Errore in reperimento dati';
    end if;

    if enteOilRec.ente_oil_siope_plus=false then
    	raise exception ' SIOPE PLUS non attivo per l''ente.';
    end if;

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     flusso_elab_mif_codice_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
             null, -- flussoElabMifDistOilId -- da calcolare su tab progressivi
    		 dataElaborazione,
     		 enteProprietarioId,
      		 loginOperazione
      from mif_d_flusso_elaborato_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null
     )
     returning flusso_elab_mif_id into flussoElabMifLogId;-- valore da restituire

      raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',MANDMIF_TIPO;
     end if;

    strMessaggio:='Verifica esistenza elaborazioni in corso per tipo flusso '||MANDMIF_TIPO||'.';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
    where  elab.flusso_elab_mif_id!=flussoElabMifLogId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null
    and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
    and    tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
    and    tipo.ente_proprietario_id=enteProprietarioId
    and    tipo.data_cancellazione is null
    and    tipo.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION ' Verificare situazioni esistenti.';
    end if;

    -- verifico se la tabella degli id contiene dati in tal caso elaborazioni precedenti sono andate male
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_spesa_id].';
    codResult:=null;
    select distinct 1 into codResult
    from mif_t_ordinativo_spesa_id mif
    where mif.ente_proprietario_id=enteProprietarioId;

    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
   		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TS_DET_TIPO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordSedeSecRelazTipoId
        strMessaggio:='Lettura relazione sede secondaria  Code Id '||ORD_RELAZ_SEDE_SEC||'.';
        select ord_tipo.relaz_tipo_id into strict ordSedeSecRelazTipoId
        from siac_d_relaz_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.relaz_tipo_code=ORD_RELAZ_SEDE_SEC
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


    	-- programmaCodeTipoId
        strMessaggio:='Lettura programma_code_tipo_id  '||PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=PROGRAMMA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- famTitSpeMacroAggrCodeId
		-- FAM_TIT_SPE_MACROAGGREG='Spesa - TitoliMacroaggregati'
        strMessaggio:='Lettura fam_tit_spe_macroggregati_code_tipo_id  '||FAM_TIT_SPE_MACROAGGREG||'.';
		select fam.classif_fam_tree_id into strict famTitSpeMacroAggrCodeId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_SPE_MACROAGGREG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));


    	-- titoloUscitaCodeTipoId
        strMessaggio:='Lettura titolo_spesa_code_tipo_id  '||TITOLO_SPESA||'.';
		select tipo.classif_tipo_id into strict titoloUscitaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TITOLO_SPESA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- noteOrdAttrId
        strMessaggio:='Lettura noteOrdAttrId per attributo='||NOTE_ORD_ATTR||'.';
		select attr.attr_id into strict  noteOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ORD_ATTR
        and   attr.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 	 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile, flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;
        -- mifFlussoElabTypeRec


        strMessaggio:='Lettura flusso struttura MIF  per tipo '||MANDMIF_TIPO||'.';
        for mifElabRec IN
        (select m.*
         from mif_d_flusso_elaborato m
         where m.flusso_elab_mif_tipo_id=flussoElabMifTipoId
         and   m.flusso_elab_mif_elab=true
         order by m.flusso_elab_mif_ordine_elab
        )
        loop
        	mifAFlussoElabTypeRec.flussoElabMifId :=mifElabRec.flusso_elab_mif_id;
            mifAFlussoElabTypeRec.flussoElabMifAttivo :=mifElabRec.flusso_elab_mif_attivo;
            mifAFlussoElabTypeRec.flussoElabMifDef :=mifElabRec.flusso_elab_mif_default;
            mifAFlussoElabTypeRec.flussoElabMifElab :=mifElabRec.flusso_elab_mif_elab;
            mifAFlussoElabTypeRec.flussoElabMifParam :=mifElabRec.flusso_elab_mif_param;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine_elab :=mifElabRec.flusso_elab_mif_ordine_elab;
            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;
            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;



		-- Gestione registroPcc per enti che non gestiscono quitanze
        -- Nota : capire se necessario gestire PCC
		/*if enteOilRec.ente_oil_quiet_ord=false then

  			-- comPccAttrId
	        strMessaggio:='Lettura comPccAttrId per attributo='||COM_PCC_ATTR||'.';
			select attr.attr_id into strict  comPccAttrId
	        from siac_t_attr attr
	        where attr.ente_proprietario_id=enteProprietarioId
	        and   attr.attr_code=COM_PCC_ATTR
	        and   attr.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
   	 	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

            strMessaggio:='Lettura Id tipo operazine PCC='||PCC_OPERAZ_CPAG||'.';
			select pcc.pccop_tipo_id into strict pccOperazTipoId
		    from siac_d_pcc_operazione_tipo pcc
		    where pcc.ente_proprietario_id=enteProprietarioId
		    and   pcc.pccop_tipo_code=PCC_OPERAZ_CPAG;


        end if;*/

        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
	    and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso MIF tipo '||MANDMIF_TIPO||'.';

        	select viaTipo.via_tipo_code||' '||indir.toponimo||' '||indir.numero_civico,
        		   com.comune_desc
                   into indirizzoEnte,localitaEnte
            from siac_t_indirizzo_soggetto indir,
                 siac_t_comune com,
                 siac_d_via_tipo viaTipo
            where indir.soggetto_id=soggettoEnteId
            and   indir.principale='S'
            and   indir.data_cancellazione is null
            and   indir.validita_fine is null
            and   com.comune_id=indir.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null
            and   viaTipo.via_tipo_id=indir.via_tipo_id
            and   viaTipo.data_cancellazione is null
	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',viaTipo.validita_inizio)
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;

        -- Calcolo progressivo "distinta" per flusso MANDMIF
	    -- calcolo su progressivi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifDistOilRetId -- 25.05.2016 Sofia - JIRA-3619
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then -- 25.05.2016 Sofia - JIRA-3619
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_'||MANDMIF_TIPO||'_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifDistOilRetId:=0;
            end if;
        end if;

        if flussoElabMifDistOilRetId is not null then
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1;
        end if;

	    -- calcolo su progressivo di flussoElabMifOilId flussoOIL univoco
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifOilId
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_out_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifOilId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_out_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifOilId:=0;
            end if;
        end if;

        if flussoElabMifOilId is not null then
	        flussoElabMifOilId:=flussoElabMifOilId+1;
        end if;

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
        when TOO_MANY_ROWS THEN
            RAISE EXCEPTION ' Diverse righe presenti in archivio.';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;




    --- popolamento mif_t_ordinativo_spesa_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I' -- INSERIMENTO
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_spesa_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_modpag_id,
     mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
     mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (
     with
     ritrasm as
     (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	  from mif_t_ordinativo_ritrasmesso r
	  where mifOrdRitrasmElabId is not null
	  and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	  and   r.ente_proprietario_id=enteProprietarioId
	  and   r.data_cancellazione is null),
     ordinativi as
     (
      select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione , 0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id, elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
             ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
             ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id, ord.ord_desc mif_ord_desc,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
             ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
             enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
        and  ord.bil_id=bil.bil_id
        and  ord.ord_tipo_id=ordTipoCodeId
        and  ord_stato.ord_id=ord.ord_id
        and  ord_stato.data_cancellazione is null
	    and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	    and  ord_stato.validita_fine is null
        and  ord_stato.ord_stato_id=ordStatoCodeIId
        and  ord.ord_trasm_oil_data is null
        and  ord.ord_emissione_data<=dataElaborazione
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
        and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
        and  elem.ord_id=ord.ord_id
        and  elem.data_cancellazione is null
        and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S' -- 'SOSPENSIONE'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
 	   mif_ord_soggetto_id, mif_ord_modpag_id,
 	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id, mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_S mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id ,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione, ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem,siac_r_ordinativo rord
  	    where  bil.ente_proprietario_id=enteProprietarioId
   		  and  per.periodo_id=bil.periodo_id
    	  and  per.anno::integer <=annoBilancio::integer
      	  and  ord.bil_id=bil.bil_id
     	  and  ord.ord_tipo_id=ordTipoCodeId
    	  and  ord_stato.ord_id=ord.ord_id
    	  and  ord_stato.data_cancellazione is null
	   	  and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
          and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		   or (mifOrdRitrasmElabId is not null and exists
              (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
	   mif_ord_soggetto_id, mif_ord_modpag_id,
	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_N mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
      	 	   ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,
               ord.codbollo_id mif_ord_codbollo_id,ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord, siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.validita_inizio<=dataElaborazione -- questa e'' la data di annullamento
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	     and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
         and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       ),
       -- 23.03.2018 Sofia SIAC-5969
       ordSos as
       (
          select rord.ord_id_da, rord.ord_id_a
          from siac_r_ordinativo rOrd
          where rOrd.ente_proprietario_id=enteProprietarioId
          and   rOrd.relaz_tipo_id=ordRelazCodeTipoId
          and   rOrd.data_cancellazione is null
          and   rOrd.validita_fine is null
       ),
       -- 16.04.2018 Sofia siac-6067
       enteOil as
       (
       select false esclAnnull
       from siac_t_ente_oil oil
       where oil.ente_proprietario_id=enteProprietarioId
       and   oil.ente_oil_invio_escl_annulli=false
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o, enteOil  -- 16.04.2018 Sofia siac-6067
/*	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))*/
	   where
        -- 23.03.2018 Sofia SIAC-5969
        ( mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        )
        and  enteOil.esclAnnull=false -- 16.04.2018 Sofia siac-6067
        -- 23.03.2018 Sofia SIAC-5969 : devono essere escludi ordinativi
        -- sostituiti e sostituti
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_da=o.mif_ord_ord_id)
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_a=o.mif_ord_ord_id)
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id,mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_A mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
          and  per.periodo_id=bil.periodo_id
          and  per.anno::integer <=annoBilancio::integer
          and  ord.bil_id=bil.bil_id
          and  ord.ord_tipo_id=ordTipoCodeId
   		  and  ord_stato.ord_id=ord.ord_id
  		  and  ord.ord_emissione_data<=dataElaborazione
          and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		  and  ord.ord_trasm_oil_data is not null
 		  and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
          and  ord_stato.data_cancellazione is null
          and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
          and  ord_stato.ord_stato_id=ordStatoCodeAId
--          and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
          and  ( ord.ord_spostamento_data is null or date_trunc('DAY',ord.ord_spostamento_data)<=date_trunc('DAY',ord_stato.validita_inizio)) -- 30.07.2019 Sofia siac-6950
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
          and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
          and  elem.ord_id=ord.ord_id
          and  elem.data_cancellazione is null
          and  elem.validita_fine is null
        ),
        -- 23.03.2018 Sofia SIAC-5969
        ordSos as
        (
          select rord.ord_id_da, rord.ord_id_a
          from siac_r_ordinativo rOrd
          where rOrd.ente_proprietario_id=enteProprietarioId
          and   rOrd.relaz_tipo_id=ordRelazCodeTipoId
          and   rOrd.data_cancellazione is null
          and   rOrd.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
        from ordinativi o
        -- 23.03.2018 Sofia SIAC-5969
/*	    where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))*/
	    where
        ( mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        )
        -- 23.03.2018 Sofia SIAC-5969 : devono essere escludi ordinativi
        -- sostituiti e sostituti
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_da=o.mif_ord_ord_id)
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_a=o.mif_ord_ord_id)
       );

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati ) _--- VARIAZIONE
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_VB mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord.ord_trasm_oil_data is not null
         and  ord.ord_spostamento_data is not null
--         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data -- 30.07.2019 Sofia siac-6950
         and  date_trunc('DAY',ord.ord_trasm_oil_data)<=date_trunc('DAY',ord.ord_spostamento_data) -- 30.07.2019 Sofia siac-6950
         and  ord.ord_spostamento_data<=dataElaborazione
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
         and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
       select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );
      -- aggiornamento mif_t_ordinativo_spesa_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per fase_operativa_code.';
      update mif_t_ordinativo_spesa_id m
      set mif_ord_bil_fase_ope=(select fase.fase_operativa_code from siac_r_bil_fase_operativa rFase, siac_d_fase_operativa fase
      							where rFase.bil_id=m.mif_ord_bil_id
                                and   rFase.data_cancellazione is null
                                and   rFase.validita_fine is null
                                and   fase.fase_operativa_id=rFase.fase_operativa_id
                                and   fase.data_cancellazione is null
                                and   fase.validita_fine is null);


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per soggetto_id.';
      -- soggetto_id

      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id=coalesce(s.soggetto_id,0)
      from siac_r_ordinativo_soggetto s
      where s.ord_id=m.mif_ord_ord_id
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id.';

      -- modpag_id
      update mif_t_ordinativo_spesa_id m set  mif_ord_modpag_id=coalesce(s.modpag_id,0)
      from siac_r_ordinativo_modpag s
      where s.ord_id=m.mif_ord_ord_id
   	  and s.modpag_id is not null
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id [CSI].';
      update mif_t_ordinativo_spesa_id m set mif_ord_modpag_id=coalesce(rel.modpag_id,0)
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=m.mif_ord_ord_id
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      --  and rel.validita_fine is null
      -- 04.04.2018 Sofia SIAC-6064
      and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(rel.validita_fine,dataElaborazione))
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_spesa_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per liq_id.';

	 -- liq_id
	 update mif_t_ordinativo_spesa_id m
	 set mif_ord_liq_id = (select s.liq_id from siac_r_liquidazione_ord s
                            where s.sord_id = m.mif_ord_subord_id
                              and s.data_cancellazione is null
                              and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_ts_id = (select s.movgest_ts_id from siac_r_liquidazione_movgest s
                                   where s.liq_id = m.mif_ord_liq_id
                                     and s.data_cancellazione is null
                                     and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_spesa_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_liquidazione_atto_amm s
                                where s.liq_id = m.mif_ord_liq_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);

	-- mif_ord_programma_id
    -- mif_ord_programma_code
    -- mif_ord_programma_desc
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_programma_id mif_ord_programma_code mif_ord_programma_desc.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_programma_id,mif_ord_programma_code,mif_ord_programma_desc) = (class.classif_id,class.classif_code,class.classif_desc) -- 11.01.2016 Sofia
    from siac_r_bil_elem_class classElem, siac_t_class class
    where classElem.elem_id=m.mif_ord_elem_id
    and   class.classif_id=classElem.classif_id
    and   class.classif_tipo_id=programmaCodeTipoId
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
    and   class.data_cancellazione is null;

	-- mif_ord_titolo_id
    -- mif_ord_titolo_code
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_titolo_id mif_ord_titolo_code.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_titolo_id, mif_ord_titolo_code) = (cp.classif_id,cp.classif_code)
	from siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id=m.mif_ord_elem_id
    and   cf.classif_id=classElem.classif_id
    and   cf.data_cancellazione is null
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitSpeMacroAggrCodeId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
    and   cp.data_cancellazione is null;






	-- mif_ord_note_attr_id
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_note_attr_id.';
	update mif_t_ordinativo_spesa_id m
    set mif_ord_note_attr_id= attr.ord_attr_id
    from siac_r_ordinativo_attr attr
    where attr.ord_id=m.mif_ord_ord_id
    and   attr.attr_id=noteOrdAttrId
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;


    strMessaggio:='Verifica esistenza ordinativi di spesa da trasmettere.';
    codResult:=null;
    select 1 into codResult
    from mif_t_ordinativo_spesa_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di spesa da trasmettere.';
    end if;


    -- <ritenute>
    flussoElabMifElabRec:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA];

    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
  					tipoRelazRitOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	                tipoRelazSprOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
	                tipoRelazSubOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    tipoOnereIrpef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    tipoOnereInps:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    tipoOnereIrpeg:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));


                    if tipoRelazRitOrd is null or tipoRelazSprOrd is null or tipoRelazSubOrd is null
                       or tipoOnereInps is null or tipoOnereIrpef is null
                       or tipoOnereIrpeg is null then
                       RAISE EXCEPTION ' Dati configurazione ritenute non completi.';
                    end if;
                    isRitenutaAttivo:=true;
            end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
   end if;

   if isRitenutaAttivo=true then
     	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA_PRG];
         strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   	 if flussoElabMifElabRec.flussoElabMifId is null then
  			  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   	 end if;
    	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	progrRitenuta:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
	    	else
				RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   		end if;
	     else
    	   isRitenutaAttivo:=false;
		 end if;
   end if;

   if isRitenutaAttivo=true then
           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpef
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpefId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpef
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
   		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

           if tipoOnereIrpefId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereInps
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereInpsId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereInps
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereInpsId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

		   strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpeg
                        ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpegId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpeg
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereIrpegId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;
   end if;


   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];
   mifCountRec:=FLUSSO_MIF_ELAB_NUM_SOSPESO;
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			null;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
        isRicevutaAttivo:=true;
   end if;




   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    numeroDocs:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            tipoGruppoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' and
               tipoGruppoDocs is not null and tipoGruppoDocs!='' then
                tipoDocs:=tipoDocs||'|'||tipoGruppoDocs;
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_CODFISC;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    docAnalogico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            attrCodeDataScad:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_NATURA_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 20.02.2018 Sofia JIRA siac-5849
        /*
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

		end if;*/

        -- 20.02.2018 Sofia JIRA siac-5849
        if flussoElabMifElabRec.flussoElabMifDef is not null then
        	defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
        end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   --- lettura mif_t_ordinativo_spesa_id per popolamento mif_t_ordinativo_spesa
   codResult:=null;
   strMessaggio:='Lettura ordinativi di spesa da migrare [mif_t_ordinativo_spesa_id].Inizio ciclo.';
   for mifOrdinativoIdRec IN
   (select ms.*
     from mif_t_ordinativo_spesa_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
   )
   loop


		mifFlussoOrdinativoRec:=null;
		MDPRec:=null;
        codAccreRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;
        soggettoSedeRec:=null;
        soggettoRifId:=null;
        soggettoSedeSecId:=null;
		indirizzoRec:=null;
        mifOrdSpesaId:=null;




        isIndirizzoBenef:=true;
        isIndirizzoBenQuiet:=true;


        bavvioFrazAttr:=false;
        bAvvioSiopeNew:=false;


	    statoBeneficiario:=false;
		statoDelegatoCredEff:=false;

        -- lettura importo ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        													  		       flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura MDP ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura MDP ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into MDPRec
        from siac_t_modpag mdp
        where mdp.modpag_id=mifOrdinativoIdRec.mif_ord_modpag_id;
        if MDPRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_modpag.';
        end if;

        -- lettura accreditoTipo ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura accredito tipo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select tipo.accredito_tipo_id, tipo.accredito_tipo_code,tipo.accredito_tipo_desc,
               gruppo.accredito_gruppo_id, gruppo.accredito_gruppo_code
               into codAccreRec
        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
          and tipo.data_cancellazione is null
          and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		  and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
          and gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id;
        if codAccreRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_d_accredito_tipo siac_d_accredito_gruppo.';
        end if;


        -- lettura dati soggetto ordinativo
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto [siac_r_soggetto_relaz] ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';
        select rel.soggetto_id_da into soggettoRifId
        from  siac_r_soggetto_relaz rel
        where rel.soggetto_id_a=mifOrdinativoIdRec.mif_ord_soggetto_id
        and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
        and   rel.ente_proprietario_id=enteProprietarioId
        and   rel.data_cancellazione is null
		and   rel.validita_fine is null;

        if soggettoRifId is null then
	        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        else
        	soggettoSedeSecId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        end if;

        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;

        if soggettoSedeSecId is not null then
	        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati sede sec. soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

            select * into soggettoSedeRec
   		    from siac_t_soggetto sogg
	       	where sogg.soggetto_id=soggettoSedeSecId;

	        if soggettoSedeRec is null then
    	    	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id=%]',soggettoSedeSecId;
        	end if;

        end if;



        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into bilElemRec
        from siac_t_bil_elem elem
        where elem.elem_id=mifOrdinativoIdRec.mif_ord_elem_id;
        if bilElemRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_bil_elem.';
        end if;

		-- dati testata flusso presenti come tag solo in testata
        -- valorizzati su ogni ordinativo trasmesso
        -- <testata_flusso>
		-- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ABI_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_abi is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=enteOilRec.ente_oil_abi;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_ipa is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=trim(both ' ' from enteOilRec.ente_oil_codice_ipa);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_DESC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	    -- <codice_istat_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_istat is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=enteOilRec.ente_oil_codice_istat;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_fiscale_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.codice_fiscale is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=trim(both ' ' from enteProprietarioRec.codice_fiscale);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite_bt is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite_bt);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=trim(both ' ' from enteOilRec.ente_oil_codice);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <riferimento_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_riferimento is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=trim(both ' ' from enteOilRec.ente_oil_riferimento);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_flusso>

        -- <testata_esercizio>
        -- <esercizio>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_ESERCIZIO;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_anno_esercizio:=mifOrdinativoIdRec.mif_ord_anno_bil;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_esercizio>

        mifCountRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;
        mifCountTmpRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;

        -- <mandato>
		-- <tipo_operazione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null then
	            flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( mifOrdinativoIdRec.mif_ord_codice_funzione,flussoElabMifElabRec.flussoElabMifParam);
            else
            	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_codice_funzione;
            end if;
            if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_codice_funzione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <numero_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
/*         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;*/
            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if  flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_data:=mifOrdinativoIdRec.mif_ord_data_emissione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non  elaborabile.';
         end if;
        end if;



		-- <importo_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:='0';
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_evidenza>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if mifOrdinativoIdRec.mif_ord_contotes_id is not null then
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';


            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_bci_conto_tes:=substring(flussoElabMifValore from 1 for 7 );
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <estremi_provvedimento_autorizzativo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        flussoElabMifValore:=null;
        attoAmmRec:=null;
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           if mifOrdinativoIdRec.mif_ord_atto_amm_id is not null then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoSpr is null then
            		attoAmmTipoSpr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmTipoAll is null then
                	attoAmmTipoAll:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            	end if;
            end if;

            select * into attoAmmRec
            from fnc_mif_estremi_atto_amm(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                                          mifOrdinativoIdRec.mif_ord_atto_amm_movg_id,
                                          attoAmmTipoSpr,attoAmmTipoAll,
                                          dataElaborazione,dataFineVal);
           end if;

           if attoAmmRec.attoAmmEstremi is not null   then
                mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=attoAmmRec.attoAmmEstremi;
           elseif flussoElabMifElabRec.flussoElabMifDef is not null then
           		mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=flussoElabMifElabRec.flussoElabMifDef;
           end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
       end if;


       -- <responsabile_provvedimento>
	   flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifValoreDesc:=null;
	   mifCountRec:=mifCountRec+1;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_resp_attoamm:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- <ufficio_responsabile>
     mifCountRec:=mifCountRec+1;

     -- <bilancio>
     -- <codifica_bilancio>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

                mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=mifOrdinativoIdRec.mif_ord_programma_code
                												||mifOrdinativoIdRec.mif_ord_titolo_code;

                mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <descrizione_codifica>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_programma_desc from 1 for 30);
     	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     	 end if;
      end if;

      -- <gestione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
            	mifFlussoOrdinativoRec.mif_ord_gestione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anno_residuo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

            if  mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
               	   mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;


      -- <numero_articolo>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_articolo:=bilElemRec.elem_code2;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <voce_economica>
      mifCountRec:=mifCountRec+1;


      -- <importo_bilancio>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_importo_bil:=mifFlussoOrdinativoRec.mif_ord_importo;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- </bilancio>

      -- <funzionario_delegato>
      -- <codice_funzionario_delegato>
      -- <importo_funzionario_delegato>
      -- <tipologia_funzionario_delegato>
      -- <numero_pagamento_funzionario_delegato>
      mifCountRec:=mifCountRec+5;

      -- <informazioni_beneficiario>

      -- <progressivo_beneficiario>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--	  raise notice 'progressivo_beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_benef:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- <importo_beneficiario>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_importo_benef:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;


	  -- <tipo_pagamento>
      flussoElabMifElabRec:=null;
      tipoPagamRec:=null;
	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	 	if flussoElabMifElabRec.flussoElabMifElab=true then
    	   	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null then
            	if codicePaeseIT is null then
                	codicePaeseIT:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if codiceAccreCB is null then
	                codiceAccreCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if codiceAccreREG is null then
	                codiceAccreREG:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;
				if codiceSepa is null then
	                codiceSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                end if;
				if codiceExtraSepa is null then
	                codiceExtraSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                end if;

                if codiceGFB is null then
	                codiceGFB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));
                end if;

                select * into tipoPagamRec
                from fnc_mif_tipo_pagamento_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											       (case when MDPRec.iban is not null and length(MDPRec.iban)>=2
                                                   then substring(MDPRec.iban from 1 for 2)
                                                   else null end), -- codicePaese
	                                               codicePaeseIT,codiceSepa,codiceExtraSepa,
                                                   codiceAccreCB,codiceAccreREG,
                                                   flussoElabMifElabRec.flussoElabMifDef, -- compensazione
												   MDPRec.accredito_tipo_id,
                                                   codAccreRec.accredito_gruppo_code,
                                                   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC, -- importo_ordinativo
                                                   (case when codAccreRec.accredito_tipo_code=codiceGFB then true else false end),
	                                               dataElaborazione,dataFineVal,
                                                   enteProprietarioId);
                if tipoPagamRec is not null then
                	if tipoPagamRec.descTipoPagamento is not null then
                    	mifFlussoOrdinativoRec.mif_ord_pagam_tipo:=tipoPagamRec.descTipoPagamento;
                        mifFlussoOrdinativoRec.mif_ord_pagam_code:=tipoPagamRec.codeTipoPagamento;
                    end if;
                end if;

	        end if;
     	else
       		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;

      -- <impignorabili>
      mifCountRec:=mifCountRec+1;


      -- <frazionabile>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then --1
         if flussoElabMifElabRec.flussoElabMifElab=true then --2
          if flussoElabMifElabRec.flussoElabMifParam is not null and --3
             flussoElabMifElabRec.flussoElabMifDef is not null  then

             if dataAvvioFrazAttr is null then
             	dataAvvioFrazAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;

             if dataAvvioFrazAttr is not null and
                dataAvvioFrazAttr::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                then
                bavvioFrazAttr:=true;
             end if;

             if bavvioFrazAttr=false then
              if classifTipoCodeFraz is null then
               classifTipoCodeFraz:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;

              if classifTipoCodeFrazVal is null then
               classifTipoCodeFrazVal:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
             else
              if attrFrazionabile is null then
	             attrFrazionabile:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;
             end if;

             if  bavvioFrazAttr = false then
              if classifTipoCodeFraz is not null and
				 classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classificatoreTipoId '||classifTipoCodeFraz||'.';
             	select tipo.classif_tipo_id into classifTipoCodeFrazId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classifTipoCodeFraz
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null
                order by tipo.classif_tipo_id
                limit 1;
              end if;

              if classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is not null then
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore classificatore '||classifTipoCodeFraz||' [siac_r_ordinativo_class].';
             	select c.classif_code into flussoElabMifValore
                from siac_r_ordinativo_class r, siac_t_class c
                where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=r.classif_id
                and   c.classif_tipo_id=classifTipoCodeFrazId
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                and   c.data_cancellazione is null
                order by r.ord_classif_id
                limit 1;

              end if;

              if classifTipoCodeFrazVal is not null and
                flussoElabMifValore is not null and
                flussoElabMifValore=classifTipoCodeFrazVal then
             	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
             end if;
			else
              if attrFrazionabile is not null then
               --- calcolo su attributo
               codResult:=null;
               select 1 into codResult
               from  siac_t_ordinativo_ts ts,siac_r_liquidazione_ord liqord,
                     siac_r_liquidazione_movgest rmov,
                     siac_r_movgest_ts_attr r, siac_t_attr attr
               where ts.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
               and   liqord.sord_id=ts.ord_ts_id
               and   rmov.liq_id=liqord.liq_id
               and   r.movgest_ts_id=rmov.movgest_ts_id
               and   attr.attr_id=r.attr_id
               and   attr.attr_code=attrFrazionabile
               and   r.boolean='N'
               and   r.data_cancellazione is null
               and   r.validita_fine is null
               and   rmov.data_cancellazione is null
               and   rmov.validita_fine is null
               and   liqord.data_cancellazione is null
               and   liqord.validita_fine is null
			   and   ts.data_cancellazione is null
               and   ts.validita_fine is null;

               if codResult is not null then
               	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

             end if;

            end if;

          end if; -- 3
      	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;  --- 2

        end if; -- 1

  	   -- <gestione_provvisoria>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
        -- gestione_provvisoria da impostare solo se frazionabile=NO
       if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz is not null then
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             flussoElabMifElabRec.flussoElabMifDef is not null and
             mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null  then

             if tipoEsercizio is null then
	             tipoEsercizio:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
          	if tipoEsercizio=mifOrdinativoIdRec.mif_ord_bil_fase_ope  then
				mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov=flussoElabMifElabRec.flussoElabMifDef;
            end if;
		   end if;


         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;

        end if;
        --- frazionabile da impostare NO solo se gestione_provvisoria=SI
        if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov is null then
        	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=null;
        end if;

      else
       	null;
      end if;

      -- <data_esecuzione_pagamento>
      flussoElabMifElabRec:=null;
      ordDataScadenza:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=flussoElabMifElabRec.flussoElabMifParam then
            	flussoElabMifElabRec.flussoElabMifElab:=false; -- se REGOLARIZZAZIONE data_esecuzione_pagamento non deve essere valorizzato
            end if;

            if flussoElabMifElabRec.flussoElabMifElab=true then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza.';
        	 select sub.ord_ts_data_scadenza into ordDataScadenza
             from siac_t_ordinativo_ts sub
             where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;

             if ordDataScadenza is not null and
--               date_trunc('DAY',ordDataScadenza)>= date_trunc('DAY',dataElaborazione) and
               date_trunc('DAY',ordDataScadenza)> date_trunc('DAY',dataElaborazione) and -- 13.12.2017 Sofia siac-5653
               extract('year' from ordDataScadenza)::integer<=annoBilancio::integer then
		  		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec:=
    		        extract('year' from ordDataScadenza)||'-'||
    	         	lpad(extract('month' from ordDataScadenza)::varchar,2,'0')||'-'||
            	 	lpad(extract('day' from ordDataScadenza)::varchar,2,'0');
             end if;
            end if;

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <data_scadenza_pagamento>
  	  mifCountRec:=mifCountRec+1;

	  -- <destinazione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	   RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	   if flussoElabMifElabRec.flussoElabMifElab=true then

        if flussoElabMifElabRec.flussoElabMifParam is not null or
           flussoElabMifElabRec.flussoElabMifDef is not null then --1

           if flussoElabMifElabRec.flussoElabMifParam is not null then --2
		    if classVincolatoCode is null then
	        	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCode is not null and classVincolatoCodeId is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into classVincolatoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classVincolatoCode;

            end if;

            if classVincolatoCodeId is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore per classVincolatoCode='||classVincolatoCode||'.';

                         select c.classif_desc into flussoElabMifValore
                         from siac_r_ordinativo_class r, siac_t_class c
                         where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                         and   c.classif_id=r.classif_id
                         and   c.classif_tipo_id=classVincolatoCodeId
                         and   r.data_cancellazione is null
                         and   r.validita_fine is null
                         and   c.data_cancellazione is null;

            end if;
  	     end if; --2


         if flussoElabMifValore is null and --3
            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    		                   ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		           ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                		       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                    		   ||' mifCountRec='||mifCountRec
	                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_vincolato].';

			select mif.vincolato into flussoElabMifValore
    	    from mif_r_conto_tesoreria_vincolato mif
	    	where mif.ente_proprietario_id=enteProprietarioId
    	    and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	        and   mif.validita_fine is null
		    and   mif.data_cancellazione is null;


        end if; --3
 	    if flussoElabMifValore is null and
           flussoElabMifElabRec.flussoElabMifDef is not null then
           flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
        end if;

	    if flussoElabMifValore is not null then
        	mifFlussoOrdinativoRec.mif_ord_progr_dest:=flussoElabMifValore;
        end if;

       end if; --1
      else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
      end if;
     end if;


     -- <numero_conto_banca_italia_ente_ricevente>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     codResult:=null;
     if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	-- non esposto se regolarizzazione (provvisori)
                if mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
-- 28.12.2017 Sofia SIAC-5665	   mifFlussoOrdinativoRec.mif_ord_pagam_tipo= trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
          		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                    or
                     mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                    )  then -- 28.12.2017 Sofia SIAC-5665

                   flussoElabMifElabRec.flussoElabMifElab:=false;
                end if;

                if flussoElabMifElabRec.flussoElabMifElab=true then
	             if tipoMDPCbi is null then
                   	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
               	  end if;


                  if tipoMDPCbi is not null then
                  	if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
                        	 mifFlussoOrdinativoRec.mif_ord_bci_conto:=MDPRec.contocorrente;
                    end if;
                  end if;
                 end if;


            end if;
       else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;


     -- <tipo_contabilita_ente_ricevente>
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     codResult:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
             if flussoElabMifElabRec.flussoElabMifDef is not null then

                if flussoElabMifElabRec.flussoElabMifParam is not null then
                   if tipoClassFruttifero is null then
                    	tipoClassFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                   end if;

                   if tipoClassFruttifero is not null and valFruttifero is null then
	                   valFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                       valFruttiferoStr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                       valFruttiferoStrAltro:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                   end if;

                   if tipoClassFruttifero is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      tipoClassFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classifTipoCodeId '||tipoClassFruttifero||'.';
                   	select tipo.classif_tipo_id into tipoClassFruttiferoId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoClassFruttifero
                    and   tipo.data_cancellazione is null
                    and   tipo.validita_fine is null;

                   end if;


                   if tipoClassFruttiferoId is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      valFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' [siac_r_ordinativo_class].';


                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;

                  end if;

				end if; -- param

				if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
                end if;

               if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null and
	              mifOrdinativoIdRec.mif_ord_contotes_id is not null and
    	          mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

               	  flussoElabMifValore:=null;
	              strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	           	  select mif.fruttifero into flussoElabMifValore
	              from mif_r_conto_tesoreria_fruttifero mif
    	          where mif.ente_proprietario_id=enteProprietarioId
        	      and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
            	  and   mif.validita_fine is null
	              and   mif.data_cancellazione is null;

    	          if flussoElabMifValore is not null then
        	       	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
            	  end if;

              end if;

              if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null then
                   	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
           end if; -- default
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <tipo_postalizzazione>
      flussoElabMifElabRec:=null;
      codResult:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'tipo_postalizzazione mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null and
            flussoElabMifElabRec.flussoElabMifDef is not null then
           if tipoPagamPostA is null then
           	tipoPagamPostA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
           end if;

           if tipoPagamPostB is null then
           	tipoPagamPostB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
           end if;


           if tipoPagamPostA is not null or tipoPagamPostB is not null then
			  if tipoPagamRec is not null and tipoPagamRec.descTipoPagamento is not null then
              	if tipoPagamRec.descTipoPagamento in (tipoPagamPostA,tipoPagamPostB) then
	                mifFlussoOrdinativoRec.mif_ord_pagam_postalizza:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
              end if;
           end if;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;


      -- <classificazione>
	  -- <codice_cgu>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      codiceCge:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'classificazione mifCountRec=%',mifCountRec;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then -- attivo
       if flussoElabMifElabRec.flussoElabMifElab=true then -- elab

        if flussoElabMifElabRec.flussoElabMifParam is not null then -- param

       	 if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
         end if;

         if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
            flussoElabMifElabRec.flussoElabMifParam is not null then
           	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
       	 	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
       	  if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
             then
              bAvvioSiopeNew:=true;
           end if;
         end if;

         if bAvvioSiopeNew=true then -- avvioSiopeNew
           if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;

          end if;
         else -- avvioSiopeNew
           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is null and siopeCodeTipo is not null then
           	select tipo.classif_tipo_id into siopeCodeTipoId
            from siac_d_class_tipo tipo
            where tipo.classif_tipo_code=siopeCodeTipo
            and   tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.data_cancellazione is null
	 		and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
           end if;

           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is not null then
           	select class.classif_code, class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
            from siac_r_ordinativo_class cord, siac_t_class class
            where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and cord.data_cancellazione is null
            and cord.validita_fine is null
            and class.classif_id=cord.classif_id
            and class.classif_code!=siopeDef
            and class.data_cancellazione is null
            and class.classif_tipo_id=siopeCodeTipoId;

            if flussoElabMifValore is null then
             select class.classif_code, class.classif_desc
                    into flussoElabMifValore,flussoElabMifValoreDesc
             from siac_r_liquidazione_class cord, siac_t_class class
             where cord.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
             and cord.data_cancellazione is null
             and cord.validita_fine is null
             and class.classif_id=cord.classif_id
             and class.classif_code!=siopeDef
             and class.data_cancellazione is null
             and class.classif_tipo_id=siopeCodeTipoId;
            end if;


           end if;
         end if; -- avvioSiopeNew


         if flussoElabMifValore is not null then
         	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
            codiceCge:=flussoElabMifValore;
         end if;
        end if; -- param
       else -- elab
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if; -- elab
      end if; -- attivo

	  -- <codice_cup>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cupAttrCode,NVL_STR)=NVL_STR then
                	cupAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cupAttrCode,NVL_STR)!=NVL_STR and cupAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupAttrCode||'.';
                	select attr.attr_id into cupAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cupAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_codice_cup is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_cpv>
      mifCountRec:=mifCountRec+1;

      -- <importo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
 	      	mifFlussoOrdinativoRec.mif_ord_class_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- </classificazione>

      -- <classificazione_dati_siope_uscite>
	  -- <tipo_debito_siope_c>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isOrdCommerciale:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 21.12.2017 Sofia JIRA SIAC-5665
        if flussoElabMifElabRec.flussoElabMifParam is not null then
            flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

            isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
                                                                         tipoDocsComm,
                                                   	                     enteProprietarioId
                                                                        );


/*        	if mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura tipo debito [siac_d_siope_tipo_debito].';
            	select tipo.siope_tipo_debito_desc_bnkit into flussoElabMifValore
                from siac_d_siope_tipo_debito tipo
                where tipo.siope_tipo_debito_id=mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id;
            end if;

            if flussoElabMifValore is not null and
               upper(flussoElabMifValore)=flussoElabMifElabRec.flussoElabMifParam then
               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifElabRec.flussoElabMifParam;
               isOrdCommerciale:=true;
            end if;*/
            -- 21.12.2017 Sofia JIRA SIAC-5665
            if isOrdCommerciale=true then
            	mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifValore;
            end if;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <tipo_debito_siope_nc>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      if isOrdCommerciale=false then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifDef is not null then
            -- 20.03.2018 Sofia SIAC-5968 - test sul pdcFin di OP per verificare se IVA
            if flussoElabMifElabRec.flussoElabMifParam is not null then
         	 if coalesce(tipoPdcIVA,'')='' then
	         	tipoPdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
             if coalesce(codePdcIVA,'')='' then
	         	codePdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
             end if;

             if coalesce(tipoPdcIVA,'')!=''  and coalesce(codePdcIVA,'')!='' then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Verifica tipo debito IVA.';
             	select 1 into codResult
                from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipo
                where rc.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=rc.classif_id
                and   tipo.classif_tipo_id=c.classif_tipo_id
                and   tipo.classif_tipo_code=tipoPdcIVA
                and   c.classif_code like codePdcIVA||'%'
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null;

                if codResult is not null then
	               	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
             end if;

            end if;

            -- 21.12.2017 Sofia JIRA SIAC-5665
            --mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifElabRec.flussoElabMifParam;

            -- 20.03.2018 Sofia SIAC-5968
            if flussoElabMifValore is null then
            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
            end if;
            -- 20.03.2018 Sofia SIAC-5968
			mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifValore;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;




      -- <codice_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      raise notice 'codice_cig_siope mifCountRec=%',mifCountRec;
      -- solo per COMMERCIALI
	  if isOrdCommerciale=true then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cigAttrCode,NVL_STR)=NVL_STR then
                	cigAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cigAttrCode,NVL_STR)!=NVL_STR and cigAttrCodeId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigAttrCode||'.';
                	select attr.attr_id into cigAttrCodeId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cigAttrCodeId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigAttrCodeId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_cig is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigAttrCodeId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      -- <motivo_esclusione_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      -- solo per COMMERCIALI
      if isOrdCommerciale=true and
         mifFlussoOrdinativoRec.mif_ord_class_cig is null then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

	   if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
       	  if mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura motivazione [siac_d_siope_assenza_motivazione].';
            raise notice 'siope_assenza_motivazione_desc_bnkit';
		  	select upper(ass.siope_assenza_motivazione_desc_bnkit) into flussoElabMifValore
			from siac_d_siope_assenza_motivazione ass
			where ass.siope_assenza_motivazione_id=mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id;
          end if;
		  if flussoElabMifValore is not null then
	    	  mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig:=flussoElabMifValore;
              raise notice 'siope_assenza_motivazione_desc_bnkit=%',mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig;

          end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      raise notice 'motivo_esclusione_cig_siope mifCountRec=%',mifCountRec;

      -- <fatture_siope>
      -- </fatture_siope>
      mifCountRec:=mifCountRec+12;

      -- <dati_ARCONET_siope>


      -- <codice_missione_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_missione:=SUBSTRING(mifOrdinativoIdRec.mif_ord_programma_code from 1 for 2);
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      raise notice 'codice_missione_siope mifCountRec=%',mifCountRec;

      -- <codice_programma_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_programma:=mifOrdinativoIdRec.mif_ord_programma_code;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_economico_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
                              raise notice 'codice_economico_siope mifCountRec=%',mifCountRec;

      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        if flussoElabMifElabRec.flussoElabMifParam is not null then

          if codiceFinVTbr is null then
				codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
          end if;

		  if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select class.classif_code  into flussoElabMifValore
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select class.classif_code  into flussoElabMifValore
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;
          end if;
/*
       	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo coll. evento '||flussoElabMifElabRec.flussoElabMifParam||'.';


            select coll.collegamento_tipo_id into collEventoCodeId
            from siac_d_collegamento_tipo coll
            where coll.ente_proprietario_id=enteProprietarioId
            and   coll.collegamento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   coll.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',coll.validita_inizio)
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(coll.validita_fine,dataElaborazione));

         end if;

	     if collEventoCodeId is not null then
		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
                             raise notice 'QUI QUI strMessaggio=%',strMessaggio;

          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where evento.ente_proprietario_id=enteProprietarioId
          and   evento.collegamento_tipo_id=collEventoCodeId -- OP
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN togliamo ambito
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A  -- forse sarebbe meglio prendere solo i D
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Dare
		  and   conto.pdce_conto_id=det.pdce_conto_id
          and   regMovFin.data_cancellazione is null
          and   regMovFin.validita_fine is null
          and   rEvento.data_cancellazione is null
          and   rEvento.validita_fine is null
          and   evento.data_cancellazione is null
          and   evento.validita_fine is null
          and   reg.data_cancellazione is null
          and   reg.validita_fine is null
          and   regstato.data_cancellazione is null
          and   regstato.validita_fine is null
          and   pn.data_cancellazione is null
          and   pn.validita_fine is null
          and   rpnota.data_cancellazione is null
          and   rpnota.validita_fine is null
          and   conto.data_cancellazione is null
          and   conto.validita_fine is null
          order by pn.pnota_id desc
          limit 1;
         end if;
*/
       end if;


        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <importo_codice_economico_siope>
	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_economico is not null then
      	flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

	    if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		mifFlussoOrdinativoRec.mif_ord_class_importo_economico:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

      -- <codice_UE_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
            raise notice 'codice_UE_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceUECodeTipo is null then
				codiceUECodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceUECodeTipo is not null and codiceUECodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceUECodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceUECodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceUECodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                             raise notice 'QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceUECodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

                             raise notice '222QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceUECodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
                raise notice 'QUI QUI flussoElabMifValore=%',flussoElabMifValore;
            	mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <codice_uscita_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                  raise notice 'codice_uscita_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if ricorrenteCodeTipo is null then
				ricorrenteCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if ricorrenteCodeTipo is not null and ricorrenteCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into ricorrenteCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=ricorrenteCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if ricorrenteCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select upper(class.classif_desc) into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=ricorrenteCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select upper(class.classif_desc) into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=ricorrenteCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;


      -- <codice_cofog_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                        raise notice 'codice_cofog_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceCofogCodeTipo is null then
				codiceCofogCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceCofogCodeTipo is not null and codiceCofogCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceCofogCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceCofogCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceCofogCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceCofogCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceCofogCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_cofog_codice:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <importo_cofog_siope>
  	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_cofog_codice is not null then
       flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
        		mifFlussoOrdinativoRec.mif_ord_class_cofog_importo:=mifFlussoOrdinativoRec.mif_ord_importo;

         else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		 end if;
	    end if;
       end if;

      -- </dati_ARCONET_siope>

      -- </classificazione_dati_siope_uscite>

      -- <bollo>
      -- <assoggettamento_bollo>
   	  mifCountRec:=mifCountRec+1;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then


	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then

          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo in
                 (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- F24EP
                 ) then

               codiceBolloPlusEsente:=true;
               -- REGOLARIZZAZIONE
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
               end if;
               -- F24EP
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               end if;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , plus.codbollo_plus_desc, plus.codbollo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
             from siac_d_codicebollo bollo, siac_d_codicebollo_plus plus, siac_r_codicebollo_plus rp
             where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id
             and   rp.codbollo_id=bollo.codbollo_id
             and   plus.codbollo_plus_id=rp.codbollo_plus_id
             and   rp.data_cancellazione is null
             and   rp.validita_fine is null;

             if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_bollo_carico:=codiceBolloPlusDesc;
             end if;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
       end if;

      -- <causale_esenzione_bollo>
   	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      if codiceBolloPlusEsente=true and coalesce(ordCodiceBolloDesc,NVL_STR)!=NVL_STR then
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
            if mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione is null then
--              27.06.2018 Sofia siac-6272
--	          	mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=ordCodiceBolloDesc;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- </bollo>

	  -- <spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      -- <soggetto_destinatario_delle_spese>
      if mifOrdinativoIdRec.mif_ord_comm_tipo_id is not null then
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice commissione.';

            select tipo.comm_tipo_desc , plus.comm_tipo_plus_desc, plus.comm_tipo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
            from siac_d_commissione_tipo tipo, siac_d_commissione_tipo_plus plus, siac_r_commissione_tipo_plus rp
            where tipo.comm_tipo_id=mifOrdinativoIdRec.mif_ord_comm_tipo_id
            and   rp.comm_tipo_id=tipo.comm_tipo_id
            and   plus.comm_tipo_plus_id=rp.comm_tipo_plus_id
            and   rp.data_cancellazione is null
            and   rp.validita_fine is null;

            if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_commissioni_carico:=codiceBolloPlusDesc;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- <natura_pagamento>
      mifCountRec:=mifCountRec+1;

      -- <causale_esenzione_spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if codiceBolloPlusEsente=true and mifFlussoOrdinativoRec.mif_ord_commissioni_carico is not null then
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione:=ordCodiceBolloDesc;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
       end if;
      end if;
      -- </spese>

	  -- <beneficiario>
      mifCountRec:=mifCountRec+1;
      -- <anagrafica_beneficiario>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      anagraficaBenefCBI:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--       raise notice 'beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if soggettoSedeSecId is not null then
            	flussoElabMifValore:=soggettoRec.soggetto_desc||' '||soggettoSedeRec.soggetto_desc;
            else
            	flussoElabMifValore:=soggettoRec.soggetto_desc;
            end if;

            /*if flussoElabMifElabRec.flussoElabMifParam is not null and tipoMDPCbi is null then
	           	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if; */

            -- se non e girofondo o se lo e ma il contocorrente_intestazione e vuoto
            -- valorizzo i tag di anagrafica_beneficiario
            -- altrimenti solo anagrafica_beneficiario=contocorrente_intestazione
            -- e anagrafica_beneficiario in dati_a_disposizione_ente
            /*if codAccreRec.accredito_gruppo_code!=tipoMDPCbi or
			   (codAccreRec.accredito_gruppo_code=tipoMDPCbi and
                 (MDPRec.contocorrente_intestazione is null or MDPRec.contocorrente_intestazione='')) then
	           	mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);
            else
	            	anagraficaBenefCBI:=flussoElabMifValore;
	                mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(MDPRec.contocorrente_intestazione from 1 for 140);
            end if;*/

            mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;



	 -- <indirizzo_beneficiario>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' indirizzo_benef mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        	if soggettoSedeSecId is not null then
                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoSedeSecId
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

            else
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;

            end if;

            if indirizzoRec is null then
            	-- RAISE EXCEPTION ' Errore in lettura indirizzo soggetto [siac_t_indirizzo_soggetto].';
                isIndirizzoBenef:=false;
            end if;

            if isIndirizzoBenef=true then

             if indirizzoRec.via_tipo_id is not null then
            	select tipo.via_tipo_code into flussoElabMifValore
                from siac_d_via_tipo tipo
                where tipo.via_tipo_id=indirizzoRec.via_tipo_id
                and   tipo.data_cancellazione is null
         	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
                if flussoElabMifValore is not null then
                	flussoElabMifValore:=flussoElabMifValore||' ';
                end if;
             end if;

             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

             if flussoElabMifValore is not null and anagraficaBenefCBI is null then
	            mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
             end if;
           end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

   	  -- <cap_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	  end if;

      -- <localita_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select com.comune_desc into flussoElabMifValore
            from siac_t_comune com
            where com.comune_id=indirizzoRec.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;


	  -- <provincia_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select prov.sigla_automobilistica into flussoElabMifValore
            from siac_r_comune_provincia provRel, siac_t_provincia prov
            where provRel.comune_id=indirizzoRec.comune_id
            and   provRel.data_cancellazione is null
            and   provRel.validita_fine is null
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
            order by provRel.data_creazione;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;

      -- <stato_beneficiario>
      mifCountRec:=mifCountRec+1; -- popolare in seguito ricavato il codice_paese di piazzatura
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
          if anagraficaBenefCBI is null and
             statoBeneficiario=false then
	            statoBeneficiario:=true;
           end if;
         else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <partita_iva_beneficiario>
      mifCountRec:=mifCountRec+1;
      if ( anagraficaBenefCBI is null and
            (soggettoRec.partita_iva is not null or
            (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11))
          )   then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	    if soggettoRec.partita_iva is not null then
		            mifFlussoOrdinativoRec.mif_ord_partiva_benef:=soggettoRec.partita_iva;
                else
                    if length(trim ( both ' ' from soggettoRec.codice_fiscale))=11 then
                        mifFlussoOrdinativoRec.mif_ord_partiva_benef:=trim ( both ' ' from soggettoRec.codice_fiscale);
                    end if;
                end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;

       -- <codice_fiscale_beneficiario>
      mifCountRec:=mifCountRec+1;
--      if mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and anagraficaBenefCBI is null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
            -- se CASSA codice_fiscale obbligatorio
          	if flussoElabMifElabRec.flussoElabMifParam is not null then
		            if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                       if soggettoRec.codice_fiscale is not null then
                    	flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
                       else
	                    if mifFlussoOrdinativoRec.mif_ord_partiva_benef is not null then
     	                   flussoElabMifValore:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                        end if;
                       end if;
                    end if;
            end if;

            -- se non CASSA valorizzato se partita iva non presente e  codice_fiscale=16
            if flussoElabMifValore is null and
               mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and
               soggettoRec.codice_fiscale is not null and
               length(soggettoRec.codice_fiscale)=16 then
               flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		             mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
--        end if;
      -- </beneficiario>


      -- <delegato>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isMDPCo:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                    if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                    	isMDPCo:=true;
                    end if;

					if isMDPCo=true and -- non esporre se REGOLARIZZAZIONE ( provvisori di cassa )
                       mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
            		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                         or
                         mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                       )  then -- 20.12.2017 Sofia Jira SIAC-5665
			             isMDPCo=false;
			        end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anagrafica_delegato>
      mifCountRec:=mifCountRec+1;
      if isMDPCo=true and MDPRec.quietanziante is not null then
        	flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;

     	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	    end if;
            if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	mifFlussoOrdinativoRec.mif_ord_anag_quiet:=MDPRec.quietanziante;
           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		         end if;
	        end if;
      end if;

      mifCountRec:=mifCountRec+7;
--      raise notice 'codfisc_quiet mifCountRec=%',mifCountRec;
      -- <codice_fiscale_delegato>
      if isMDPCo=true and mifFlussoOrdinativoRec.mif_ord_anag_quiet is not null and
         MDPRec.quietanziante_codice_fiscale is not null  and
         length(MDPRec.quietanziante_codice_fiscale)=16   then
             flussoElabMifElabRec:=null;
      		 flussoElabMifValore:=null;
             flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 72
		     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	 if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	     end if;
             if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	flussoElabMifValore:=trim ( both ' ' from MDPRec.quietanziante_codice_fiscale);

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_codfisc_quiet:=flussoElabMifValore;
                    end if;

           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		        end if;
	         end if;
      end if;
      -- </delegato>

	  -- <creditore_effettivo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      soggettoQuietRec:=null;
      soggettoQuietRifRec:=null;
      soggettoQuietId:=null;
      soggettoQuietRifId:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

	      /* -- 20.04.2018 Sofia JIRA SIAC-6097
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
             ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))
               or -- 13.04.2018 Sofia JIRA SIAC-6097
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6))
                 -- 13.04.2018 Sofia JIRA SIAC-6097
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7))
                 -- 19.04.2018 Sofia JIRA SIAC-6097
             )   then -- 20.12.2017 Sofia JIRA siac-5665

          end if;*/


          -- 20.04.2018 Sofia JIRA SIAC-6097
          if flussoElabMifElabRec.flussoElabMifParam is not null and
           mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null  then

           flussoElabMifValore:= regexp_replace(flussoElabMifElabRec.flussoElabMifParam,
                                                trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))||'.'||
                                                trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'.',
							                    '');
 		   if  fnc_mif_ordinativo_esenzione_bollo(mifFlussoOrdinativoRec.mif_ord_pagam_tipo,flussoElabMifValore)=true  then
	           flussoElabMifElabRec.flussoElabMifElab=false;
               flussoElabMifValore:=null;
           end if;
          end if;

          if flussoElabMifElabRec.flussoElabMifElab=true then -- non esporre su regolarizzazione (provvisori)
           if  ordCsiRelazTipoId is null then
            if ordCsiRelazTipo is null then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
	                ordCsiRelazTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    ordCsiCOTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
            end if;

            if ordCsiRelazTipo is  not null then
                select tipo.oil_relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_oil_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.oil_relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
                  and tipo.validita_fine is null;
            end if;
           end if;

           if ordCsiRelazTipoId is not null and
              ( ordCsiCOTipo is null or ordCsiCOTipo!=codAccreRec.accredito_gruppo_code ) then

                soggettoQuietId:=MDPRec.soggetto_id;

                select sogg.*
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg,
                     siac_r_oil_relaz_tipo roil
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                -- and   relmdp.validita_fine is null 04.04.2018 Sofia SIAC-6064
                -- 04.04.2018 Sofia SIAC-6064
			    and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(relmdp.validita_fine,dataElaborazione))
    			and   relmdp.soggetto_relaz_id=relsogg.soggetto_relaz_id
                and   relsogg.soggetto_id_a=MDPRec.soggetto_id
                and   relsogg.soggetto_id_da=soggettoRifId
                and   roil.relaz_tipo_id=relsogg.relaz_tipo_id
                and   roil.oil_relaz_tipo_id=ordCsiRelazTipoId
                and   relsogg.data_cancellazione is null
                and   relsogg.validita_fine is null
                and   roil.data_cancellazione is null
                and   roil.validita_fine is null;

				if soggettoQuietRec is null then
                	soggettoQuietId:=null;
                end if;

               if soggettoQuietId is not null then
                 select sogg.*
                        into soggettoQuietRifRec
		         from  siac_t_soggetto sogg, siac_r_soggetto_relaz rel
		         where rel.soggetto_id_a=soggettoQuietRec.soggetto_id
		         and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
		         and   rel.ente_proprietario_id=enteProprietarioId
		         and   rel.data_cancellazione is null
                 and   rel.validita_fine is null
                 and   sogg.soggetto_id=rel.soggetto_id_da
		         and   sogg.data_cancellazione is null
                 and   sogg.validita_fine is null;


                 if soggettoQuietRifRec is null then

                 else
                 	soggettoQuietRifId:=soggettoQuietRifRec.soggetto_id;
                 end if;
               end if;
            end if;
          end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      mifCountRec:=mifCountRec+1;
  	  -- <anagrafica_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --63
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
	            if soggettoQuietRifId is not null then
    	        	flussoElabMifValore:=soggettoQuietRifRec.soggetto_desc||' '||soggettoQuietRec.soggetto_desc;
        	    else
            		flussoElabMifValore:=soggettoQuietRec.soggetto_desc;
	            end if;

                if flussoElabMifValore is not null then
--                	mifFlussoOrdinativoRec.mif_ord_anag_del:=substring(flussoElabMifValore from 1 for 140);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in creditore_effettivo -- anagrafica_beneficiario
                    mifFlussoOrdinativoRec.mif_ord_anag_del:=mifFlussoOrdinativoRec.mif_ord_anag_benef;
                    mifFlussoOrdinativoRec.mif_ord_indir_del:=mifFlussoOrdinativoRec.mif_ord_indir_benef;
                    mifFlussoOrdinativoRec.mif_ord_cap_del:=mifFlussoOrdinativoRec.mif_ord_cap_benef;
                    mifFlussoOrdinativoRec.mif_ord_localita_del:=mifFlussoOrdinativoRec.mif_ord_localita_benef;
                    mifFlussoOrdinativoRec.mif_ord_prov_del:=mifFlussoOrdinativoRec.mif_ord_prov_benef;
                    mifFlussoOrdinativoRec.mif_ord_partiva_del:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                    mifFlussoOrdinativoRec.mif_ord_codfisc_del:=mifFlussoOrdinativoRec.mif_ord_codfisc_benef;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	  end if;

      mifCountRec:=mifCountRec+1;
      -- <indirizzo_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         indirizzoRec:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoQuietId
                and   (case when soggettoQuietRifId is null
                            then indir.principale='S' else coalesce(indir.principale,'N')='N' end)
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

                if indirizzoRec is null then
                    isIndirizzoBenQuiet:=false;
            	end if;

			    if isIndirizzoBenQuiet=true then

            	 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
                	from siac_d_via_tipo tipo
               		where tipo.via_tipo_id=indirizzoRec.via_tipo_id
	                and   tipo.data_cancellazione is null
    	     	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 			 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                	if flussoElabMifValore is not null then
                		flussoElabMifValore:=flussoElabMifValore||' ';
               	    end if;

           		  end if;

	             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
    	                             ||' '||coalesce(indirizzoRec.numero_civico,''));

        	     if flussoElabMifValore is not null then
--	        	    mifFlussoOrdinativoRec.mif_ord_indir_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
	             end if;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

	 -- <cap_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
--         		mifFlussoOrdinativoRec.mif_ord_cap_del:=lpad(indirizzoRec.zip_code,5,'0');

				-- 24.01.2018 Sofia jira siac-5765 - scambio tag
                -- in anagrafica_beneficiario -- creditore_effettivo
                mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;

         end if;
        end if;
     end if;


     -- <localita_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select com.comune_desc into flussoElabMifValore
           		from siac_t_comune com
	            where com.comune_id=indirizzoRec.comune_id
    	        and   com.data_cancellazione is null
                and   com.validita_fine is null;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_localita_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <provincia_creditore_effettivo>
	 if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select prov.sigla_automobilistica into flussoElabMifValore
            	from siac_r_comune_provincia provRel, siac_t_provincia prov
           		where provRel.comune_id=indirizzoRec.comune_id
           	  	and   provRel.data_cancellazione is null
                and   provRel.validita_fine is null
        	    and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
        	    order by provRel.data_creazione;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_prov_del:=flussoElabMifValore;
                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <stato_creditore_effettivo>
     if soggettoQuietId is not null  then
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
         	if statoDelegatoCredEff=false then
	            statoDelegatoCredEff:=true;
                -- valorizzato poi in piazzatura
            end if;
          else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
       end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <partita_iva_creditore_effettivo>
     if soggettoQuietId is not null THEN
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
                if  soggettoQuietRifId is not null then
	            	if soggettoQuietRifRec.partita_iva is not null  or
                       (soggettoQuietRifRec.partita_iva is null and
                        soggettoQuietRifRec.codice_fiscale is not null and length(soggettoQuietRifRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRifRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRifRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                        end if;
                     end if;
				else
                	if soggettoQuietRec.partita_iva is not null  or
                       (soggettoQuietRec.partita_iva is null and
                        soggettoQuietRec.codice_fiscale is not null and length(soggettoQuietRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                        end if;
                    end if;
                end if;

			    if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_partiva_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_partiva_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     mifCountRec:=mifCountRec+1;
     -- <codice_fiscale_creditore_effettivo>
     if soggettoQuietId is not null  then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if soggettoQuietRifId is not null then
                 if mifFlussoOrdinativoRec.mif_ord_partiva_del is null then
                  if soggettoQuietRifRec.codice_fiscale is not null and
                     length(soggettoQuietRifRec.codice_fiscale)= 16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                  end if;
                 end if;
                else
                 if soggettoQuietRec.codice_fiscale is not null and
                    length(soggettoQuietRec.codice_fiscale)=16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                 end if;
                end if;

				if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_codfisc_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
  		            mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
        end if;
     end if;

     -- </creditore_effettivo>
/**/
	 -- <piazzatura>
     flussoElabMifElabRec:=null;
     isOrdPiazzatura:=false;
     accreditoGruppoCode:=null;
     isPaeseSepa:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'piazzatura mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
       	 if flussoElabMifElabRec.flussoElabMifParam is not null then
            isOrdPiazzatura:=fnc_mif_ordinativo_piazzatura_splus(MDPRec.accredito_tipo_id,
                                                           		 mifOrdinativoIdRec.mif_ord_codice_funzione,
		  												         flussoElabMifElabRec.flussoElabMifParam,
                                                                 mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
			                                                     dataElaborazione,dataFineVal,enteProprietarioId);
         end if;
      	else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
     end if;

     if isOrdPiazzatura=true then

      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura tipo accredito MDP per popolamento  campi relativi a'||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

--        raise notice 'Ordinativo con piazzatura % codice funzione=%',mifOrdinativoIdRec.mif_ord_ord_id,mifOrdinativoIdRec.mif_ord_codice_funzione;

		accreditoGruppoCode:=codAccreRec.accredito_gruppo_code;
	    --raise notice 'accreditoGruppoCode=% ',accreditoGruppoCode;

        if MDPRec.iban is not null and length(MDPRec.iban)>2  then
        	select distinct 1 into isPaeseSepa
            from siac_t_sepa sepa
            where sepa.sepa_iso_code=substring(upper(MDPRec.iban) from 1 for 2)
            and   sepa.ente_proprietario_id=enteProprietarioId
            and   sepa.data_cancellazione is null
      	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));
        end if;
     end if;


     -- <abi_beneficiario>
 	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;

	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 6 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;


                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_abi_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
	 end if;

     -- <cab_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
         flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
 	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 11 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cab_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <numero_conto_corrente_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;
                    if tipoMDPCCP is null or tipoMDPCCP='' then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 16 for 12);
                    end if;

                    if tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode and
                       coalesce(MDPRec.contocorrente,NVL_STR)!=NVL_STR then
                       flussoElabMifValore:=lpad(MDPRec.contocorrente,NUM_DODICI,ZERO_PAD);
                    end if;

                    --raise notice 'numero_conto_corrente_beneficiario';
                    --raise notice 'tipoMDPCCP=% ',tipoMDPCCP;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cc_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <caratteri_controllo>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
	    flussoElabMifElabRec:=null;
    	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 3 for 2);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_ctrl_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;
     end if;


     -- <codice_cin>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 5 for 1);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cin_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <codice_paese>
	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 1 for 2);
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cod_paese_benef:=flussoElabMifValore;
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true and statoDelegatoCredEff=false then -- se CSI IBAN non riporta dati del beneficiario quindi omettiamo codice_paese
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                        if statoDelegatoCredEff=true then
--	                        mifFlussoOrdinativoRec.mif_ord_stato_del:=flussoElabMifValore;
                            -- 24.01.2018 Sofia jira siac-5765
                            mifFlussoOrdinativoRec.mif_ord_stato_del:=mifFlussoOrdinativoRec.mif_ord_stato_benef;
                            mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
       end if;
     end if;


     -- extra sepa
     -- <denominazione_banca_destinataria>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true and isPaeseSepa is null then
		 flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.banca_denominazione is not null  then
                       	flussoElabMifValore:=MDPRec.banca_denominazione;
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_denom_banca_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;
     -- </piazzatura>

     -- sezione esteri sepa
     -- <sepa_credit_transfer>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and isPaeseSepa is not null then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     if flussoElabMifElabRec.flussoElabMifParam is not null then
                if paeseSepaTr is null then
	        	   	paeseSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if accreditoGruppoSepaTr is null then
	            	accreditoGruppoSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if SepaTr is null then
		            SepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;

    	        if accreditoGruppoSepaTr is not null and SepaTr is not null and paeseSepaTr is not null then
	    	        sepaCreditTransfer:=true;
            	end if;
             end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <iban>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           	mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr:=MDPRec.iban;

                   -- 01.10.2018 Sofia SIAC-6421
                   if coalesce(substring(upper(MDPRec.iban) from 1 for 2),'')!='' then
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true and statoDelegatoCredEff=false then
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=substring(upper(MDPRec.iban) from 1 for 2);
                        end if;
                        if statoDelegatoCredEff=true then
                            mifFlussoOrdinativoRec.mif_ord_stato_del:=mifFlussoOrdinativoRec.mif_ord_stato_benef;
                            mifFlussoOrdinativoRec.mif_ord_stato_benef:=substring(upper(MDPRec.iban) from 1 for 2);
                        end if;
                    end if;

        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <bic>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.bic is not null and
                   MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr:=MDPRec.bic;
        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;
     mifCountRec:=mifCountRec+5;
     -- </sepa_credit_transfer>


     -- <causale> ancora informazioni_beneficiario
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifValoreDesc:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'causale mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura CUP-CIG.';
            	if cupCausAttr is null then
	            	cupCausAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if cigCausAttr is null then
	                cigCausAttr:=trim (both ' '	 from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;

                if coalesce(cupCausAttr,NVL_STR)!=NVL_STR  and cupCausAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupCausAttr||'.';
                	select attr.attr_id into cupCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;

                if coalesce(cigCausAttr,NVL_STR)!=NVL_STR and cigCausAttrId is null then

                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigCausAttr||'.';
                	select attr.attr_id into cigCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;


                if cupCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

                if cigCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValoreDesc
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValoreDesc,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValoreDesc
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

            end if;
            -- cup
			if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
			       	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=cupCausAttr||' '||flussoElabMifValore;

            end if;
            -- cig
			if coalesce(flussoElabMifValoreDesc,NVL_STR)!=NVL_STR  then
                	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
                      trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||
                           ' '||cigCausAttr||' '||flussoElabMifValoreDesc);
            end if;


			mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
      			replace(replace(substring(trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||' '||mifOrdinativoIdRec.mif_ord_desc )
	                            from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

--			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;


	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <sospeso>
     -- <numero_provvisorio>
     -- <importo_provvisorio>
     mifCountRec:=mifCountRec+2;

	 -- <ritenuta>
     -- <importo_ritenute>
     -- <numero_reversale>
     -- <progressivo_versante>
     mifCountRec:=mifCountRec+3;

	 -- <informazioni_aggiuntive>

     -- <lingua>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null then
        		mifFlussoOrdinativoRec.mif_ord_lingua:=flussoElabMifElabRec.flussoElabMifDef;

--                raise notice 'LINGUA def % %',flussoElabMifElabRec.flusso_elab_mif_campo,flussoElabMifElabRec.flussoElabMifDef;
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;


    -- <riferimento_documento_esterno>
    mifCountRec:=mifCountRec+1;
    if tipoPagamRec is not null then
    	flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codResult:=null;

        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;
    	if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null and
                   flussoElabMifElabRec.flussoElabMifParam is not null then

				    -- 30.07.2018 Sofia siac-6202
                    if coalesce(trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5)),'')!='' then

                       select 1 into codResult
                       from siac_r_ordinativo_class rc, siac_t_class c , siac_d_class_tipo tipo
                       where tipo.ente_proprietario_id=enteProprietarioId
                       and   tipo.classif_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))
                       and   c.classif_tipo_id=tipo.classif_tipo_id
                       and   rc.classif_id=c.classif_id
                       and   rc.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                       and   rc.data_cancellazione is null
                       and   rc.validita_fine is null;

                       if codResult is not null then
		                   select * into flussoElabMifValore
                           from fnc_mif_ordinativo_splus_get_mese(mifOrdinativoIdRec.mif_ord_data_emissione);
                       end if;

                       if coalesce(flussoElabMifValore,'')!='' then
                       	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,3))
                                             ||' '||flussoElabMifValore;
                       end if;
                    end if;
                    -- 30.07.2018 Sofia siac-6202


                    -- modalita accredito=STI - STIPENDI
                    if coalesce(flussoElabMifValore,'')='' and -- 30.07.2018 Sofia siac-6202
                       codAccreRec.accredito_tipo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3)) then
                           flussoElabMifValore:=
                             trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                    end if;

                    if  coalesce(flussoElabMifValore,'')='' and -- 30.07.2018 Sofia siac-6202
                        tipoPagamRec.descTipoPagamento in
                        (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)),
                         trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                        ) then
		                flussoElabMifValore:=tipoPagamRec.descTipoPagamento;
                    end if;

                    -- 23.01.2018 Sofia jira siac-5765
			        if coalesce(flussoElabMifValore,'')='' and -- 30.07.2018 Sofia siac-6202
                       codAccreRec.accredito_gruppo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4)) and
                           MDPRec.contocorrente is not null and MDPRec.contocorrente!=''
                            then
                           flussoElabMifValore:=MDPRec.contocorrente;
                    end if;
                    -- 23.01.2018 Sofia jira siac-5765

                    if coalesce(flussoElabMifValore,'')='' and tipoPagamRec.defRifDocEsterno=true then
                        flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                    end if;

                    if coalesce(flussoElabMifValore,'')!='' then
	                    mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifValore;
                    end if;
		        end if;
			else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if;
    	end if;
    end if;
    -- </informazioni_aggiuntive>

    -- <sostituzione_mandato>

    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

    end if;

   mifCountRec:=mifCountRec+3;
   if ordSostRec is not null then
   		 flussoElabMifElabRec:=null;
   		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-2];
	     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-2
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         -- <numero_mandato_da_sostituire>
      	 if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;

      	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	   if flussoElabMifElabRec.flussoElabMifElab=true then
--        		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=ordSostRec.ordNumeroSostituto::varchar;
	    	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     	end if;
         end if;

     	-- <progressivo_beneficiario_da_sostuire>
     	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

        -- <esercizio_mandato_da_sostituire>
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg:=ordSostRec.ordAnnoSostituto;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

     end if;


     -- <dati_a_disposizione_ente_beneficiario> facoltativo non valorizzato
     -- </informazioni_beneficiario>

     -- <dati_a_disposizione_ente_mandato>
	 -- <codice_distinta>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
      		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta [siac_d_distinta].';
            	select  d.dist_code into flussoElabMifValore
                from siac_d_distinta d
                where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
            end if;

            if flussoElabMifValore is not null then
              	mifFlussoOrdinativoRec.mif_ord_codice_distinta:=flussoElabMifValore;
            end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	 end if;

     -- <atto_contabile>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoAllRag is null then
            		attoAmmTipoAllRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmStrTipoRag is null then
                	attoAmmStrTipoRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         		end if;

                if attoAmmTipoAllRag is not null and  attoAmmStrTipoRag is not null then

                 flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                 										          attoAmmTipoAllRag,attoAmmStrTipoRag,
                                                                  dataElaborazione, dataFineVal);

                end if;
          	end if;

            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

      -- 15.01.2018 Sofia SIAC-5765
      -- <codice_operatore>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  flussoElabMifValoreDesc:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- </dati_a_disposizione_ente_mandato>

     -- </mandato>
/**/
        /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
		raise notice 'numero_mandato= %',mifFlussoOrdinativoRec.mif_ord_numero;
        raise notice 'data_mandato= %',mifFlussoOrdinativoRec.mif_ord_data;
        raise notice 'importo_mandato= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

		 strMessaggio:='Inserimento mif_t_ordinativo_spesa per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_spesa
        (
  		-- mif_ord_data_elab, def now
  		 mif_ord_flusso_elab_mif_id,
 		 mif_ord_bil_id,
 		 mif_ord_ord_id,
  		 mif_ord_anno,
  		 mif_ord_numero,
  		 mif_ord_codice_funzione,
  		 mif_ord_data,
  		 mif_ord_importo,
  		 mif_ord_flag_fin_loc,
  		 mif_ord_documento,
  		 mif_ord_bci_tipo_ente_pag,
  		 mif_ord_bci_dest_ente_pag,
  		 mif_ord_bci_conto_tes,
 		 mif_ord_estremi_attoamm,
         mif_ord_resp_attoamm,
         mif_ord_uff_resp_attomm,
  		 mif_ord_codice_abi_bt,
  		 mif_ord_codice_ente,
  		 mif_ord_desc_ente,
  		 mif_ord_codice_ente_bt,
  		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
  		 mif_ord_id_flusso_oil,
  		 mif_ord_data_creazione_flusso,
  		 mif_ord_anno_flusso,
 		 mif_ord_codice_struttura,
  		 mif_ord_ente_localita,
  		 mif_ord_ente_indirizzo,
 		 mif_ord_codice_raggrup,
  		 mif_ord_progr_benef,
         mif_ord_progr_dest,
  		 mif_ord_bci_conto,
  		 mif_ord_bci_tipo_contabil,
  		 mif_ord_class_codice_cge,
  		 mif_ord_class_importo,
  		 mif_ord_class_codice_cup,
  		 mif_ord_class_codice_gest_prov,
  		 mif_ord_class_codice_gest_fraz,
  		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
  		 mif_ord_articolo,
  		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
  		 mif_ord_gestione,
  		 mif_ord_anno_res,
  		 mif_ord_importo_bil,
  		 mif_ord_stanz,
    	 mif_ord_mandati_stanz,
  		 mif_ord_disponibilita,
  		 mif_ord_prev,
  		 mif_ord_mandati_prev,
  		 mif_ord_disp_cassa,
  		 mif_ord_anag_benef,
  		 mif_ord_indir_benef,
  		 mif_ord_cap_benef,
  		 mif_ord_localita_benef,
  		 mif_ord_prov_benef,
         mif_ord_stato_benef,
  		 mif_ord_partiva_benef,
  		 mif_ord_codfisc_benef,
  		 mif_ord_anag_quiet,
  		 mif_ord_indir_quiet,
  		 mif_ord_cap_quiet,
  		 mif_ord_localita_quiet,
  		 mif_ord_prov_quiet,
  		 mif_ord_partiva_quiet,
  		 mif_ord_codfisc_quiet,
	     mif_ord_stato_quiet,
  		 mif_ord_anag_del,
         mif_ord_indir_del,
         mif_ord_cap_del,
         mif_ord_localita_del,
         mif_ord_prov_del,
  		 mif_ord_codfisc_del,
         mif_ord_partiva_del,
         mif_ord_stato_del,
  		 mif_ord_invio_avviso,
  		 mif_ord_abi_benef,
  		 mif_ord_cab_benef,
  		 mif_ord_cc_benef_estero,
 		 mif_ord_cc_benef,
         mif_ord_ctrl_benef,
  		 mif_ord_cin_benef,
  		 mif_ord_cod_paese_benef,
  		 mif_ord_denom_banca_benef,
  		 mif_ord_cc_postale_benef,
  		 mif_ord_swift_benef,
  		 mif_ord_iban_benef,
         mif_ord_sepa_iban_tr,
         mif_ord_sepa_bic_tr,
         mif_ord_sepa_id_end_tr,
  		 mif_ord_bollo_esenzione,
  		 mif_ord_bollo_carico,
  		 mif_ordin_bollo_caus_esenzione,
  		 mif_ord_commissioni_carico,
         mif_ord_commissioni_esenzione,
  		 mif_ord_commissioni_importo,
         mif_ord_commissioni_natura,
  		 mif_ord_pagam_tipo,
  		 mif_ord_pagam_code,
  		 mif_ord_pagam_importo,
  		 mif_ord_pagam_causale,
  		 mif_ord_pagam_data_esec,
  		 mif_ord_lingua,
  		 mif_ord_rif_doc_esterno,
  		 mif_ord_info_tesoriere,
  		 mif_ord_flag_copertura,
  		 mif_ord_num_ord_colleg,
  		 mif_ord_progr_ord_colleg,
  		 mif_ord_anno_ord_colleg,
  		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
  		 mif_ord_descri_estesa_cap,
  		 mif_ord_siope_codice_cge,
  		 mif_ord_siope_descri_cge,
         mif_ord_codice_ente_ipa,
         mif_ord_codice_ente_istat,
         mif_ord_codice_ente_tramite,
         mif_ord_codice_ente_tramite_bt,
	     mif_ord_riferimento_ente,
         mif_ord_importo_benef,
         mif_ord_pagam_postalizza,
         mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
         mif_ord_class_cig,
         mif_ord_class_motivo_nocig,
         mif_ord_class_missione,
         mif_ord_class_programma,
         mif_ord_class_economico,
         mif_ord_class_importo_economico,
         mif_ord_class_transaz_ue,
         mif_ord_class_ricorrente_spesa,
         mif_ord_class_cofog_codice,
         mif_ord_class_cofog_importo,
         mif_ord_codice_distinta,
         mif_ord_codice_atto_contabile,
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
	  	 --:mif_ord_data_elab,
  		 flussoElabMifLogId, --idElaborazione univoco
  		 mifOrdinativoIdRec.mif_ord_bil_id,
  		 mifOrdinativoIdRec.mif_ord_ord_id,
  		 mifOrdinativoIdRec.mif_ord_ord_anno,
  		 mifFlussoOrdinativoRec.mif_ord_numero,
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione,
  		 mifFlussoOrdinativoRec.mif_ord_data,
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end),
         mifFlussoOrdinativoRec.mif_ord_importo,
 		 mifFlussoOrdinativoRec.mif_ord_flag_fin_loc,
  	     mifFlussoOrdinativoRec.mif_ord_documento,
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_ente_pag,
 	 	 mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag,
 		 mifFlussoOrdinativoRec.mif_ord_bci_conto_tes,
 		 mifFlussoOrdinativoRec.mif_ord_estremi_attoamm,
         mifFlussoOrdinativoRec.mif_ord_resp_attoamm,
  		 mifFlussoOrdinativoRec.mif_ord_uff_resp_attomm,
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,
 		 mifFlussoOrdinativoRec.mif_ord_codice_ente,
		 mifFlussoOrdinativoRec.mif_ord_desc_ente,
  		 mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,
 		 mifFlussoOrdinativoRec.mif_ord_anno_esercizio,
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
  		flussoElabMifOilId, --idflussoOil
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,
 		mifFlussoOrdinativoRec.mif_ord_codice_raggrup,
 		mifFlussoOrdinativoRec.mif_ord_progr_benef,
 		mifFlussoOrdinativoRec.mif_ord_progr_dest,
 		mifFlussoOrdinativoRec.mif_ord_bci_conto,
  		mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_class_importo,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cup,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz,
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio,
        mifFlussoOrdinativoRec.mif_ord_capitolo,
  		mifFlussoOrdinativoRec.mif_ord_articolo,
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil,
		mifFlussoOrdinativoRec.mif_ord_gestione,
 		mifFlussoOrdinativoRec.mif_ord_anno_res,
 		mifFlussoOrdinativoRec.mif_ord_importo_bil,
        mifFlussoOrdinativoRec.mif_ord_stanz,
    	mifFlussoOrdinativoRec.mif_ord_mandati_stanz,
  		mifFlussoOrdinativoRec.mif_ord_disponibilita,
		mifFlussoOrdinativoRec.mif_ord_prev,
  		mifFlussoOrdinativoRec.mif_ord_mandati_prev,
  		mifFlussoOrdinativoRec.mif_ord_disp_cassa,
        mifFlussoOrdinativoRec.mif_ord_anag_benef,
  		mifFlussoOrdinativoRec.mif_ord_indir_benef,
		mifFlussoOrdinativoRec.mif_ord_cap_benef,
 		mifFlussoOrdinativoRec.mif_ord_localita_benef,
  		mifFlussoOrdinativoRec.mif_ord_prov_benef,
        mifFlussoOrdinativoRec.mif_ord_stato_benef,
 		mifFlussoOrdinativoRec.mif_ord_partiva_benef,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_benef,
  		mifFlussoOrdinativoRec.mif_ord_anag_quiet,
        mifFlussoOrdinativoRec.mif_ord_indir_quiet,
  		mifFlussoOrdinativoRec.mif_ord_cap_quiet,
 		mifFlussoOrdinativoRec.mif_ord_localita_quiet,
  		mifFlussoOrdinativoRec.mif_ord_prov_quiet,
 		mifFlussoOrdinativoRec.mif_ord_partiva_quiet,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_quiet,
        mifFlussoOrdinativoRec.mif_ord_stato_quiet,
 		mifFlussoOrdinativoRec.mif_ord_anag_del,
        mifFlussoOrdinativoRec.mif_ord_indir_del,
        mifFlussoOrdinativoRec.mif_ord_cap_del,
 		mifFlussoOrdinativoRec.mif_ord_localita_del,
 		mifFlussoOrdinativoRec.mif_ord_prov_del,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_del,
 		mifFlussoOrdinativoRec.mif_ord_partiva_del,
        mifFlussoOrdinativoRec.mif_ord_stato_del,
 		mifFlussoOrdinativoRec.mif_ord_invio_avviso,
 		mifFlussoOrdinativoRec.mif_ord_abi_benef,
 		mifFlussoOrdinativoRec.mif_ord_cab_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef_estero,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef,
 		mifFlussoOrdinativoRec.mif_ord_ctrl_benef,
 		mifFlussoOrdinativoRec.mif_ord_cin_benef,
 		mifFlussoOrdinativoRec.mif_ord_cod_paese_benef,
  		mifFlussoOrdinativoRec.mif_ord_denom_banca_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_postale_benef,
  		mifFlussoOrdinativoRec.mif_ord_swift_benef,
  		mifFlussoOrdinativoRec.mif_ord_iban_benef,
        mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
  		mifFlussoOrdinativoRec.mif_ord_bollo_carico,
  		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione,
 		mifFlussoOrdinativoRec.mif_ord_commissioni_carico,
        mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione,
		mifFlussoOrdinativoRec.mif_ord_commissioni_importo,
        mifFlussoOrdinativoRec.mif_ord_commissioni_natura,
  		mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_code,
	    mifFlussoOrdinativoRec.mif_ord_pagam_importo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_causale,
 		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
	    mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_importo_benef,
        mifFlussoOrdinativoRec.mif_ord_pagam_postalizza,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc,
        mifFlussoOrdinativoRec.mif_ord_class_cig,
        mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig,
        mifFlussoOrdinativoRec.mif_ord_class_missione,
        mifFlussoOrdinativoRec.mif_ord_class_programma,
        mifFlussoOrdinativoRec.mif_ord_class_economico,
        mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
        mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
        mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_codice,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_importo,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
        mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile,
        now(),
        enteProprietarioId,
        loginOperazione
   )
   returning mif_ord_id into mifOrdSpesaId;




 -- dati fatture da valorizzare se ordinativo commerciale
 -- @@@@ sicuramente da completare
 -- <fattura_siope>
 if isGestioneFatture = true and isOrdCommerciale=true then
  flussoElabMifElabRec:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
  titoloCap:=null;
  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa.';

  /*if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
  else
   if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
   end if;
  end if;*/
  -- 20.02.2018 Sofia JIRA siac-5849
  select oil.oil_natura_spesa_desc into titoloCap
  from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r
  where r.oil_natura_spesa_titolo_id=mifOrdinativoIdRec.mif_ord_titolo_id
  and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
  and   r.data_cancellazione is null
  and   r.validita_fine is null;
  if titoloCap is null then titoloCap:=defNaturaPag; end if;
   -- 26.02.2018 Sofia JIRA siac-5849 - inclusione delle note credito  per ordinativi di pagamento
  titoloCap:=titoloCap||'|N'; -- 08.05.2018 Sofia siac-6137
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Inizio ciclo.';
  ordRec:=null;
  for ordRec in
  (select * from fnc_mif_ordinativo_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											         numeroDocs::integer,
                                                     tipoDocs,
                                                     docAnalogico,
                                                     attrCodeDataScad,
                                                     titoloCap,
                                                     enteOilRec.ente_oil_codice_pcc_uff,
		   		                        	         enteProprietarioId,
	            		                             dataElaborazione,dataFineVal)
  )
  loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento fatture '
                       ||' in mif_t_ordinativo_spesa_documenti '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         insert into  mif_t_ordinativo_spesa_documenti
         ( mif_ord_id,
		   mif_ord_documento,
           mif_ord_doc_codice_ipa_ente,
	       mif_ord_doc_tipo,
           mif_ord_doc_tipo_a,
		   mif_ord_doc_id_lotto_sdi,
		   mif_ord_doc_tipo_analog,
		   mif_ord_doc_codfisc_emis,
		   mif_ord_doc_anno,
	       mif_ord_doc_numero,
	       mif_ord_doc_importo,
	       mif_ord_doc_data_scadenza,
	       mif_ord_doc_motivo_scadenza,
	       mif_ord_doc_natura_spesa,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          --ordRec.numero_fattura_siope,
          'S', -- 07.06.2018 Sofia SIAC-6228
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          ordRec.importo_siope,
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          now(),
          enteProprietarioId,
          loginOperazione
         );
  end loop;
 end if;




   -- <ritenuta>
   -- <importo_ritenuta>
   -- <numero_reversale>
   -- <progressivo_reversale>

   if  isRitenutaAttivo=true then
    ritenutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  ritenute'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ritenutaRec in
    (select *
     from fnc_mif_ordinativo_ritenute(mifOrdinativoIdRec.mif_ord_ord_id,
         	 					      tipoRelazRitOrd,tipoRelazSubOrd,tipoRelazSprOrd,
                                      tipoOnereIrpefId,tipoOnereInpsId,
                                      tipoOnereIrpegId,
									  ordStatoCodeAId,ordDetTsTipoId,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento ritenuta'
                       ||' in mif_t_ordinativo_spesa_ritenute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ritenute
        (mif_ord_id,
  		 mif_ord_rit_tipo,
 		 mif_ord_rit_importo,
 		 mif_ord_rit_numero,
  		 mif_ord_rit_ord_id,
 		 mif_ord_rit_progr_rev,
  		 validita_inizio,
		 ente_proprietario_id,
		 login_operazione)
        values
        (mifOrdSpesaId,
         tipoRitenuta,
         ritenutaRec.importoRitenuta,
         ritenutaRec.numeroRitenuta,
         ritenutaRec.ordRitenutaId,
         progrRitenuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );

    end loop;
   end if;

   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
  if  isRicevutaAttivo=true then
    ricevutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  provvisori'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   ricevuta'
                       ||' in mif_t_ordinativo_spesa_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ricevute
        (mif_ord_id,
	     mif_ord_ric_anno,
	     mif_ord_ric_numero,
	     mif_ord_provc_id,
		 mif_ord_ric_importo,
	     validita_inizio,
		 ente_proprietario_id,
	     login_operazione
        )
        values
        (mifOrdSpesaId,
         ricevutaRec.annoRicevuta,
         ricevutaRec.numeroRicevuta,
         ricevutaRec.provRicevutaId,
         ricevutaRec.importoRicevuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );
    end loop;
  end if;

  numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;
 end loop;

/* if comPccAttrId is not null and numeroOrdinativiTrasm>0 then
   	   strMessaggio:='Inserimento Registro PCC.';
	   insert into siac_t_registro_pcc
	   (doc_id,
    	subdoc_id,
	    pccop_tipo_id,
    	ordinativo_data_emissione,
	    ordinativo_numero,
    	rpcc_quietanza_data,
        rpcc_quietanza_importo,
	    soggetto_id,
    	validita_inizio,
	    ente_proprietario_id,
    	login_operazione
	    )
    	(
         with
         mif as
         (select m.mif_ord_ord_id ord_id, m.mif_ord_soggetto_id soggetto_id,
                 ord.ord_emissione_data , ord.ord_numero
          from mif_t_ordinativo_spesa_id m, siac_t_ordinativo ord
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ord.ord_id=m.mif_ord_ord_id
         ),
         tipodoc as
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
         doc as
         (select distinct m.mif_ord_ord_id ord_id, subdoc.doc_id , subdoc.subdoc_id, subdoc.subdoc_importo, doc.doc_tipo_id
	      from  mif_t_ordinativo_spesa_id m, siac_t_ordinativo_ts ts, siac_r_subdoc_ordinativo_ts rsubdoc,
                siac_t_subdoc subdoc, siac_t_doc doc
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ts.ord_id=m.mif_ord_ord_id
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
         )
         select
          doc.doc_id,
          doc.subdoc_id,
          pccOperazTipoId,
--          mif.ord_emissione_data,
--		  mif.ord_emissione_data+(1*interval '1 day'),
		  mif.ord_emissione_data,
          mif.ord_numero,
          dataElaborazione,
          doc.subdoc_importo,
          mif.soggetto_id,
          now(),
          enteProprietarioId,
          loginOperazione
         from mif, doc,tipodoc
         where mif.ord_id=doc.ord_id
         and   tipodoc.doc_tipo_id=doc.doc_tipo_id
        );
   end if;*/


   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;


   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';

   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_spesa')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di spesa.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;


    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
       	  codiceRisultato:=-1;
    	end if;

        numeroOrdinativiTrasm:=0;
		messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when NO_DATA_FOUND THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then


            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;
        return;
	when others  THEN
		raise notice '% % Errore DB % % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||' '||mifCountRec||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;

        else
        	flussoElabMifId:=null;
        end if;

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;