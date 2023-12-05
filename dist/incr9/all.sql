/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Sofia SIAC-5231 - INIZIO

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='C'
from mif_d_flusso_elaborato_tipo tipo
where tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code = 'invio_avviso'
and   mif.flusso_elab_mif_default is not null
and   mif.flusso_elab_mif_default='B';

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa (
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
-- ordinativoRec record;

 mifFlussoOrdDispeBenefRec mif_t_ordinativo_spesa_disp_ente_benef%rowtype;

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
 datiNascitaRec record;
 oneriCauRec record;
 tipoPagamRec record;
 ritenutaRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;
 ordRec record;

 -- 26.01.2016 SofiaJira
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

 -- 01.03.2016 Sofia JIRA-SIAC-3138-ABI36
/* isAccreTipoF24 boolean:=false;
 accreTipoF24 varchar(100):=null; */
 -- 01.03.2016 Sofia JIRA-SIAC-3138-ABI36

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
 avvisoTipoClassCode varchar(50):=null;
 avvisoTipoClassCodeId integer:=null;
 isMDPCo boolean:=false;
 isInvioAvviso boolean:=false;
 isOrdACopertura boolean:=false;
 isOrdPiazzatura boolean:=false;
 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 soggettoSedeSecId integer:=null;
 soggettoQuietId integer:=null;
 soggettoQuietRifId integer:=null;
 accreditoGruppoCode varchar(15):=null;
 avvisoBenef varchar(1):=null;
 avvisoBenQuiet  varchar(1):=null;
 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;
 ordRelazCodeTipoId integer :=null;
 ordDetTsTipoId integer :=null;
 ordSedeSecRelazTipoId integer:=null;
 ordCsiRelazTipoId  integer:=null;
 capOrigAttrId integer:=null;
 noteOrdAttrId integer:=null;
 isPaeseSepa integer:=null;
 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 isOrdBolloEsente boolean:=false;
 ordDataScadenza timestamp:=null;
 ordCsiRelazTipo varchar(20):=null;
 ambitoFinId integer:=null;
 anagraficaBenefCBI varchar(500):=null;

 isDefAnnoRedisuo  varchar(5):=null;
 -- ritenute
 tipoRelazRitOrd varchar(10):=null;
 tipoRelazSprOrd varchar(10):=null;
 tipoRelazSubOrd varchar(10):=null;
 tipoRitenuta varchar(10):=null;
 progrRitenuta  varchar(10):=null;
 isRitenutaAttivo boolean:=false;
 tipoOnereIrpefId integer:=null;
 tipoOnereInpsId integer:=null;
 tipoOnereIrpef varchar(10):=null;
 tipoOnereInps varchar(10):=null;

 -- 30.08.2016 Sofia HD-INC000001208683
 tipoOnereIrpegId integer:=null;
 tipoOnereIrpeg varchar(10):=null;

 isRicevutaAttivo boolean:=false;
 programmaCodeTipo varchar(50):=null;

 programmaCodeTipoId integer :=null;
 titoloUscitaCodeTipoId integer :=null;
 famTitSpeMacroAggrCodeId integer:=null;

 famMissProgrCode VARCHAR(50):=null;
 famMissProgrCodeId integer:=null;
 programmaId integer :=null;
 titoloUscitaId integer:=null;
 valBolloEsente varchar(10):=null;
 valBolloNonEsente varchar(10):=null;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;
 codiceCofogCodeTipo  VARCHAR(50):=null;
 codiceCofogCodeTipoId integer:=null;
 codiceTrib varchar(50) :=null;
 codiceTribId integer:=null;
 codicePaeseIT varchar(50):=null;
 codiceAccreCB varchar(50):=null;
 codiceAccreCO varchar(50):=null;
 codiceSepa varchar(50):=null;
 eventoTipoCodeId integer:=null;
 splitEsenteCode varchar(50):=null;
 splitEsenteCodeId integer:=null;
 codiceFinanzTipo varchar(50):=null;
 codiceFinanzTipoId integer :=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;

 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;

 -- 23.03.2016 Sofia - JIRA-SIAC-3032
 classifTipoCodeFraz    varchar(50):=null;
 classifTipoCodeFrazVal varchar(50):=null;
 classifTipoCodeFrazId   integer:=null;

 -- 14.03.2016 Sofia ABI36
 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;

 -- 10.02.2017 Sofia SIAC-4423-CmTo
 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;
 valFruttiferoClassCode   varchar(100):=null;
 valFruttiferoClassCodeId INTEGER:=null;
 valFruttiferoClassCodeSI varchar(100):=null;
 valFruttiferoCodeSI varchar(100):=null;
 valFruttiferoClassCodeNO varchar(100):=null;
 valFruttiferoCodeNO varchar(100):=null;

 -- 23.02.2017 Sofia HD-INC000001582991
 ordCsiCOTipo varchar(50):=null;

-- ordinativoTsDetTipoId integer:=null;
 movgestTsTipoSubId integer:=null;
 isGestioneQuoteOK boolean:=false;

 isGestioneFatture boolean:=false;
 numeroDocs varchar(10):=null;
 tipoDocs varchar(50):=null;

 impostaInfoTes boolean:=false;  -- 01.09.2016 Sofia HD-INC000001204673

 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false; -- 20.01.2016 Sofia ABI36

 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 NVL_STR               CONSTANT VARCHAR:='';
 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;

 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TIPO_A CONSTANT  varchar :='A';

 ORD_RELAZ_SEDE_SEC CONSTANT  varchar :='SEDE_SECONDARIA';
 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 CAP_ORIGINE_ATTR CONSTANT  varchar :='numeroCapitoloOrigine';
 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';


 PROGRAMMA               CONSTANT varchar:='PROGRAMMA';
 TITOLO_SPESA            CONSTANT varchar:='TITOLO_SPESA';
 FAM_TIT_SPE_MACROAGGREG CONSTANT varchar:='Spesa - TitoliMacroaggregati';

 FUNZIONE_CODE_I CONSTANT  varchar :='I'; -- inserimenti
 FUNZIONE_CODE_S CONSTANT  varchar :='S'; -- sostituzioni senza trasmissione ( ma da capire se ha senso )
 FUNZIONE_CODE_N CONSTANT  varchar :='N'; -- annullamenti prima di trasmissione

 FUNZIONE_CODE_A CONSTANT  varchar :='A'; -- annullamenti dopo trasmissione
 FUNZIONE_CODE_VB CONSTANT  varchar :='VB'; -- spostamenti dopo trasmissione


 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 NUM_DODICI CONSTANT integer:=12; -- JIRA SIAC-2999 Sofia 09.02.2016
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF';


 COM_PCC_ATTR  CONSTANT  varchar :='flagComunicaPCC';
 PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';
 comPccAttrId integer:=null;
 pccOperazTipoId integer:=null;

 SEPARATORE     CONSTANT  varchar :='|';

 --mifFlussoElabTypeRec record;
 --flussoElabMifElabRec record;
 mifFlussoElabMifArr flussoElabMifRecType[];


 mifCountRec integer:=1;
 mifCountTmpRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 -- 16.02.2016 Sofia JIRA-SIAC-3035
 cigCausAttrId INTEGER:=null;
 cupCausAttrId INTEGER:=null;
 cigCausAttr   varchar(10):=null;
 cupCausAttr   varchar(10):=null;


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

 isTransElemAttiva boolean:=false;

 datiDispEnteBenef boolean:=false; --19.01.2016 Sofia ABI3



 -- 21.01.2016 Sofia ABI36 - sepa_credit_transfer
 sepaCreditTransfer boolean:=false;
 accreditoGruppoSepaTr varchar(10):=null;
 SepaTr varchar(10):=null;
 paeseSepaTr varchar(10):=null;

 commissioneCode varchar(50):=null; -- 05.02.2016 Sofia

 tipoEsercizio varchar(50):=null; -- 11.01.2016 Sofia

 statoBeneficiario boolean :=false; -- 18.01.2016 Sofia ABI36
 statoDelegatoAbi36 boolean :=false; -- 08.11.2016 Sofia ABI36 JIRA-SIAC-4158

 -- JIRA-SIAC-4278 28.12.2016 Sofia
 bavvioFrazAttr boolean :=false;
 dataAvvioFrazAttr timestamp:=null;
 attrfrazionabile VARCHAR(50):=null;

 -- 29.12.2016 Sofia SIAC-4139
 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;

 FLUSSO_MIF_ELAB_CAST_CASSA     CONSTANT integer:=52; -- 11.01.2016 Sofia castelletti di cassa
 FLUSSO_MIF_ELAB_CC_POSTALE     CONSTANT integer:=87;
 FLUSSO_MIF_ELAB_TIPO_RITENUTA  CONSTANT integer:=93; -- 11.01.2016
 FLUSSO_MIF_ELAB_FLAG_COPERTURA CONSTANT integer:=122;
 FLUSSO_MIF_ELAB_NUM_RICEVUTA   CONSTANT integer:=123;
 FLUSSO_MIF_ELAB_IMP_RICEVUTA   CONSTANT integer:=124;
 FLUSSO_MIF_ELAB_CAP_ORIGINE    CONSTANT integer:=129; -- primo elemento di dati a disposizione ente
 FLUSSO_MIF_ELAB_NUM_QUOTA_MAND CONSTANT integer:=165;
 FLUSSO_MIF_ELAB_CODICE_CGE     CONSTANT integer:=182;
 FLUSSO_MIF_ELAB_DESCRI_CGE     CONSTANT integer:=183;
 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=177;
 FLUSSO_MIF_ELAB_TBR            CONSTANT integer:=184;
 FLUSSO_MIF_ELAB_STATO_BENEF    CONSTANT integer:=185; -- 18.01.2016 Sofia ABI36
 FLUSSO_MIF_ELAB_DISP_ABI36     CONSTANT integer:=186; -- 19.01.2016 Sofia ABI36 dati_a_disposizione_ente_beneficiario
 FLUSSO_MIF_ELAB_SEPA_CREDIT_T  CONSTANT integer:=194; -- 21.01.2016 Sofia ABI36 sepa_credit_transfer
 FLUSSO_MIF_ELAB_NATURA_PAGAM   CONSTANT integer:=198; -- 16.02.2016 Sofia ABI36
 FLUSSO_MIF_ELAB_STATO_DELEGATO CONSTANT integer:=199; -- 08.11.2016 Sofia ABI36 JIRA SIAC-4158

 NUMERO_DATI_DISP_ENTE          CONSTANT integer:=44;


BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    -- 25.05.2016 Sofia - JIRA-3619
    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di spesa al MIF.';

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
--    execute  'ANALYZE mif_t_flusso_elaborato;';
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
--    execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal)); 19.01.2017
   		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal)); 19.01.2017
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal)); 19.01.2017
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TS_DET_TIPO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal)); 19.01.2017
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordSedeSecRelazTipoId
        strMessaggio:='Lettura relazione sede secondaria  Code Id '||ORD_RELAZ_SEDE_SEC||'.';
        select ord_tipo.relaz_tipo_id into strict ordSedeSecRelazTipoId
        from siac_d_relaz_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.relaz_tipo_code=ORD_RELAZ_SEDE_SEC
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
-- 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal)); 19.01.2017
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
--		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal)); 19.01.2017
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
--		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));19.01.2017
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


    	-- programmaCodeTipoId
        strMessaggio:='Lettura programma_code_tipo_id  '||PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=PROGRAMMA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
--		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal)); 19.01.2017
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
--		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(fam.validita_fine,dataFineVal)); 19.01.2017
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));


    	-- titoloUscitaCodeTipoId
        strMessaggio:='Lettura titolo_spesa_code_tipo_id  '||TITOLO_SPESA||'.';
		select tipo.classif_tipo_id into strict titoloUscitaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TITOLO_SPESA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
--		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal));  19.01.2017
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- noteOrdAttrId
        strMessaggio:='Lettura noteOrdAttrId per attributo='||NOTE_ORD_ATTR||'.';
		select attr.attr_id into strict  noteOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ORD_ATTR
        and   attr.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
-- 	 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal)); 19.01.2017
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
        /*strMessaggio:='Lettura flusso MIF type per tipo '||MANDMIF_TIPO||'.';
		select * into strict  mifFlussoElabTypeRec
   		from mif_d_flusso_elaborato_type t
   	    where t.ente_proprietario_id=enteProprietarioId
   		  and t.flusso_elab_mif_tipo=flussoElabMifTipoId;*/

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
            -- Sofia introdotto con ABI36
            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;
            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;

        -- enteOilRec
        strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select * into strict enteOilRec
        from siac_t_ente_oil ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

		-- 11.02.2016 Sofia - gestione registroPcc per enti che non gestiscono quitanze
--		if enteOilRec.ente_oil_quiet_ord=true then -- 01.03.2016 Sofia va gestisto se il flag = false ente non gestisce quietanza
		if enteOilRec.ente_oil_quiet_ord=false then

  			-- comPccAttrId
	        strMessaggio:='Lettura comPccAttrId per attributo='||COM_PCC_ATTR||'.';
			select attr.attr_id into strict  comPccAttrId
	        from siac_t_attr attr
	        where attr.ente_proprietario_id=enteProprietarioId
	        and   attr.attr_code=COM_PCC_ATTR
	        and   attr.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
--	 	 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal)); 19.01.2017
   	 	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

            strMessaggio:='Lettura Id tipo operazine PCC='||PCC_OPERAZ_CPAG||'.';
			select pcc.pccop_tipo_id into strict pccOperazTipoId
		    from siac_d_pcc_operazione_tipo pcc
		    where pcc.ente_proprietario_id=enteProprietarioId
		    and   pcc.pccop_tipo_code=PCC_OPERAZ_CPAG;


        end if;

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
-- 			and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataFineVal)) 19.01.2017
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;

        -- 18.04.2016 Sofia - calcolo progressivo "distinta" per flusso MANDMIF
	    -- calcolo su progressi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
--        select prog.prog_value into flussoElabMifDistOilId
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
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1; -- 25.05.2016 Sofia - JIRA-3619
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


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I'
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_spesa_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_modpag_id,
     mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
     mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (-- 04.04.2016 Sofia - aggiunto filtro su mif_t_ordinativo_ritrasmesso x ritrasmissione
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
-- 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
  	    and  ord_stato.validita_fine is null -- SofiaData
        and  ord_stato.ord_stato_id=ordStatoCodeIId
        and  ord.ord_trasm_oil_data is null
        and  ord.ord_emissione_data<=dataElaborazione
        and  elem.ord_id=ord.ord_id
        and  elem.data_cancellazione is null
--	   	 and  date_trunc('day',dataElaborazione)>=date_trunc('day',elem.validita_inizio)
-- 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(elem.validita_fine,dataFineVal))
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
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

--     execute  'ANALYZE mif_t_ordinativo_spesa_id;';

      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
 	   mif_ord_soggetto_id, mif_ord_modpag_id,
 	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id, mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (-- 04.04.2016 Sofia - aggiunto filtro su mif_t_ordinativo_ritrasmesso x ritrasmissione
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
-- 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
  	      and  ord_stato.validita_fine is null -- SofiaData
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
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
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		   or (mifOrdRitrasmElabId is not null and exists
              (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

--	  execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
	   mif_ord_soggetto_id, mif_ord_modpag_id,
	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (-- 04.04.2016 Sofia - aggiunto filtro su mif_t_ordinativo_ritrasmesso x ritrasmissione
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
-- 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
  	     and  ord_stato.validita_fine is null -- SofiaData
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
	   );

--      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id,mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (-- 04.04.2016 Sofia - aggiunto filtro su mif_t_ordinativo_ritrasmesso x ritrasmissione
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
-- 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
  	      and  ord_stato.validita_fine is null -- SofiaData
          and  ord_stato.ord_stato_id=ordStatoCodeAId
          and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
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
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))

       );
--      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati )
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (-- 04.04.2016 Sofia - aggiunto filtro su mif_t_ordinativo_ritrasmesso x ritrasmissione
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
         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data
         and  ord.ord_spostamento_data<=dataElaborazione
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
        					--and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
 		 					--and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal)))
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
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );
--      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      -- aggiornamento mif_t_ordinativo_spesa_id per id

	  -- 11.01.2016 Sofia
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
/*      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id = (select s.soggetto_id from siac_r_ordinativo_soggetto s
                                 where s.ord_id=m.mif_ord_ord_id
                                   and s.data_cancellazione is null
                                   and s.validita_fine is null);*/

      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id=coalesce(s.soggetto_id,0)
      from siac_r_ordinativo_soggetto s
      where s.ord_id=m.mif_ord_ord_id
      and s.data_cancellazione is null
      and s.validita_fine is null;

--      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id.';

      -- modpag_id
      update mif_t_ordinativo_spesa_id m set  mif_ord_modpag_id=coalesce(s.modpag_id,0)
      from siac_r_ordinativo_modpag s
      where s.ord_id=m.mif_ord_ord_id
   	  and s.modpag_id is not null -- 05.02.2016 Sofia JIRA-2977
      and s.data_cancellazione is null
      and s.validita_fine is null;

      -- 05.02.2016 Sofia JIRA-2977
      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id [CSI].';
      update mif_t_ordinativo_spesa_id m set mif_ord_modpag_id=coalesce(rel.modpag_id,0)
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=m.mif_ord_ord_id
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      and rel.validita_fine is null
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);

--      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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

--     execute  'ANALYZE mif_t_ordinativo_spesa_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per liq_id.';

	 -- liq_id
	 update mif_t_ordinativo_spesa_id m
	 set mif_ord_liq_id = (select s.liq_id from siac_r_liquidazione_ord s
                            where s.sord_id = m.mif_ord_subord_id
                              and s.data_cancellazione is null
                              and s.validita_fine is null);
--     execute  'ANALYZE mif_t_ordinativo_spesa_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_ts_id = (select s.movgest_ts_id from siac_r_liquidazione_movgest s
                                   where s.liq_id = m.mif_ord_liq_id
                                     and s.data_cancellazione is null
                                     and s.validita_fine is null);
--     execute  'ANALYZE mif_t_ordinativo_spesa_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);
--     execute  'ANALYZE mif_t_ordinativo_spesa_id;';

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_spesa_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);
--     execute  'ANALYZE mif_t_ordinativo_spesa_id;';


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_liquidazione_atto_amm s
                                where s.liq_id = m.mif_ord_liq_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);
--    execute  'ANALYZE mif_t_ordinativo_spesa_id;';

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
--                                    where s.movgest_ts_id = m.mif_ord_movgest_id  -- 16.02.2016 Sofia
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);
--    execute  'ANALYZE mif_t_ordinativo_spesa_id;';

	-- mif_ord_programma_id
    -- mif_ord_programma_code
    -- mif_ord_programma_desc 11.01.2016 Sofia
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_programma_id mif_ord_programma_code mif_ord_programma_desc.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_programma_id,mif_ord_programma_code,mif_ord_programma_desc) = (class.classif_id,class.classif_code,class.classif_desc) -- 11.01.2016 Sofia
    from siac_r_bil_elem_class classElem, siac_t_class class
    where classElem.elem_id=m.mif_ord_elem_id
    and   class.classif_id=classElem.classif_id
    and   class.classif_tipo_id=programmaCodeTipoId
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
    and   class.data_cancellazione is null; -- 19.01.2017
    -- Sofia 10.11.2016 INC000001359464
--    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio);  19.01.2017
--    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017
--    and   class.validita_fine is null;

	-- mif_ord_titolo_id
    -- mif_ord_titolo_code
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_titolo_id mif_ord_titolo_code.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_titolo_id, mif_ord_titolo_code) = (cp.classif_id,cp.classif_code)
	from siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id=m.mif_ord_elem_id
    and   cf.classif_id=classElem.classif_id
    and   cf.data_cancellazione is null
    and   classElem.data_cancellazione is null -- 19.01.2017
    and   classElem.validita_fine is null      -- 19.01.2017
    -- Sofia 10.11.2016 INC000001359464
--    and   date_trunc('day',dataElaborazione)>=date_trunc('day',cf.validita_inizio) 19.01.2017
--    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cf.validita_fine,dataFineVal)) 19.01.2017
--    and   cf.validita_fine is null
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitSpeMacroAggrCodeId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
    and   cp.data_cancellazione is null;
    -- Sofia 10.11.2016 INC000001359464
--    and   date_trunc('day',dataElaborazione)>=date_trunc('day',cp.validita_inizio) 19.01.2017
 --   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cp.validita_fine,dataFineVal)); 19.01.2017
--    and   cp.validita_fine is null;

/*    update mif_t_ordinativo_spesa_id m
    set (mif_ord_titolo_id, mif_ord_titolo_code) = (class.classif_id,class.classif_code)
    from siac_r_bil_elem_class classElem, siac_t_class class
    where classElem.elem_id=m.mif_ord_elem_id
    and   class.classif_id=classElem.classif_id
    and   class.classif_tipo_id=titoloUscitaCodeTipoId
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
    and   class.data_cancellazione is null
    and   class.validita_fine is null;*/




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
--    execute  'ANALYZE mif_t_ordinativo_spesa_id;';
    select 1 into codResult
    from mif_t_ordinativo_spesa_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di spesa da trasmettere.';
    end if;



    -- <ritenute>
    -- <ritenuta>
    -- <tipo_ritenuta>
    flussoElabMifElabRec:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_TIPO_RITENUTA]; -- 11.01.2016 Sofia

    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null and
               flussoElabMifElabRec.flussoElabMifParam is not null then
  					tipoRelazRitOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	                tipoRelazSprOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
	                tipoRelazSubOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    tipoOnereIrpef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    tipoOnereInps:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    -- 30.08.2016 Sofia-HD-INC000001208683
                    tipoOnereIrpeg:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));

	                tipoRitenuta:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));

                    if tipoRelazRitOrd is null or tipoRelazSprOrd is null or tipoRelazSubOrd is null or
                       tipoRitenuta is null or tipoOnereInps is null or tipoOnereIrpef is null
                       or tipoOnereIrpeg is null then -- 30.08.2016 Sofia-HD-INC000001208683
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
     flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_TIPO_RITENUTA+1];
     strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   	 if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   	 end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
    	else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
     else
       isRitenutaAttivo:=false;
	 end if;
     if isRitenutaAttivo=true then
     	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_TIPO_RITENUTA+2];
         strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   	 if flussoElabMifElabRec.flussoElabMifId is null then
  			  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   	 end if;
    	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
	    	else
				RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   		end if;
	     else
    	   isRitenutaAttivo:=false;
		 end if;
     end if;



     if isRitenutaAttivo=true then
     	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_TIPO_RITENUTA+3];
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
-- 		   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
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
-- 		   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
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
-- 		   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereIrpegId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;
     end if;
   end if;


   -- <ricevute>
   -- <ricevuta>
   -- <numero_ricevuta>
   -- <importo_ricevuta>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_RICEVUTA];

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
   if isRicevutaAttivo=true then
   	flussoElabMifElabRec:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_IMP_RICEVUTA];
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
    else isRicevutaAttivo:=false;
  	end if;
   end if;

   -- <Transazione_Elementare>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_TBR];

    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            		programmaTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    codiceEconPatTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    cofogTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    transazioneUeTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    siopeTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));
                    cupTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7));
                    ricorrenteTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,8));
  					aslTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,9));
                    progrRegUnitTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,10));

                    if codiceFinVTbr is not null then
						-- codiceFinVTipoTbrId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'. Transazione Elementare.Lettura piano_conti_fin_V_code_tipo_id '||codiceFinVTbr||'.';
			   		    select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
				    	from siac_d_class_tipo tipo
						where tipo.ente_proprietario_id=enteProprietarioId
						and   tipo.classif_tipo_code=codiceFinVTbr
						and   tipo.data_cancellazione is null
						and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
--						and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal)); 19.01.2017
						and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
                    end if;

                    if codiceEconPatTbr is not null then
                    	-- eventoTipoCodeId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura evento_id piano conto economico  '||codiceEconPatTbr||'.';

						select tipo.evento_tipo_id into strict eventoTipoCodeId
			            from siac_d_evento_tipo tipo
        			    where tipo.ente_proprietario_id=enteProprietarioId
		    	        and   tipo.evento_tipo_code=codiceEconPatTbr
		        	    and   tipo.data_cancellazione is null
				    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--			  		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
			  		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

    				end if;

                    if cofogTbr is not null then

                        codiceCofogCodeTipo:=cofogTbr;
                        -- codiceCofogCodeTipoId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura cofog_code_tipo_id  '||codiceCofogCodeTipo||'.';

			        	select tipo.classif_tipo_id into strict codiceCofogCodeTipoId
			            from  siac_d_class_tipo tipo
			            where tipo.ente_proprietario_id=enteProprietarioId
			            and   tipo.classif_tipo_code=codiceCofogCodeTipo
			            and   tipo.data_cancellazione is null
					    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--					 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
					 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       			    end if;

                    if transazioneUeTbr is not null then
                        codiceUECodeTipo:=transazioneUeTbr;
                        -- codiceUECodeTipoId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura codice_UE_code_tipo_id  '||codiceUECodeTipo||'.';

						select tipo.classif_tipo_id into strict codiceUECodeTipoId
    			        from  siac_d_class_tipo tipo
			            where tipo.ente_proprietario_id=enteProprietarioId
			            and   tipo.classif_tipo_code=codiceUECodeTipo
            			and   tipo.data_cancellazione is null
					    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--					 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));  19.01.2017
					 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                    end if;

                    if siopeTbr is not null then
                        siopeCodeTipo:=siopeTbr;
                        -- siopeCodeTipoId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura siope_code_tipo_id  '||siopeCodeTipo||'.';

	                    select tipo.classif_tipo_id into strict siopeCodeTipoId
                        from siac_d_class_tipo tipo
                        where tipo.classif_tipo_code=siopeCodeTipo
                        and   tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.data_cancellazione is null
	 				    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 			 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                    end if;

                    if cupTbr is not null then
                    	-- cupAttrId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura cup_attr_id  '||cupTbr||'.';

                    	select attr.attr_id into strict cupAttrId
                        from siac_t_attr attr
                        where attr.attr_code=cupTbr
                        and   attr.ente_proprietario_id=enteProprietarioId
                        and   attr.data_cancellazione is null
	 				    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
-- 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal)); 19.01.2017
 			 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

                    end if;

                    if ricorrenteTbr is not null then
	                    -- ricorrenteTipoTbrId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura ricorrente_code_tipo_id  '||ricorrenteTbr||'.';

	                    select tipo.classif_tipo_id into strict ricorrenteTipoTbrId
                        from siac_d_class_tipo tipo
                        where tipo.classif_tipo_code=ricorrenteTbr
                        and   tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.data_cancellazione is null
	 				    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 			 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


                    end if;

                    if aslTbr is not null then
						-- aslTipoTbrId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare. Lettura asl_code_tipo_id  '||aslTbr||'.';

	                    select tipo.classif_tipo_id into strict aslTipoTbrId
                        from siac_d_class_tipo tipo
                        where tipo.classif_tipo_code=aslTbr
                        and   tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.data_cancellazione is null
	 				    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--- 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 			 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                    end if;

                    if progrRegUnitTbr is not null then
						-- progrRegUnitTipoTbrId
                        strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                     ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.Lettura progr_reg_unit_code_tipo_id  '||progrRegUnitTbr||'.';

	                    select tipo.classif_tipo_id into strict progrRegUnitTipoTbrId
                        from siac_d_class_tipo tipo
                        where tipo.classif_tipo_code=progrRegUnitTbr
                        and   tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.data_cancellazione is null
	 				    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 			 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                    end if;
                isTransElemAttiva:=true;
            end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
   end if;

   -- <Numero_quota_mandato>
   mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
               ||' mifCountRec='||mifCountRec
               ||' tipo flusso '||MANDMIF_TIPO||'.';
  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  end if;
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
 	if flussoElabMifElabRec.flussoElabMifElab=true then
    	isGestioneQuoteOK:=true;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
  end if;

   -- <InfSerMan_Fattura_Descr>
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
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' then
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
  end if;

   -- <previsione>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_CAST_CASSA];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.Transazione Elementare.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	tipoEsercizio:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;
        else
	    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
   end if;

   -- 19.01.2016 Sofia ABI36
   -- <dati_a_disposizione_ente_beneficiario>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_DISP_ABI36];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.Dati a disposizione ente beneficiario ABI36.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	datiDispEnteBenef:=true;
        else
	    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
   end if;

   -- 21.01.2016 Sofia ABI36
   -- <sepa_credit_transfer>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_SEPA_CREDIT_T];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.Tracciato ABI36.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
           if flussoElabMifElabRec.flussoElabMifParam is not null then
           	paeseSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            accreditoGruppoSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            SepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if accreditoGruppoSepaTr is not null and SepaTr is not null and paeseSepaTr is not null then
	            sepaCreditTransfer:=true;
            end if;
           end if;
        else
	    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
   end if;


--  execute  'ANALYZE mif_t_ordinativo_spesa;';
--  execute  'ANALYZE mif_t_ordinativo_spesa_ritenute;';
--  execute  'ANALYZE mif_t_ordinativo_spesa_ricevute;';
--  execute  'ANALYZE mif_t_ordinativo_spesa_disp_ente;';


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
	    mifCountRec:=1;
        mifCountTmpRec:=1;

        avvisoBenef:='N';
        isIndirizzoBenef:=true;
        avvisoBenQuiet:='N';
        isIndirizzoBenQuiet:=true;

		-- 15.02.2016 Sofia ABI36
		codiceFinVCodeTbr:=null;
	    contoEconCodeTbr:=null;
	    cofogCodeTbr:=null;
	    codiceUeCodeTbr:=null;
	    siopeCodeTbr:=null;
	    cupAttrTbr:=null;
	    ricorrenteCodeTbr:=null;
	    aslCodeTbr:=null;
	    progrRegUnitCodeTbr:=null;

        -- 29.12.2016 Sofia JIRA-SIAC-4278
        bavvioFrazAttr:=false;
        -- 29.12.2016 Sofia SIAC-4139
        bAvvioSiopeNew:=false;

		-- 05.05.2017 Sofia HD-INC000001742637
	    statoBeneficiario:=false;
		statoDelegatoAbi36:=false; -- 12.05.2017

        -- lettura importo ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        													  		       flussoElabMifTipoDec); -- 20.01.2016 Sofia ABI36

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
-- 		  and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)) 19.01.2017
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


       /* strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_funzione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';*/
		-- <codice_funzione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --1
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        /*select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_funzione ,enteProprietarioId);*/
		--raise notice '% %',strMessaggio,mifOrdinativoIdRec.mif_ord_codice_funzione;
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            -- ABI36 Aggiungere lettura param per impostare valori particolari del codice funzione
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
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --2
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
            -- 21.01.2016 Sofia ABI36
         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --3
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


/*        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.
                       ||' tipo flusso '||MANDMIF_TIPO||'.';*/

		-- <importo_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 4
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		/*select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo_mandato ,enteProprietarioId);*/
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

        -- <flg_finanza_locale>
        mifCountRec:=mifCountRec+1; --5
        -- <numero_documento>
        mifCountRec:=mifCountRec+1; --6

		-- <tipo_contabilita_ente_pagante>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 7
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
             mifFlussoOrdinativoRec.mif_ord_bci_tipo_ente_pag:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <destinazione_ente_pagante>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 8
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

            /* 16.02.2017 Sofia HD-INC000001564624  spostato sotto
              if coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
             mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag:=flussoElabMifElabRec.flussoElabMifDef;
            end if; */

            -- 10.02.2017 Sofia SIAC-4423-CmTo
              if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR then
            	if valFruttiferoClassCode is null then
                	valFruttiferoClassCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if valFruttiferoClassCode is not null and valFruttiferoClassCodeId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura identificativo valFruttiferoClassCode='||valFruttiferoClassCode||'.';
                	select tipo.classif_tipo_id into valFruttiferoClassCodeId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=valFruttiferoClassCode;
                end if;

                if valFruttiferoClassCodeId is not null then
                	if valFruttiferoClassCodeSI is null and valFruttiferoCodeSI is null then
                    	valFruttiferoClassCodeSI:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                        valFruttiferoCodeSI:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;
                   	if valFruttiferoClassCodeNO is null and valFruttiferoCodeNO is null then
                    	valFruttiferoClassCodeNO:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                        valFruttiferoCodeNO:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    end if;

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per valFruttiferoClassCode='||valFruttiferoClassCode||'.';
                    select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r ,siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=valFruttiferoClassCodeId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttiferoClassCodeSI then
                        	flussoElabMifValore:=valFruttiferoCodeSI;
                        elsif flussoElabMifValore=valFruttiferoClassCodeNO then
                        	flussoElabMifValore:=valFruttiferoCodeNO;
                        else     flussoElabMifValore:=null;
                        end if;
                    end if;

					if flussoElabMifValore is not null then
    		         mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag:=flussoElabMifValore;
            		end if;

                end if; --valFruttiferoClassCodeId

            end if; -- flussoElabMifParam

            -- 17.03.2017  	JIRA-SIAC-4621-CMTO
            if mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag is null and
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
               	mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag:=flussoElabMifValore;
               end if;

            end if;
            -- 17.03.2017  	JIRA-SIAC-4621-CMTO


            -- 16.02.2017 Sofia HD-INC000001564624
            if mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag is null and
               coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
               mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_tesoreria>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 9
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

            mifFlussoOrdinativoRec.mif_ord_bci_conto_tes:=substring(flussoElabMifValore from 1 for 7 );

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <estremi_provvedimento_autorizzativo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 10
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

       -- <codice_ufficio_responsabile>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --11
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
         	mifFlussoOrdinativoRec.mif_ord_codice_uff_resp:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <data_provvedimento_autorizzativo> --12
        -- <responsabile_provvedimento> --13
        -- <ufficio_responsabile>--14
        mifCountRec:=mifCountRec+3;

        -- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 15
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
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 16
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

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 17
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
 --           	mifFlussoOrdinativoRec.mif_ord_desc_ente:=flussoElabMifElabRec.flussoElabMifDef; 09.02.2016 Sofia JIRA SIAC-2998
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 18
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
/*        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_ente_BT
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_ente_BT ,enteProprietarioId);*/
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=enteOilRec.ente_oil_codice;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <esercizio>
        flussoElabMifElabRec:=null;
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 19
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

        -- <identificativo_flusso> -- 20
        -- <data_ora_creazione_flusso> --21
        -- <anno_flusso> --22
        mifCountRec:=mifCountRec+3;

        -- <codice_struttura>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 23
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice distinta collegata all''ordinativo.';

                	select d.dist_code into flussoElabMifValore
                    from siac_d_distinta d
                    where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_codice_struttura:=flussoElabMifValore;
                    end if;
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <progressivo_mandato_struttura>
        mifCountRec:=mifCountRec+1; -- 24

		-- <ente_localita>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 25
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
         		if localitaEnte is null then
                	if flussoElabMifElabRec.flussoElabMifDef is not null then
                     localitaEnte:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;
                end if;

                if localitaEnte is not null then
                	mifFlussoOrdinativoRec.mif_ord_ente_localita:=localitaEnte;
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <ente_indirizzo>
        flussoElabMifElabRec:=null;
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 26
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
         		if indirizzoEnte is null then
                	if flussoElabMifElabRec.flussoElabMifDef is not null then
                     indirizzoEnte:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;
                end if;

                if indirizzoEnte is not null then
                	mifFlussoOrdinativoRec.mif_ord_ente_indirizzo:=indirizzoEnte;
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_cge> -- 27
        -- <descr_cge>  -- 28
        mifCountRec:=mifCountRec+2;

		-- <siope_codice_cge>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codiceCge:=null;
        --mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_CODICE_CGE];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_CODICE_CGE
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true or isTransElemAttiva=true then
         if flussoElabMifElabRec.flussoElabMifElab=true or isTransElemAttiva=true then
         		if flussoElabMifElabRec.flussoElabMifParam is not null or isTransElemAttiva=true then
					--raise notice 'flussoElabMifElabRec.flussoElabMifParam %',flussoElabMifElabRec.flussoElabMifParam;
                	if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
                    	--siopeCodeTipo:=flussoElabMifElabRec.flussoElabMifParam;
                        -- 28.12.2015 Sofia Siope fittizio
                        siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;

                    if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
                    	siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;
					--raise notice 'siopeDef %',siopeDef;

                    -- 29.12.2016 Sofia SIAC-4139
                    if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
                       flussoElabMifElabRec.flussoElabMifParam is not null then
                    	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
                    	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    end if;

					raise notice 'dataAvvioSiopeNew=%',dataAvvioSiopeNew;
                    -- 29.12.2016 Sofia SIAC-4139
                    if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
                    	if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                           then
                             bAvvioSiopeNew:=true;
                        end if;
                    end if;

				    if bAvvioSiopeNew=true then
                    	if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
						 -- codiceFinVTipoTbrId
                         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||FLUSSO_MIF_ELAB_CODICE_CGE
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			   		     select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
				    	 from siac_d_class_tipo tipo
						 where tipo.ente_proprietario_id=enteProprietarioId
						 and   tipo.classif_tipo_code=codiceFinVTbr
						 and   tipo.data_cancellazione is null
						 and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
--						 and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal)); 19.01.2017
						 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

	                    end if;

                        if codiceFinVTipoTbrId is not null then
                          strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||FLUSSO_MIF_ELAB_CODICE_CGE
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
--			              and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
-- 		     			  and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017

                        end if;

                    else

                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_CODICE_CGE
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||siopeCodeTipo||'.';

                     if siopeCodeTipoId is null and siopeCodeTipo is not null then
                    	select tipo.classif_tipo_id into siopeCodeTipoId
                        from siac_d_class_tipo tipo
                        where tipo.classif_tipo_code=siopeCodeTipo
                        and   tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.data_cancellazione is null
	 				    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 			 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                     end if;

                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_CODICE_CGE
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||siopeCodeTipo||'.';

                     if siopeCodeTipoId is not null then
                  	  select class.classif_code, class.classif_desc
                            into flussoElabMifValore,flussoElabMifValoreDesc
                      from siac_r_ordinativo_class cord, siac_t_class class
                      where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                      and cord.data_cancellazione is null
                      and cord.validita_fine is null
                      and class.classif_id=cord.classif_id
                      and class.classif_code!=siopeDef -- 28.12.2015 Sofia - esclusione siope fittizio
                      and class.data_cancellazione is null
--         			  and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--		 			  and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)) 19.01.2017
                      and class.classif_tipo_id=siopeCodeTipoId;

                     end if;
                   end if;

                   if flussoElabMifValore is not null then
                		mifFlussoOrdinativoRec.mif_ord_siope_codice_cge:=flussoElabMifValore;
                   		codiceCge:=flussoElabMifValore;
                    	-- TBR
	                    if isTransElemAttiva=true then
                    		siopeCodeTbr:=codiceCge;
	                    end if;
    	           end if;
        		end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <siope_descr_cge>
        flussoElabMifElabRec:=null;
        --mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_DESCRI_CGE];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||FLUSSO_MIF_ELAB_DESCRI_CGE
        			   ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifValoreDesc is not null then
--                	mifFlussoOrdinativoRec.mif_ord_siope_descri_cge:=flussoElabMifValoreDesc; 25.02.2016 Sofia troncato a 60
                	mifFlussoOrdinativoRec.mif_ord_siope_descri_cge:=substring(flussoElabMifValoreDesc from 1 for 60);
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <Tipo_Contabilita>
		mifCountRec:=mifCountRec+1; -- 29

        -- <codice_raggruppamento>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --30
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
               /* if   flussoElabMifValore is not null then --  20.12.2016 Sofia SIAC-4235- CmTo
                	mifFlussoOrdinativoRec.mif_ord_codice_raggrup:=flussoElabMifValore;
                end if; spostato sotto */
               end if;
            elsif mifOrdinativoIdRec.mif_ord_dist_id is not null then --  20.12.2016 Sofia SIAC-4235- CmTo
             raise notice 'DIST';
            	    select d.dist_code into flussoElabMifValore
                    from siac_d_distinta d
                    where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
          	end if;

            --  20.12.2016 Sofia SIAC-4235- CmTo
            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_raggrup:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <progressivo_beneficiario>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --31
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
                	mifFlussoOrdinativoRec.mif_ord_progr_benef:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <Impignorabili> --32
        mifCountRec:=mifCountRec+1;
        -- 18.01.2016 Sofia ABI36
        -- <destinazione>  --33
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --31
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--	   raise notice '%', strMessaggio;

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
                -- 15.03.2016 Sofia ABI36 (Alessandria)
                if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR and
                   mifFlussoOrdinativoRec.mif_ord_bci_conto_tes is not null then
                   if coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
                	if fnc_mif_ordinativo_esenzione_bollo(mifFlussoOrdinativoRec.mif_ord_bci_conto_tes,
                                                          flussoElabMifElabRec.flussoElabMifParam)=true then

                           flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                    else
 						   flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                    end if;
                   end if;
                end if;

                if flussoElabMifValore is null and
                   coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
       			   flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                end if;

                if flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_dest:=flussoElabMifValore;
                end if;
                -- 15.03.2016 Sofia ABI36 (Alessandria)
/*                if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_dest:=flussoElabMifElabRec.flussoElabMifDef;
                end if;*/
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


		-- <numero_conto_banca_italia_ente_ricevente>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        mifCountRec:=mifCountRec+1;
-- 01.03.2016        isAccreTipoF24:=false;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 34
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
                    if tipoMDPCbi is null then
                    	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    -- 01.03.2016 Sofia-JIRA-3138-ABI36
/*					if tipoMDPCbi is not null and
                       accreTipoF24 is null and flussoElabMifElabRec.flussoElabMifDef is not null then
	                    accreTipoF24:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                        if accreTipoF24 is not null and accreTipoF24!='' then
                        	accreTipoF24:=trim (both ' ' from substring(flussoElabMifElabRec.flussoElabMifParam from length(tipoMDPCbi)+1));
                        end if;
                    end if;*/

                    if tipoMDPCbi is not null then
                    	if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
                        	 mifFlussoOrdinativoRec.mif_ord_bci_conto:=MDPRec.contocorrente;
                        end if;
                    end if;

                    -- 01.03.2016 Sofia-JIRA-3138-ABI36
/*                    if mifFlussoOrdinativoRec.mif_ord_bci_conto is null and
                       accreTipoF24 is not null and accreTipoF24!=''
                       then
	                    isAccreTipoF24:=fnc_mif_ordinativo_esenzione_bollo(codAccreRec.accredito_tipo_code,accreTipoF24);
                        if isAccreTipoF24=true then
                        	mifFlussoOrdinativoRec.mif_ord_bci_conto:=flussoElabMifElabRec.flussoElabMifDef;
                        end if;
                    end if;**/

                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- 14.03.2016 Sofia ABI36
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

/* 22.04.2016 Sofia SIAC-3470
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' valore '||valFruttifero||'.';

                      select c.classif_id into valFruttiferoId
                      from siac_t_class c
                      where c.classif_tipo_id=tipoClassFruttiferoId
                      and   c.classif_code=valFruttifero
                      and   c.data_cancellazione is null
                      and   c.validita_fine is NULL
                      order by c.validita_inizio desc
                      limit 1;
                   end if;*/

--    22.04.2016 Sofia SIAC-3470               if valFruttiferoId is not null then
-- 22.04.2016 Sofia SIAC-3470
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

/*      22.04.2016 Sofia SIAC-3470
             	select r.ord_classif_id into codResult
                    from siac_r_ordinativo_class r
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   r.classif_id=valFruttiferoId
                    and   r.data_cancellazione is null
                    order by r.ord_classif_id limit 1;*/

-- 22.04.2016 Sofia SIAC-3470
                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null -- Sofia 10.11.2016 INC000001359464
--                    and   date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) 19.01.2017
--  	 			    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(c.validita_fine,dataFineVal)) 19.01.2017
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

/*  22.04.2016 Sofia SIAC-3470
                  if codResult is not null then
	                   	 flussoElabMifValore:=valFruttiferoStr;
                    else flussoElabMifValore:=valFruttiferoStrAltro;
                    end if;*/

-- 22.04.2016 Sofia SIAC-3470
                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;

                   end if;

				 end if; -- param


                 if flussoElabMifValore is null then
                   	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                 end if;

                 mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
                end if; -- default
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
		end if;


        mifCountRec:=mifCountRec+2; --37
        if codiceCge is not null then
		 -- <class_codice_cge>
         flussoElabMifElabRec:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1]; --36
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
            	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=codiceCge;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <importo>
        flussoElabMifElabRec:=null;
        --mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --37
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
       end if;


       -- <Codice_cup>
       -- <Codice_cpv>
       mifCountRec:=mifCountRec+2; --41

       -- 23.02.2016 Sofia JIRA-SIAC-3032 - gestione_provvisoria,  frazionabile
  	   -- <gestione_provvisoria>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --42
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
          raise notice 'PROVVISORIO mif_ord_bil_fase_ope=%',mifOrdinativoIdRec.mif_ord_bil_fase_ope;
          	if tipoEsercizio=mifOrdinativoIdRec.mif_ord_bil_fase_ope  then
				mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov=flussoElabMifElabRec.flussoElabMifDef;
            end if;
		   end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;

       end if;

	   -- <frazionabile>
       mifCountRec:=mifCountRec+1;
       if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov is not null then
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --42
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
             flussoElabMifElabRec.flussoElabMifDef is not null  then

			 -- JIRA-SIAC-4278 27.12.2016 SOfia
             if dataAvvioFrazAttr is null then
             	dataAvvioFrazAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
			 raise notice 'dataAvvioFrazAttr=%',dataAvvioFrazAttr::timestamp;
             raise notice 'mif_ord_data_emissione=%',date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp);

             if dataAvvioFrazAttr is not null and
                dataAvvioFrazAttr::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                then
                bavvioFrazAttr:=true;
             end if;


             -- JIRA-SIAC-4278 27.12.2016 SOfia
             if bavvioFrazAttr=false then
              -- JIRA-SIAC-4278 27.12.2016 SOfia
              if classifTipoCodeFraz is null then
--              classifTipoCodeFraz:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
               classifTipoCodeFraz:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;

              -- JIRA-SIAC-4278 27.12.2016 SOfia
              if classifTipoCodeFrazVal is null then
--              classifTipoCodeFrazVal:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
               classifTipoCodeFrazVal:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
             else
 			  -- JIRA-SIAC-4278 27.12.2016 SOfia
              if attrFrazionabile is null then
	             attrFrazionabile:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;
             end if;

             -- JIRA-SIAC-4278 27.12.2016 SOfia
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
--                and   c.data_cancellazione is null
--                and   c.validita_fine is null
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                -- Sofia 10.11.2016 INC000001359464
                and   c.data_cancellazione is null
--                and date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) 19.01.2017
--  	 			and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(c.validita_fine,dataFineVal)) 19.01.2017
                order by r.ord_classif_id
                limit 1;

              end if;

              if classifTipoCodeFrazVal is not null and
                flussoElabMifValore is not null and
                flussoElabMifValore=classifTipoCodeFrazVal then
             	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
             end if;
			else -- bavvioFrazAttr=true then -- JIRA-SIAC-4278 287.12.2016 SOfia
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
               and   r.validita_fine is null -- 19.01.2017
--               and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) 19.01.2017
-- 			   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(r.validita_fine,dataFineVal)) 19.01.2017
               and   rmov.data_cancellazione is null
               and   rmov.validita_fine is null -- 19.01.2017
--               and   date_trunc('day',dataElaborazione)>=date_trunc('day',rmov.validita_inizio) 19.01.2017
-- 			   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rmov.validita_fine,dataFineVal)) 19.01.2017
               and   liqord.data_cancellazione is null
               and   liqord.validita_fine is null -- 19.01.2017
--               and   date_trunc('day',dataElaborazione)>=date_trunc('day',liqord.validita_inizio) 19.01.2017
-- 			   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(liqord.validita_fine,dataFineVal)) 19.01.2017
			   and   ts.data_cancellazione is null
               and   ts.validita_fine is null; -- 19.01.2017
--               and   date_trunc('day',dataElaborazione)>=date_trunc('day',ts.validita_inizio) 19.01.2017
-- 			   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ts.validita_fine,dataFineVal)); 19.01.2017

               if codResult is not null then
               	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

              end if;
            end if;

          end if; -- param, def
      	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;  --- elab

        end if; -- attivo

        -- non ho valorizzato il frazionabile nonostante sia in EP quindi svuoto anche il campo della gestione_provvisoria
        if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz is null then
          mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov:=null;
        end if;

       end if; -- mif_ord_class_codice_gest_prov

       -- 23.02.2016 Sofia JIRA-SIAC-3032 - gestione_provvisoria,  frazionabile

	   -- <codifica_bilancio>
       -- 26.11.2015 Sofia - tag valorizzato parametricamente  per ente
       -- in base al nome campo presente in flusso_elab_mif_campo
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --42
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

            	-- 26.11.2015 Sofia la codifica di bilancio salvata in mif_ord_codifica_bilancio
                -- missione||programma||titolo_uscita
                mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=mifOrdinativoIdRec.mif_ord_programma_code
                												||mifOrdinativoIdRec.mif_ord_titolo_code;

                -- 26.11.2015 Sofia il numero del capitolo salvato in mif_ord_capitolo
                mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <numero_articolo>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --43
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
        mifCountRec:=mifCountRec+1; --44

	   -- <descrizione_codifica>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --45
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
         		-- 11.01.2016 Sofia
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
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --46
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
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --47
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
               coalesce(isDefAnnoRedisuo,NVL_STR)=NVL_STR then
               isDefAnnoRedisuo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

/*     -- 16.02.2016 ABI36
       if isDefAnnoRedisuo is not null and isDefAnnoRedisuo='S' THEN
            	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
            else
            	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_anno_bil;
            end if;*/

/*            if coalesce(isDefAnnoRedisuo,NVL_STR)!=NVL_STR  then
              if  coalesce(isDefAnnoRedisuo,NVL_STR)='S' or
                  mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg then -- 16.02.2016 ABI36
	           	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
	          end if;
            else
            	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_anno_bil;
            end if;*/

            -- 17.02.2016 ABI36 dopo modifica ABI36 tutto in errore !
            if coalesce(isDefAnnoRedisuo,NVL_STR)!=NVL_STR and  coalesce(isDefAnnoRedisuo,NVL_STR)!='N' then
               if  coalesce(isDefAnnoRedisuo,NVL_STR)='S' or
	               mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
               	   mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
               end if;
	        else
            	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_anno_bil;
            end if;



         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


       -- <importo_bilancio>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --48
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



       -- 11.01.2016 Sofia
	   -- <stanziamento> --49
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
         	if coalesce(mifOrdinativoIdRec.mif_ord_cast_competenza,0)>0 then -- 15.01.2016 Sofia castelleti lasciati a zero
	           	if flussoElabMifTipoDec=false then -- 20.01.2016 Sofia ABI36
	                mifFlussoOrdinativoRec.mif_ord_stanz:=trunc((mifOrdinativoIdRec.mif_ord_cast_competenza*100))::varchar;
                else
                	mifFlussoOrdinativoRec.mif_ord_stanz:=mifOrdinativoIdRec.mif_ord_cast_competenza::varchar;
                end if;
            else
            	mifFlussoOrdinativoRec.mif_ord_stanz:='0';
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

       -- <mandati_stanziamento> --50
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; ---53
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
         	if coalesce(mifOrdinativoIdRec.mif_ord_cast_competenza,0)>0 then -- 15.01.2016 Sofia castelleti lasciati a zero
				if flussoElabMifTipoDec=false then -- 20.01.2016 Sofia ABI36
                     mifFlussoOrdinativoRec.mif_ord_mandati_stanz:=
    	          	  trunc((mifOrdinativoIdRec.mif_ord_cast_emessi+
        	       	  (mifFlussoOrdinativoRec.mif_ord_importo::numeric/100))*100)::varchar;
                else
                	 mifFlussoOrdinativoRec.mif_ord_mandati_stanz:=
    	          	  (mifOrdinativoIdRec.mif_ord_cast_emessi+
                       (mifFlussoOrdinativoRec.mif_ord_importo::numeric))::varchar;
                end if;

            else    mifFlussoOrdinativoRec.mif_ord_mandati_stanz:='0';
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

       -- <disponibilita_capitolo> --51
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 54
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
	         if coalesce(mifOrdinativoIdRec.mif_ord_cast_competenza,0)>0 then -- 15.01.2016 Sofia castelleti lasciati a zero
				if flussoElabMifTipoDec=false then -- 20.01.2016 Sofia ABI36
               		 mifFlussoOrdinativoRec.mif_ord_disponibilita:=
        	    		trunc((mifFlussoOrdinativoRec.mif_ord_stanz::numeric/100-mifFlussoOrdinativoRec.mif_ord_mandati_stanz::numeric/100)*100)::varchar;
                else
                	 mifFlussoOrdinativoRec.mif_ord_disponibilita:=
        	    		(mifFlussoOrdinativoRec.mif_ord_stanz::numeric-mifFlussoOrdinativoRec.mif_ord_mandati_stanz::numeric)::varchar;

                end if;
             else
                mifFlussoOrdinativoRec.mif_ord_disponibilita:='0';
             end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
	   -- 11.01.2016 Sofia

       -- <previsione>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --52
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
         if flussoElabMifElabRec.flussoElabMifElab=true THEN
            -- 11.01.2016 Sofia
         	if tipoEsercizio is not null and mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null AND
	           tipoEsercizio!=mifOrdinativoIdRec.mif_ord_bil_fase_ope  then
               	 if coalesce(mifOrdinativoIdRec.mif_ord_cast_cassa)>0 then -- 15.01.2016 Sofia castelleti lasciati a zero
                   if flussoElabMifTipoDec=false then -- 20.01.2016 Sofia ABI36
		     	       mifFlussoOrdinativoRec.mif_ord_prev:=trunc((mifOrdinativoIdRec.mif_ord_cast_cassa*100))::varchar;
                   else
                   	   mifFlussoOrdinativoRec.mif_ord_prev:=mifOrdinativoIdRec.mif_ord_cast_cassa::varchar;
                   end if;
                else mifFlussoOrdinativoRec.mif_ord_prev:='0';
                end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	   -- <mandati_previsione>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; ---53
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
            -- 11.01.2016 Sofia
	        if tipoEsercizio is not null and mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null AND
               tipoEsercizio!=mifOrdinativoIdRec.mif_ord_bil_fase_ope then
           	   if coalesce(mifOrdinativoIdRec.mif_ord_cast_cassa)>0 then -- 15.01.2016 Sofia castelleti lasciati a zero
	               if flussoElabMifTipoDec=false then -- 20.01.2016 Sofia ABI36
    	           	mifFlussoOrdinativoRec.mif_ord_mandati_prev:=
        	    		trunc((mifOrdinativoIdRec.mif_ord_cast_emessi+
	        	     	(mifFlussoOrdinativoRec.mif_ord_importo::numeric/100))*100)::varchar;
                   else
                   	mifFlussoOrdinativoRec.mif_ord_mandati_prev:=
        	    		(mifOrdinativoIdRec.mif_ord_cast_emessi+(mifFlussoOrdinativoRec.mif_ord_importo::numeric))::varchar;
                   end if;
               else mifFlussoOrdinativoRec.mif_ord_mandati_prev:='0';
               end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <disponibilita_cassa>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 54
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
          -- 11.01.2016 Sofia
          if tipoEsercizio is not null and mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null AND
             tipoEsercizio!=mifOrdinativoIdRec.mif_ord_bil_fase_ope then
             	if coalesce(mifOrdinativoIdRec.mif_ord_cast_cassa)>0 then -- 15.01.2016 Sofia castelleti lasciati a zero
	               if flussoElabMifTipoDec=false then -- 20.01.2016 Sofia ABI36
	 	          	  mifFlussoOrdinativoRec.mif_ord_disp_cassa:=
    		          trunc((mifFlussoOrdinativoRec.mif_ord_prev::numeric/100-mifFlussoOrdinativoRec.mif_ord_mandati_prev::numeric/100)*100)::varchar;
                   else
                   	   mifFlussoOrdinativoRec.mif_ord_disp_cassa:=
    		             (mifFlussoOrdinativoRec.mif_ord_prev::numeric-mifFlussoOrdinativoRec.mif_ord_mandati_prev::numeric)::varchar;
                   end if;
                else mifFlussoOrdinativoRec.mif_ord_disp_cassa:='0';
                end if;
          end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <anagrafica_beneficiario>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       mifCountRec:=mifCountRec+1;
       anagraficaBenefCBI:=null;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 55
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
         	if soggettoSedeSecId is not null then
            	flussoElabMifValore:=soggettoRec.soggetto_desc||' '||soggettoSedeRec.soggetto_desc;
            else
            	flussoElabMifValore:=soggettoRec.soggetto_desc;
            end if;

            if flussoElabMifElabRec.flussoElabMifParam is not null and tipoMDPCbi is null then
	           	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            -- se non e girofondo o se lo e ma il contocorrente_intestazione e vuoto
            -- valorizzo i tag di anagrafica_beneficiario
            -- altrimenti solo anagrafica_beneficiario=contocorrente_intestazione
            -- e anagrafica_beneficiario in dati_a_disposizione_ente
            if codAccreRec.accredito_gruppo_code!=tipoMDPCbi or
			   (codAccreRec.accredito_gruppo_code=tipoMDPCbi and
                 (MDPRec.contocorrente_intestazione is null or MDPRec.contocorrente_intestazione='')) then -- 02.03.2016 Sofia
	           	mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);
            else
           --    if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
	            	anagraficaBenefCBI:=flussoElabMifValore;
	                mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(MDPRec.contocorrente_intestazione from 1 for 140);
           --    end if;
            end if;
           /* raise notice 'anagrafica_beneficiario tipoMDPCbi=% accredito_gruppo_code=%',
            		tipoMDPCbi,codAccreRec.accredito_gruppo_code;
            raise notice 'conto_correnteintazione=% anagraficaBenefCBI=%',MDPRec.contocorrente_intestazione,anagraficaBenefCBI;*/
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	   -- <indirizzo_beneficiario>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       avvisoBenef:=null;
       mifCountRec:=mifCountRec+1;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --56
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
                isIndirizzoBenef:=false; -- 26.01.2016 SofiaJira
            end if;

            if isIndirizzoBenef=true then -- 26.01.2016 SofiaJira

			 -- serve per calcolo invio_avviso
			 avvisoBenef:=COALESCE(indirizzoRec.avviso,'N');

             if indirizzoRec.via_tipo_id is not null then
            	select tipo.via_tipo_code into flussoElabMifValore
                from siac_d_via_tipo tipo
                where tipo.via_tipo_id=indirizzoRec.via_tipo_id
                and   tipo.data_cancellazione is null
         	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
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
       mifCountRec:=mifCountRec+1; --57
       if isIndirizzoBenef=true then -- 26.01.2016 SofiaJira

        if indirizzoRec.zip_code is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --57
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
      mifCountRec:=mifCountRec+1; --58
      if isIndirizzoBenef=true then-- 26.01.2016 SofiaJira

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --58
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
--         	and   date_trunc('day',dataElaborazione)>=date_trunc('day',com.validita_inizio)
-- 		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(com.validita_fine,dataFineVal));

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
      mifCountRec:=mifCountRec+1; --59
      if isIndirizzoBenef=true then-- 26.01.2016 SofiaJira

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --59
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
         --	and   date_trunc('day',dataElaborazione)>=date_trunc('day',provRel.validita_inizio)
 		 --	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(provRel.validita_fine,dataFineVal))
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
--         	and   date_trunc('day',dataElaborazione)>=date_trunc('day',prov.validita_inizio)
-- 		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(prov.validita_fine,dataFineVal))
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

        -- 18.01.2016 Sofia ABI36
        -- <stato_beneficiario>
        --mifCountRec:=mifCountRec+1; -- popolare in seguito ricavato il codice_paese di piazzatura
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_STATO_BENEF]; --59
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
         	if statoBeneficiario=false then
	            statoBeneficiario:=true;
            end if;
         else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
       end if;

        -- <partita_iva_beneficiario>
        mifCountRec:=mifCountRec+1; --60
--        if soggettoRec.partita_iva is not null and anagraficaBenefCBI is null then
        if ( anagraficaBenefCBI is null and
            (soggettoRec.partita_iva is not null or
            (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11))
           )   then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --60
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
                	mifFlussoOrdinativoRec.mif_ord_partiva_benef:=trim ( both ' ' from soggettoRec.codice_fiscale);
                end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;
       end if;

       -- <codice_fiscale_beneficiario>
       mifCountRec:=mifCountRec+1; -- 61
       if soggettoRec.partita_iva is null and anagraficaBenefCBI is null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --61
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
          	if soggettoRec.codice_fiscale is not null and
--               length(soggettoRec.codice_fiscale) in (16,11) then
				 length(soggettoRec.codice_fiscale)=16 then
--             	flussoElabMifValore:=soggettoRec.codice_fiscale;
--            elsif  flussoElabMifElabRec.flussoElabMifDef is not null then
             	flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            elsif  flussoElabMifElabRec.flussoElabMifDef is not null and
--                   soggettoRec.codice_fiscale is null then
                   (soggettoRec.codice_fiscale is null or
                    (soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale) not in (11,16))) then  -- 01.02.2016 Sofia -- modificato dopo segnalazione su entrate
	            flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
            end if;

            if flussoElabMifValore is not null then
            	if length(flussoElabMifValore)=16 then -- 15.02.2016 Sofia JIRA-SIAC-XXXX-ABI36
		             mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;
    	        elsif length(flussoElabMifValore)=11 then
	                 mifFlussoOrdinativoRec.mif_ord_partiva_benef:=flussoElabMifValore;
                end if;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;

        -- <beneficiario_quietanzante>
      	flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        soggettoQuietRec:=null;
        soggettoQuietRifRec:=null;
        soggettoQuietId:=null;
        soggettoQuietRifId:=null;
        avvisoBenQuiet:=null;
        mifCountRec:=mifCountRec+1; --62
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --62
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
           if  ordCsiRelazTipoId is null then
            if ordCsiRelazTipo is null then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
	                ordCsiRelazTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    -- 23.02.2017 Sofia HD-INC000001582991
                    ordCsiCOTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
            end if;

            if ordCsiRelazTipo is  not null then
            	/*select tipo.relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
         		  and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 		 	      and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 		 	      and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));*/
                -- 16.05.2017 Sofia creata relazione tra siac_d_relaz_tipo e CSI
                select tipo.oil_relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_oil_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.oil_relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
                  and tipo.validita_fine is null;
            end if;
           end if;
--   		   raise notice 'strMessaggio %',strMessaggio;
--           raise notice 'ordCsiRelazTipoId %',ordCsiRelazTipoId;
--           if ordCsiRelazTipoId is not null then
           if ordCsiRelazTipoId is not null and -- 23.02.2017 Sofia HD-INC000001582991 - sezione CSI solo se MDP!=CO
                                                -- se non entra in if   soggettoQuietId non viene valorizzato e neanche la sezione
              ( ordCsiCOTipo is null or ordCsiCOTipo!=codAccreRec.accredito_gruppo_code ) then

                soggettoQuietId:=MDPRec.soggetto_id;
  --              raise notice 'soggettoQuietId %',soggettoQuietId;
  --              raise notice 'MDPRec.soggetto_id %',MDPRec.soggetto_id;
  --              raise notice 'MDPRec.modpag_id %',MDPRec.modpag_id;
  --              raise notice 'soggettoRifId %',soggettoRifId;

                /*            	select sogg.soggetto_id,  sogg.soggetto_desc,
                       sogg.codice_fiscale,  sogg.partita_iva*/ /** 05.02.2016 Sofia JIRA-2977 **/
            	/*select sogg.*
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                and   relmdp.validita_fine is null
    			and   relmdp.soggetto_relaz_id=relsogg.soggetto_relaz_id
                and   relsogg.soggetto_id_a=MDPRec.soggetto_id
                and   relsogg.soggetto_id_da=soggettoRifId
                and   relsogg.relaz_tipo_id=ordCsiRelazTipoId
                and   relsogg.data_cancellazione is null
                and   relsogg.validita_fine is null;*/

				-- 16.05.2017 Sofia creata relazione tra siac_d_relaz_tipo e CSI
                select sogg.*
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg,
                     siac_r_oil_relaz_tipo roil
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                and   relmdp.validita_fine is null
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

--               if soggettoQuietRec is not null then
               if soggettoQuietId is not null then
--               	raise notice 'soggettoQuietRec.soggetto_id %',soggettoQuietRec.soggetto_id;
 --              	 soggettoQuietId:=soggettoQuietRec.soggetto_id; spostato sopra

    --             raise notice 'soggettoQuietId %',soggettoQuietId;

/*               	 select sogg.soggetto_id, sogg.soggetto_desc,
                        sogg.codice_fiscale, sogg.partita_iva*/
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

/*                 if soggettoQuietRifRec is not null then
                 	soggettoQuietRifId:=soggettoQuietRifRec.soggetto_id;
                 end if;*/

               end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

      --  raise notice 'soggettoQuietId %',soggettoQuietId;

        mifCountRec:=mifCountRec+1; -- 63
  		-- <anagrafica_ben_quiet>
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
                	mifFlussoOrdinativoRec.mif_ord_anag_quiet:=substring(flussoElabMifValore from 1 for 140);
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	   end if;

       mifCountRec:=mifCountRec+1; --64
	   -- <indirizzo_ben_quiet>
	   if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         indirizzoRec:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --64
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
--         	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',indir.validita_inizio)
-- 		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(indir.validita_fine,dataFineVal));

                if indirizzoRec is null then
            		--RAISE EXCEPTION ' Errore in lettura indirizzo soggettoQuiet [siac_t_indirizzo_soggetto].';
                    isIndirizzoBenQuiet:=false;
            	end if;

			    if isIndirizzoBenQuiet=true then -- 26.01.2016 SofiaJira
                 -- serve per calcolo invio_avviso
 				 avvisoBenQuiet:=COALESCE(indirizzoRec.avviso,'N');

            	 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
                	from siac_d_via_tipo tipo
               		where tipo.via_tipo_id=indirizzoRec.via_tipo_id
	                and   tipo.data_cancellazione is null
    	     	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 			 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 			 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                	if flussoElabMifValore is not null then
                		flussoElabMifValore:=flussoElabMifValore||' ';
               	    end if;

           		  end if;

	             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
    	                             ||' '||coalesce(indirizzoRec.numero_civico,''));

        	     if flussoElabMifValore is not null then
	        	    mifFlussoOrdinativoRec.mif_ord_indir_quiet:=substring(flussoElabMifValore from 1 for 30);
	             end if;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	   end if;

       -- <cap_ben_quiet>
       mifCountRec:=mifCountRec+1; -- 65
       if isIndirizzoBenQuiet=true then -- 26.01.2016 SofiaJira
        if soggettoQuietId is not null and indirizzoRec is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --65
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
         		mifFlussoOrdinativoRec.mif_ord_cap_quiet:=lpad(indirizzoRec.zip_code,5,'0');
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;

         end if;
        end if;
      end if;


       -- <localita_ben_quiet>
       mifCountRec:=mifCountRec+1; --66
       if isIndirizzoBenQuiet=true then -- 26.01.2016 SofiaJira
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --66
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
--        	 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',com.validita_inizio)
-- 		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(com.validita_fine,dataFineVal));

	            if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_localita_quiet:=substring(flussoElabMifValore from 1 for 30);
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
       end if;

       mifCountRec:=mifCountRec+1; --67
	   -- <provincia_ben_quiet>
	   if isIndirizzoBenQuiet=true then -- 26.01.2016 SofiaJira
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];-- 67
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
--	         	and   date_trunc('day',dataElaborazione)>=date_trunc('day',provRel.validita_inizio)
-- 			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(provRel.validita_fine,dataFineVal))
        	    and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
---	         	and   date_trunc('day',dataElaborazione)>=date_trunc('day',prov.validita_inizio)
---			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(prov.validita_fine,dataFineVal))
        	    order by provRel.data_creazione;

	            if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_prov_quiet:=flussoElabMifValore;
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
       end if;

       mifCountRec:=mifCountRec+1; --68
	   -- <partita_iva_ben_quiet>
	   if soggettoQuietId is not null THEN
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --68
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
                -- 01.02.2016 Sofia -- adeguamenti come beneficiario
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
                    -- 03.03.2017 Sofia HD-INC000001595140-COAL
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifParam is not null then
                       if soggettoQuietRifRec.codice_fiscale is not null  and
                          length(soggettoQuietRifRec.codice_fiscale)=16  THEN
                          flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                       end if;
                       if flussoElabMifValore is null and
	                      flussoElabMifElabRec.flussoElabMifDef is not null then
                       	  flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
    	               end if;
                    end if;
                    -- 03.03.2017 Sofia HD-INC000001595140-COAL

--                elsif soggettoQuietRec.partita_iva is not null then
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
--                	flussoElabMifValore:=soggettoQuietRec.partita_iva;

                    -- 03.03.2017 Sofia HD-INC000001595140-COAL
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifParam is not null then
                       if soggettoQuietRec.codice_fiscale is not null  and
                          length(soggettoQuietRec.codice_fiscale)=16  THEN
                          flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                       end if;

                       if flussoElabMifValore is null and
	                      flussoElabMifElabRec.flussoElabMifDef is not null then
                       	  flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
    	               end if;

                    end if;
                    -- 03.03.2017 Sofia HD-INC000001595140-COAL

                end if;

			    if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_partiva_quiet:=flussoElabMifValore;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
       end if;

       mifCountRec:=mifCountRec+1; -- 69
       -- <codice_fiscale_ben_quiet>
       if soggettoQuietId is not null  then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 69
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
                 if soggettoQuietRifRec.partita_iva is null then
                  if soggettoQuietRifRec.codice_fiscale is not null and
--                     length(soggettoQuietRifRec.codice_fiscale) in (16,11) then
                     length(soggettoQuietRifRec.codice_fiscale)= 16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                  elsif
                   (soggettoQuietRifRec.codice_fiscale is null or
                    (soggettoQuietRifRec.codice_fiscale is not null and length(soggettoQuietRifRec.codice_fiscale) not in (11,16))) then
                     flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                  end if;
                 end if;
                elsif soggettoQuietRec.partita_iva is null then
                 if soggettoQuietRec.codice_fiscale is not null and
--                    length(soggettoQuietRec.codice_fiscale) in (16,11) then
                    length(soggettoQuietRec.codice_fiscale)=16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
				 elsif
                   (soggettoQuietRec.codice_fiscale is null or
                    (soggettoQuietRec.codice_fiscale is not null and length(soggettoQuietRec.codice_fiscale) not in (11,16))) then
                 	 flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                 end if;
                end if;

				if length(flussoElabMifValore)=16 then -- 15.02.2016 Sofia-JIRA-SIAC-XXXX-ABI36
	                mifFlussoOrdinativoRec.mif_ord_codfisc_quiet:=flussoElabMifValore;
                elsif length(flussoElabMifValore)=11 then
	                mifFlussoOrdinativoRec.mif_ord_partiva_quiet:=flussoElabMifValore;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
       end if;

       -- 08.11.2016 Sofia JIRA SIAC-4158 - campo valorizzato poi in piazzatura
       -- <stato_delegato>
       if soggettoQuietId is not null  then
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_STATO_DELEGATO]; --199
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_STATO_DELEGATO
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--         if flussoElabMifElabRec.flussoElabMifId is null then
--            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
--         end if;

	   -- solo ed esclusivamente in questo caso
       -- utilizzo questo test per sapere se il tag e configurato o non
       -- in tutti gli altri casi le strutture devono essere identiche !!!
       if flussoElabMifElabRec.flussoElabMifId is not  null then
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
         	if statoDelegatoAbi36=false then
	            statoDelegatoAbi36:=true;
            end if;
          else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
       end if;


       -- <delegato>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       isMDPCo:=false;
       mifCountRec:=mifCountRec+1; -- 70
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 70
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
                        /*select 1 into isMDPCo
                        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
                        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
                        and   tipo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
                        and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
                        and   gruppo.accredito_gruppo_code=tipoMDPCo
                        and   gruppo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',gruppo.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(gruppo.validita_fine,dataFineVal));*/
                    end if;

                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        mifCountRec:=mifCountRec+2; -- 72
        if isMDPCo=true then
        	-- <anagrafica_delegato>
        	flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;

     	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1]; --71
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
                	if MDPRec.quietanziante is not null then
                    	mifFlussoOrdinativoRec.mif_ord_anag_del:=MDPRec.quietanziante;
                    end if;
           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		         end if;
	        end if;
			-- codice_fiscale_delegato da valorizzare solo se valorizzato anche quietanzante
            if MDPRec.quietanziante is not null then
	         -- <codice_fiscale_delegato>
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
                	if MDPRec.quietanziante_codice_fiscale is not null and
--                       length(MDPRec.quietanziante_codice_fiscale) in (11,16) then
                       length(MDPRec.quietanziante_codice_fiscale)=16 then -- 28.02.2017 Sofia HD-INC000001587525
                    	flussoElabMifValore:=trim ( both ' ' from MDPRec.quietanziante_codice_fiscale); -- 27.02.2017 Sofia HD-INC000001587525
                    elsif flussoElabMifElabRec.flussoElabMifDef is not null then
                    	flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_codfisc_del:=flussoElabMifValore;
                    end if;

           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		        end if;
	         end if;

         end if;
        end if;
		-- <cap_delegato>
        -- <localita_delegato>
        -- <provincia_delegato>
        mifCountRec:=mifCountRec+3; -- 75

		-- calcolo gi? qui il flag_copertura perch? serve anche per invio_avviso
    	-- <flag_copertura>
        flussoElabMifElabRec:=null;
        isOrdACopertura:=false;
       -- mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_FLAG_COPERTURA];
		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_FLAG_COPERTURA
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if 	flussoElabMifElabRec.flussoElabMifParam is not null then

            	select * into isOrdACopertura
                from fnc_mif_ordinativo_a_copertura(mifOrdinativoIdRec.mif_ord_ord_id,
                                                    MDPRec.accredito_tipo_id,
				   							        flussoElabMifElabRec.flussoElabMifParam,
                                                    dataElaborazione,
                                                    dataFineVal,
                                                    enteProprietarioId);

               if isOrdACopertura=true and  flussoElabMifElabRec.flussoElabMifDef is not null then
	               mifFlussoOrdinativoRec.mif_ord_flag_copertura:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

            end if;
         else
         	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <avviso>
        -- calcolo se valorizzare il successivo campo per il tag invio_avviso
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       isMDPCo:=false;
       isInvioAvviso:=false;
       mifCountRec:=mifCountRec+1; --76
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 76
 	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       /*strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.avviso
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.avviso ,enteProprietarioId);*/
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
--      -- 19.09.2017 Sofia JIRA SIAC-5231         flussoElabMifElabRec.flussoElabMifDef   is not null then
                    if avvisoTipoMDPCo is null then
                    	avvisoTipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;
                    if avvisoTipoClassCode is null then
                    	avvisoTipoClassCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    if avvisoTipoClassCode is not null and avvisoTipoClassCodeId is null then
                    	select tipo.classif_tipo_id into avvisoTipoClassCodeId
                        from siac_d_class_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.classif_tipo_code=avvisoTipoClassCode
                        and   tipo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
 		 		   		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
                    end if;

                    -- inizio calcolo isInvioAvviso
                    -- isInvioAvviso = true se


                    -- siac_t_indirizzo.avviso='S' per indirizzo_ben_quiet o indirizzo_beneficiario
                       --  avvisoBenQuiet is not null --> avvisoBenQuiet='S'
                       --  elsif avvisoBenef is not null --> avvisoBenef='S'

                    if avvisoBenQuiet is not null and  avvisoBenQuiet='S' then
                    	isInvioAvviso:=true;
            		elsif avvisoBenef is not null and avvisoBenef='S' then
                    	isInvioAvviso:=true;
                    end if;

					-- and ordinativo non a copertura
                    if isInvioAvviso=true and isOrdACopertura=true then
                    	isInvioAvviso:=false;
                    end if;

                    -- and isMDPCo = true
		            if isInvioAvviso=true and avvisoTipoMDPCo is not null then
                    	if avvisoTipoMDPCo!=codAccreRec.accredito_gruppo_code then
	                        isInvioAvviso:=false;
                        end if;

                    	/*select distinct 1 into isMDPCo
                        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
                        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
                        and   tipo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
                        and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
                        and   gruppo.accredito_gruppo_code=avvisoTipoMDPCo
                        and   gruppo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',gruppo.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(gruppo.validita_fine,dataFineVal));

                        if isMDPCo is null then
                        	isInvioAvviso:=false;
                        end if;*/
                   end if;

                    -- and esiste siac_t_ordinativo_class per avvisoTipoClassCodeId
                   codResult:=null;
-- 19.09.2017 Sofia JIRA SIAC-5231
--                    if isInvioAvviso=true and avvisoTipoClassCodeId is not null then
                   if isOrdACopertura=false and isInvioAvviso=false and
                      avvisoTipoClassCodeId is not null then

                    	select distinct 1 into codResult
                        from siac_r_ordinativo_class classOrd, siac_t_class class
                        where classOrd.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                        and   classOrd.classif_id=class.classif_id
                        and   classOrd.data_cancellazione is null
                        and   classOrd.validita_fine is null
--         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',classOrd.validita_inizio)
-- 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(classOrd.validita_fine,dataFineVal))
                        and   class.classif_tipo_id=avvisoTipoClassCodeId
                        and   class.data_cancellazione is null; -- 19.01.2017
--         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
-- 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017


/* 19.09.2017 Sofia JIRA SIAC-5231

                        if codResult is null then
                        	isInvioAvviso:=false;
                        end if;*/

                        if codResult is not null then
                        	isInvioAvviso:=true;
                        end if;

		            end if;

                    if isInvioAvviso=true then
                    	mifFlussoOrdinativoRec.mif_ord_invio_avviso:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

       mifCountRec:=mifCountRec+1;
       if isInvioAvviso=true then
        -- <invio_avviso>
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
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_invio_avviso:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

      -- <codice_fiscale_avviso>
	  mifCountRec:=mifCountRec+1;

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
      if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
      	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
--			raise notice '%', strMessaggio;
            isOrdPiazzatura:=fnc_mif_ordinativo_piazzatura(MDPRec.accredito_tipo_id,
                                                           mifOrdinativoIdRec.mif_ord_codice_funzione,
													       flussoElabMifElabRec.flussoElabMifParam,
			                                               dataElaborazione,dataFineVal,enteProprietarioId);
            end if;
      	else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      mifCountTmpRec:=mifCountRec;
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
		/*select  gruppo.accredito_gruppo_code into accreditoGruppoCode
        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
        and   tipo.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
        and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
        and   gruppo.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',gruppo.validita_inizio)
 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(gruppo.validita_fine,dataFineVal));

        if accreditoGruppoCode is null then
        	raise exception ' Dato non trovato.';
        end if;*/

        if MDPRec.iban is not null and length(MDPRec.iban)>2  then
        	select distinct 1 into isPaeseSepa
            from siac_t_sepa sepa
            where sepa.sepa_iso_code=substring(upper(MDPRec.iban) from 1 for 2)
            and   sepa.ente_proprietario_id=enteProprietarioId
            and   sepa.data_cancellazione is null
      	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
-- 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(sepa.validita_fine,dataFineVal)); 19.01.2017
 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));
        end if;

      	-- <abi_beneficiario>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                		--	raise notice '%', strMessaggio;
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 6 for 5);
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_abi_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;

    	-- <cab_beneficiario>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 11 for 5);
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cab_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;

        -- <numero_conto_corrente_beneficiario>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 16 for 12);
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cc_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;


          -- <caratteri_controllo>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 3 for 2);
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_ctrl_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;

        -- <codice_cin>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 5 for 1);
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cin_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;

        -- <codice_paese>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 1 for 2);
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cod_paese_benef:=flussoElabMifValore;
                        -- 18.01.2016 Sofia ABI36
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true then
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                        -- 08.11.2016 Sofia ABI36 JIRA SIAC-4158
                        if statoDelegatoAbi36=true then
	                        mifFlussoOrdinativoRec.mif_ord_stato_quiet:=flussoElabMifValore;
                        end if;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
       end if;

       mifCountTmpRec:=mifCountTmpRec+2;
	    -- extra sepa
        if isPaeseSepa is null then
        -- <denominazione_banca_destinataria>
		 flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec-1];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

	     -- <conto_corrente_estero>
         flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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
                       MDPRec.iban is not null and length(MDPRec.iban)>=2  then
                       	flussoElabMifValore:=MDPRec.contocorrente;
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cc_benef_estero:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;



        end if;

        -- estero sepa e extrasepa
        -- <codice_swift>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+2;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>=2 and
                       substring(upper(MDPRec.iban) from 1 for 2)!=tipoPaeseCB then
                       	flussoElabMifValore:=MDPRec.bic;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_swift_benef:=flussoElabMifValore;
                    end if;

                    -- 21.01.2016 Sofia ABI36 sepaTr -- 15.02.2016 Sofia-JIRA-SIAC-XXXX - solo paesi sepa esteri
                    if isPaeseSepa is not null and
                       sepaCreditTransfer=true and accreditoGruppoSepaTr=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
	                    mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr:=MDPRec.bic;
                        -- se sepaCreditTransfer -- no piazzatura
                        mifFlussoOrdinativoRec.mif_ord_swift_benef:=null;
                    end if;

    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

        -- <coordinate_iban>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        mifCountTmpRec:=mifCountTmpRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
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

					-- 21.01.2016 Sofia ABI36 sepaTr
                    if (( tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode ) or
                        (sepaCreditTransfer=true and accreditoGruppoSepaTr=accreditoGruppoCode)) and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 then -- 22.01.2016 Sofia
--                       MDPRec.iban is not null and length(MDPRec.iban)>=2 then

                       if substring(upper(MDPRec.iban) from 1 for 2)!=tipoPaeseCB then
                        mifFlussoOrdinativoRec.mif_ord_iban_benef:=MDPRec.iban;
                       end if;
                       -- 19.01.2016 Sofia ABI36
                       /*if statoBeneficiario=true then
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=substring(upper(MDPRec.iban) from 1 for 2);
                       end if; spostato sotto */

                       -- 21.01.2016 Sofia ABI36 sepaTr
                       if isPaeseSepa is not null and
                          sepaCreditTransfer=true and accreditoGruppoSepaTr=accreditoGruppoCode and
                          MDPRec.iban is not null and length(MDPRec.iban)>2 and
	                      substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then -- 15.02.2016 Sofia-SIAC-XXXX-ABI36 solo paesi esteri sepa
	                        mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr:=MDPRec.iban;

                            -- se sepaCreditTransfer no piazzatura
                            mifFlussoOrdinativoRec.mif_ord_iban_benef:=null;
                       end if;

                    end if;

                    -- 22.01.2016 Sofia ABI36
                    if (( tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode ) or
                        (sepaCreditTransfer=true and accreditoGruppoSepaTr=accreditoGruppoCode)) and
                       MDPRec.iban is not null and length(MDPRec.iban)>=2 then
                       if statoBeneficiario=true then
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=substring(upper(MDPRec.iban) from 1 for 2);
                       end if;

                       -- 08.11.2016 Sofia ABI36 JIRA SIAC-4158
                       if statoDelegatoAbi36=true then
	                        mifFlussoOrdinativoRec.mif_ord_stato_quiet:=substring(upper(MDPRec.iban) from 1 for 2);
                       end if;
				    end if;

    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

        -- <conto_corrente_postale>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_CC_POSTALE];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_CC_POSTALE
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCCP is null then
	                    tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;

                    if tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode and
					   MDPRec.contocorrente is not null	 then
--                        mifFlussoOrdinativoRec.mif_ord_cc_postale_benef:=MDPRec.contocorrente; JIRA SIAC-2999 09.02.2016 Sofia
                        mifFlussoOrdinativoRec.mif_ord_cc_postale_benef:=
                            lpad(MDPRec.contocorrente,NUM_DODICI,ZERO_PAD);
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

      end if;
      -- quanti sono i tag della piazzatura
      mifCountRec:=mifCountRec+11;

      -- <codice_ente_beneficiario>
      -- <flag_pagamento_condizionato>
      mifCountRec:=mifCountRec+2;

      -- <sepa_credit_transfer>
	  if isPaeseSepa is not null and sepaCreditTransfer=true and
         MDPRec.iban is not null and length(MDPRec.iban)>2 and
         substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then -- 15.02.2016 Sofia JIRA-SIAC-XXXX-ABI36 sepa_credit_transfer solo per paesi esteri sepa
        -- <iban>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_SEPA_CREDIT_T+1];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_SEPA_CREDIT_T+1
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
              -- valorizzato in piazzatura
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
        else
               mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr:=null;
     	end if;

        -- <bic>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_SEPA_CREDIT_T+2];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_SEPA_CREDIT_T+2
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
            if flussoElabMifElabRec.flussoElabMifElab=true then
              -- valorizzato in piazzatura
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
        else
               mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr:=null;
     	end if;

        -- <identificativo_end_to_end>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_SEPA_CREDIT_T+3];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
					   ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_SEPA_CREDIT_T+3
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
               if flussoElabMifElabRec.flussoElabMifDef is not null and -- 30.05.2016 Sofia JIRA-SIAC-3645
                  mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr is not null then -- il bic potrebbe anche non esserci
/* 30.05.2016 Sofia JIRA-SIAC-3645
	              mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr:=mifOrdinativoIdRec.mif_ord_anno_bil||'-'
              											   ||mifOrdinativoIdRec.mif_ord_ord_numero||'-'
                                                           ||soggettoRec.soggetto_code;*/
	              mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr:=mifOrdinativoIdRec.mif_ord_anno_bil||'-'
              											   ||mifOrdinativoIdRec.mif_ord_ord_numero||'-'
                                                           ||flussoElabMifElabRec.flussoElabMifDef; -- 30.05.2016 Sofia JIRA-SIAC-3645

               end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

      end if;


      -- <ritenute>
      mifCountRec:=mifCountRec+5;
      -- <esenzione>
      ordCodiceBollo:=null;
      ordCodiceBolloDesc:=null;
      isOrdBolloEsente:=false;
      mifCountRec:=mifCountRec+1;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then
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
        	if flussoElabMifElabRec.flussoElabMifDef is not null and
               flussoElabMifElabRec.flussoElabMifParam is not null then
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';


               select bollo.codbollo_code, bollo.codbollo_desc into ordCodiceBollo,ordCodiceBolloDesc
               from siac_d_codicebollo bollo
               where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id;

               if ordCodiceBollo is null then
               	RAISE EXCEPTION ' Errore in lettura dato.';
               end if;

               isOrdBolloEsente:=fnc_mif_ordinativo_esenzione_bollo(ordCodiceBollo,flussoElabMifElabRec.flussoElabMifParam);
               if isOrdBolloEsente=true then
                if valBolloEsente is null then
	               	valBolloEsente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                end if;
                flussoElabMifValore:=valBolloEsente;
               else
                if valBolloNonEsente is null then
	               	valBolloNonEsente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
                flussoElabMifValore:=valBolloNonEsente;
               end if;

               if flussoElabMifValore is not null then
               	mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=flussoElabMifValore;
               end if;

            end if;
	 	else
        	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;

	  mifCountRec:=mifCountRec+2;
      -- <carico_bollo>
      -- ABI36
      if isOrdBolloEsente=false and
         mifOrdinativoIdRec.mif_ord_codbollo_id is not null  then
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1];
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
               if ordCodiceBollo is null then -- ABI36
            	 select bollo.codbollo_code, bollo.codbollo_desc into ordCodiceBollo,ordCodiceBolloDesc
	               from siac_d_codicebollo bollo
    	           where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id;

	               if ordCodiceBollo is null then
    	           	RAISE EXCEPTION ' Errore in lettura dato.';
        	       end if;
                end if;

            	flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( ordCodiceBollo,flussoElabMifElabRec.flussoElabMifParam);
                if flussoElabMifValore is not null then
                		mifFlussoOrdinativoRec.mif_ord_bollo_carico:=flussoElabMifValore;
                end if;
            end if;
     	 else
        	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
        end if;
	  else
       -- <causale_esenzione_bollo>
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
        	if ordCodiceBolloDesc is not null then
	       		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
            end if;
     	 else
        	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
        end if;
      end if;
     end if;

     -- <Importo_bollo>
     -- <carico_spese>
     -- <importo_spese>
     mifCountRec:=mifCountRec+3;

     mifCountRec:=mifCountRec+1;
     commissioneCode:=null; -- 05.02.2016 Sofia
     -- <carico_commissioni>
     if mifOrdinativoIdRec.mif_ord_comm_tipo_id is not null then
     	 flussoElabMifElabRec:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura commissioni.';


                	select tipo.comm_tipo_code  into flussoElabMifValore
                    from siac_d_commissione_tipo tipo
                    where tipo.comm_tipo_id=mifOrdinativoIdRec.mif_ord_comm_tipo_id;
                    --and   tipo.data_cancellazione is null
        	   		--and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    	   		--and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

                  --  raise notice 'commissione_tipo_code=%',flussoElabMifValore ;
                    if flussoElabMifValore is null then
                   		RAISE EXCEPTION ' Errore in lettura dato.';
                    end if;

                    -- 05.02.2016 Sofia
                    commissioneCode:=flussoElabMifValore;

                	flussoElabMifValoreDesc:=fnc_mif_ordinativo_carico_bollo( flussoElabMifValore,
					                                                          flussoElabMifElabRec.flussoElabMifParam);
                   -- raise notice 'commissione_carico=%',flussoElabMifValoreDesc ;
        			if flussoElabMifValoreDesc is not null then
			       		mifFlussoOrdinativoRec.mif_ord_commissioni_carico:=flussoElabMifValoreDesc;
            		end if;
               end if; -- param
     		else
        		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if; -- elab
        end if; -- attivo


     end if; -- comm_tipo_if

	 -- 05.02.2016 Sofia -- riciclato per <causale_esenzione_spese>
     -- <importo_commissioni>
     mifCountRec:=mifCountRec+1;
     if commissioneCode is not null then
     	 flussoElabMifElabRec:=null;
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
	     if flussoElabMifElabRec.flussoElabMifId is null then
      	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       	 end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
       	 	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
                	flussoElabMifValoreDesc:=fnc_mif_ordinativo_carico_bollo( commissioneCode,
					                                                          flussoElabMifElabRec.flussoElabMifParam);

        			if flussoElabMifValoreDesc is not null then
			       		mifFlussoOrdinativoRec.mif_ord_commissioni_importo:=flussoElabMifValoreDesc;
            		end if;
                end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
            end if;
         end if;
     end if;

	 -- <natura_pagamento>
     --mifCountRec:=mifCountRec+1;
     if commissioneCode is not null then
     	 flussoElabMifElabRec:=null;
      	 flussoElabMifValore:=null;
         flussoElabMifValoreDesc:=null;

         flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NATURA_PAGAM];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||FLUSSO_MIF_ELAB_NATURA_PAGAM
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       	 end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
       	 	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
                	flussoElabMifValoreDesc:=fnc_mif_ordinativo_carico_bollo( commissioneCode,
					                                                          flussoElabMifElabRec.flussoElabMifParam);

        			if flussoElabMifValoreDesc is not null then
			       		mifFlussoOrdinativoRec.mif_ord_commissioni_natura:=flussoElabMifValoreDesc;
            		end if;
                end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
            end if;
         end if;
     end if;

	 -- <tipo_pagamento>
     flussoElabMifElabRec:=null;
     tipoPagamRec:=null;
	 mifCountRec:=mifCountRec+1; --109
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
            	if codicePaeseIT is null then
                	codicePaeseIT:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if codiceAccreCB is null then
	                codiceAccreCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if codiceAccreCO is null then
	                codiceAccreCO:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;
				if codiceSepa is null then
	                codiceSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                end if;
--			raise notice '1 %', strMessaggio;
                select * into tipoPagamRec
                from fnc_mif_tipo_pagamento( mifOrdinativoIdRec.mif_ord_ord_id,
											 (case when MDPRec.iban is not null and length(MDPRec.iban)>=2
                                                   then substring(MDPRec.iban from 1 for 2)
                                                   else null end),
                                             codicePaeseIT,codiceSepa,
                                             (case when MDPRec.contocorrente is not null then TRUE else FALSE END),
											 (case when MDPRec.bic is not null then TRUE else FALSE END),
                                             (case when MDPRec.banca_denominazione is not null then TRUE else FALSE END),
                                             codiceAccreCB,codiceAccreCO,
                                             enteOilRec.ente_oil_firma_manleva,
 											 MDPRec.accredito_tipo_id,
                                             dataElaborazione,dataFineVal, -- QUI QUI
                                             enteProprietarioId);
--			raise notice '2 %', strMessaggio;

                if tipoPagamRec is not null then
                	if tipoPagamRec.descTipoPagamento is not null then
                    	mifFlussoOrdinativoRec.mif_ord_pagam_tipo:=tipoPagamRec.descTipoPagamento;
                    end if;
                end if;

	        end if; -- param
     	else
       		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if; -- elab
     end if;

     -- <codice_pagamento>
     mifCountRec:=mifCountRec+1; --110
--    			raise notice '3 %', strMessaggio;

     if tipoPagamRec is not null then --- qui
     	if tipoPagamRec.codeTipoPagamento is not null then
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
--			raise notice '%', strMessaggio;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
	 		if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_pagam_code:=tipoPagamRec.codeTipoPagamento;
        	else
       			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if; -- elab
    	 end if;

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
     		mifFlussoOrdinativoRec.mif_ord_pagam_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <causale>
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
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	-- 16.02.2016 Sofia JIRA-SIAC-3035
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
--     		mifFlussoOrdinativoRec.mif_ord_pagam_causale:=substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370);
-- 09.02.2016 Sofia JIRA SIAC-2998


            -- 16.02.2016 Sofia JIRA-SIAC-3035
            -- cup
--            raise notice 'mifOrdinativoIdRec.mif_ord_ord_numero %',mifOrdinativoIdRec.mif_ord_ord_numero;
--            raise notice 'CUP %', flussoElabMifValore;
			if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                	/*mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
                      trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||' '||cupCausAttr||' '||flussoElabMifValore);*/
			       	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=cupCausAttr||' '||flussoElabMifValore;

            end if;
--			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;

--            raise notice 'cig %',flussoElabMifValoreDesc;
            -- cig
			if coalesce(flussoElabMifValoreDesc,NVL_STR)!=NVL_STR  then
                	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
                      trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||
                           ' '||cigCausAttr||' '||flussoElabMifValoreDesc);
            end if;
  --- 			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;


            /*mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
	            replace(replace(substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);*/

            -- 16.02.2016 Sofia JIRA-SIAC-3035
            mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
      			replace(replace(substring(trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||' '||mifOrdinativoIdRec.mif_ord_desc )
	                            from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

--			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
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
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza.';
--			raise notice '%', strMessaggio;
        	select sub.ord_ts_data_scadenza into ordDataScadenza
            from siac_t_ordinativo_ts sub
            where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;

            -- 05.02.2016 Sofia JIRA-2977
            if ordDataScadenza is not null and
               date_trunc('DAY',ordDataScadenza)>= date_trunc('DAY',dataElaborazione) and
               extract('year' from ordDataScadenza)::integer<=annoBilancio::integer then
		  		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec:=
    		        extract('year' from ordDataScadenza)||'-'||
    	         	lpad(extract('month' from ordDataScadenza)::varchar,2,'0')||'-'||
            	 	lpad(extract('day' from ordDataScadenza)::varchar,2,'0');
            end if;

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

    -- <data_scadenza_pagamento>
	-- <flag_valuta_antergata>
	-- <divisa_estera_conversione>
	-- <flag_assegno_circolare>
	-- <flag_vaglia_postale>
	mifCountRec:=mifCountRec+5;

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
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

    -- <riferimento_documento_esterno>
    mifCountRec:=mifCountRec+1;
--    			raise notice '4 %', strMessaggio;

    if tipoPagamRec is not null then
     if tipoPagamRec.defRifDocEsterno=true then
    	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    /*    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.riferimento_documento_esterno
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    select * into flussoElabMifElabRec
    	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.riferimento_documento_esterno ,enteProprietarioId);*/
	    if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;
    	if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null then
	                mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifElabRec.flussoElabMifDef;
		        end if;
			else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if;
    	end if;
     end if;
    end if;

    -- <informazioni_tesoriere>
	flussoElabMifElabRec:=null;
    flussoElabMifValore:=null;
    mifCountRec:=mifCountRec+1;
    codResult:=null; -- 01.09.2016 Sofia HD-INC000001204673
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
        	impostaInfoTes:=true;  -- 01.09.2016 Sofia HD-INC000001204673
        	-- 01.09.2016 Sofia HD-INC000001204673 - ABI36 gestione informazioni tesoriere su riferimento_documento_esterno
            -- solo per accredito_oil='DISPOSIZIONE DOCUMENTO ESTERNO'
            -- raise notice 'QUI QUI QUI % %',flussoElabMifElabRec.flussoElabMifParam,codAccreRec.accredito_tipo_id;

            if flussoElabMifElabRec.flussoElabMifParam is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura accredito tipo oil ['
                       ||flussoElabMifElabRec.flussoElabMifParam||'] .';
            	select 1 into codResult
                from siac_d_accredito_tipo_oil oil,siac_r_accredito_tipo_oil r
                where r.accredito_tipo_id=codAccreRec.accredito_tipo_id
                and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
                and   oil.accredito_tipo_oil_desc=flussoElabMifElabRec.flussoElabMifParam
                and   r.data_cancellazione is null
                and   r.validita_fine is null;
	           -- raise notice 'codResult=%',codResult;
                if codResult is  null then
                	impostaInfoTes:=false;
                end if;

            end if;

            -- 01.09.2016 Sofia HD-INC000001204673
            if impostaInfoTes=true then
         	 flussoElabMifValore:=fnc_mif_ordinativo_informazioni_tes(mifOrdinativoIdRec.mif_ord_ord_id,
              												    --mifOrdinativoIdRec.mif_ord_notetes_id,
                                                                mifOrdinativoIdRec.mif_ord_note_attr_id, -- 27.11.2015 Sofia note ordinativo nelle note al tesoriere
            													enteProprietarioId,
                                                                dataInizioVal,dataFineVal);
            --  raise notice 'info tes. %', flussoElabMifValore;
            end if;


            if flussoElabMifValore is not null then
--            	mifFlussoOrdinativoRec.mif_ord_info_tesoriere:=flussoElabMifValore; 09.02.2016 Sofia JIRA SIAC-2998

                mifFlussoOrdinativoRec.mif_ord_info_tesoriere:=
                	replace(replace(flussoElabMifValore , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

            end if;
        else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		end if;
    end if;

    -- <tipo_utenza>
	-- <codifica_utenza>il
	-- <codice_generico>
    mifCountRec:=mifCountRec+3;

	-- <flag_copertura>
    mifCountRec:=mifCountRec+3;
    -- <ricevute>

    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    -- <sostituzione_mandato>
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
/*    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.sostituzione_mandato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    select * into flussoElabMifElabRec
    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.sostituzione_mandato ,enteProprietarioId);*/
    if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        --	if flussoElabMifElabRec.flussoElabMifParam is not null then
            --    if ordRelazCodeTipoId is not null then
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);
             --   end if;
       --     end if;
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
         -- <numero_mandato_collegato>
/*      	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_mandato_collegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   	 	 select * into flussoElabMifElabRec
      	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_mandato_collegato ,enteProprietarioId);*/
      	 if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;

      	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	   if flussoElabMifElabRec.flussoElabMifElab=true then
        		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
	    	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     	end if;
         end if;

     	-- <progressivo_mandato_collegato>
     	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    /*strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.progressivo_mandato_collegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	select * into flussoElabMifElabRec
	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.progressivo_mandato_collegato ,enteProprietarioId);*/
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

        -- <esercizio_mandato_collegato>
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
/*	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.esercizio_mandato_collegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	select * into flussoElabMifElabRec
	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.esercizio_mandato_collegato ,enteProprietarioId);*/
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

  mifCountRec:=mifCountRec+NUMERO_DATI_DISP_ENTE;	-- dati_a_disposizione_ente

-- raise notice 'fine dati a disposizione ente %',mifCountRec;
  -- <InfSerMan_NumeroImpegno>
  mifCountRec:=mifCountRec+1;
  -- <InfSerMan_SubImpegno>
  mifCountRec:=mifCountRec+1;

  -- <InfSerMan_CodiceOperatore>

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
 --raise notice '% %',strMessaggio,mifCountRec;
  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  end if;
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	--raise notice '%',strMessaggio;
        -- 21.04.2017 Sofia SIAC-4783
    	/*if mifOrdinativoIdRec.mif_ord_login_modifica is not null then
        	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_modifica;
        elsif mifOrdinativoIdRec.mif_ord_login_creazione is not null then
        	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
        end if;*/
        -- 21.04.2017 Sofia SIAC-4783

        if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
        end if;

		-- 16.02.2017 Sofia HD-INC000001562461
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
--	     	mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12); 16.02.2017 Sofia HD-INC000001562461
            -- 21.04.2017 Sofia SIAC-4783
            --mifFlussoOrdinativoRec.mif_ord_code_operatore:=flussoElabMifValore;
            -- 21.04.2017 Sofia SIAC-4783
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
        end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <InfSerMan_NomeOperatore>
  mifCountRec:=mifCountRec+1;

  -- <InfSerMan_Fattura_Descr>
  mifCountRec:=mifCountRec+1;
  -- spostato dopo insert in mif_t_ordinativo_spesa

  -- <InfSerMan_DescrizioniEstesaCapitolo>
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
--                       raise notice '% %', strMessaggio,mifCountRec;
  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  end if;
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
	     	mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap:=substring(bilElemRec.elem_desc from 1 for 150);
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <InfSerMan_DescrCapitolo>
  -- <InfSerMan_ProgSpesa
  -- <InfSerMan_TipoSpesa

  -- <siope_codice_cge> -- popolati sopra  in corrispondenza dei campi analoghi su siope
  -- <siope_descr_cge>
  mifCountRec:=mifCountRec+5;


        -- sicuramente non attivi per cui li gestisco alla fine
        -- <flg_finanza_locale>
        -- <numero_documento>
        -- <data_provvedimento_autorizzativo>
        -- <responsabile_provvedimento>
        -- <ufficio_responsabile>
		-- <progressivo_mandato_struttura>
		-- <Tipo_Contabilita>
        -- <Impignorabili>
        -- <Destinazione>
		-- <Codice_cup>
        -- <Codice_cpv>
        -- <voce_economica>
		-- <stanziamento>
        -- <mandati_stanziamento>
		-- <disponibilita_capitolo>
		-- <cap_delegato>
        -- <localita_delegato>
        -- <provincia_delegato>
        -- <codice_fiscale_avviso>
        -- <codice_ente_beneficiario>
        -- <flag_pagamento_condizionato>
        -- <Importo_bollo>
        -- <carico_spese>
        -- <importo_spese>
        -- <data_scadenza_pagamento>
        -- <flag_valuta_antergata>
        -- <divisa_estera_conversione>
        -- <flag_assegno_circolare>
        -- <flag_vaglia_postale>
		-- <tipo_utenza>
        -- <codifica_utenza>
        -- <codice_generico>
        -- <Capitolo_Peg>
        -- <Vincoli_di_destinazione>
        -- <Vincolato>
        -- <Voce_Economica>
        -- <Numero_distinta_bilancio>
        -- <Numero_reversale_vincolata>
        -- <Liquidazione>
        -- <InfSerMan_NomeOperatore>
		-- <InfSerMan_DescrCapitolo>
        -- <InfSerMan_ProgSpesa>
        -- <codice_cge>
        -- <descr_cge>

        -- gestisti direttamente in insert
        -- <identificativo_flusso>
        -- <data_ora_creazione_flusso>
        -- <anno_flusso>
	    -- <InfSerMan_TipoSpesa>

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
  		 mif_ord_codice_uff_resp,
  		 --mif_ord_data_attoamm,
 		 --mif_ord_resp_attoamm,
  		 --mif_ord_uff_resp_attomm,
  		 mif_ord_codice_abi_bt,
  		 mif_ord_codice_ente,
  		 mif_ord_desc_ente,
  		 mif_ord_codice_ente_bt,
  		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil, -- 18.04.2016 Sofia
  		 mif_ord_id_flusso_oil,
  		 mif_ord_data_creazione_flusso,
  		 mif_ord_anno_flusso,
 		 mif_ord_codice_struttura,
 		 --mif_ord_progr_ord_struttura,
  		 mif_ord_ente_localita,
  		 mif_ord_ente_indirizzo,
 		 --mif_ord_codice_cge,
 		 --mif_ord_descr_cge,
 		 --mif_ord_tipo_contabilita,
 		 mif_ord_codice_raggrup,
  		 mif_ord_progr_benef,
  		 --mif_ord_progr_impignor,
         mif_ord_progr_dest,
  		 mif_ord_bci_conto,
  		 mif_ord_bci_tipo_contabil, -- 14.03.2016 Sofia ABI36
  		 mif_ord_class_codice_cge,
  		 mif_ord_class_importo,
  		 --mif_ord_class_codice_cup,
 		 --mif_ord_class_codice_cpv,
  		 mif_ord_class_codice_gest_prov, -- 23.02.2016 Sofia JIRA-SIAC-3032
  		 mif_ord_class_codice_gest_fraz,
  		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
  		 mif_ord_articolo,
  		 --mif_ord_voce_eco,
  		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil, -- 11.01.2016 Sofia
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
	     mif_ord_stato_quiet, -- 08.11.2016 Sofia ABI36 JIRA SIAC-4158
  		 mif_ord_anag_del,
  		 mif_ord_codfisc_del,
  		 --mif_ord_cap_del,
  		 --mif_ord_localita_del,
  		 --mif_ord_prov_del,
  		 mif_ord_invio_avviso,
  		 --mif_ord_codfisc_avviso,
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
  		 --mif_ord_cod_ente_benef,
  		 --mif_ord_fl_pagam_cond_benef,
  		 mif_ord_bollo_esenzione,
  		 mif_ord_bollo_carico,
  		 mif_ordin_bollo_caus_esenzione,
  		-- mif_ord_bollo_importo,
  		 --mif_ord_bollo_carico_spe,
  		-- mif_ord_bollo_importo_spe,
  		 mif_ord_commissioni_carico,
  		 mif_ord_commissioni_importo, -- 05.02.2016 Sofia
         mif_ord_commissioni_natura, -- 16.02.2016 Sofia
  		mif_ord_pagam_tipo,
  		mif_ord_pagam_code,
  		 mif_ord_pagam_importo,
  		 mif_ord_pagam_causale,
  		 mif_ord_pagam_data_esec,
  		 --mif_ord_pagam_data_scad,
  		 --mif_ord_pagam_flag_val_ant,
  		 --mif_ord_pagam_divisa_estera,
  		 --mif_ord_pagam_flag_ass_circ,
  		 --mif_ord_pagam_flag_vaglia,
  		 mif_ord_lingua,
  		 mif_ord_rif_doc_esterno,
  		 mif_ord_info_tesoriere,
  		 --mif_ord_tipo_utenza,
  		 --mif_ord_codice_ute,
  		 --mif_ord_cod_generico,
  		 mif_ord_flag_copertura,
  		 mif_ord_num_ord_colleg,
  		 mif_ord_progr_ord_colleg,
  		 mif_ord_anno_ord_colleg,
/*  		 mif_ord_dispe_cap_orig,
  		 mif_ord_dispe_articolo,
  		 mif_ord_dispe_descri_articolo,
  		 mif_ord_dispe_somme_non_sogg,
  		 mif_ord_dispe_cod_trib,
  		 mif_ord_dispe_causale_770,
  		 mif_ord_dispe_dtns_benef,
  		 mif_ord_dispe_cmns_benef,
  		 mif_ordinativo_dispe_prns_benef,
  		 mif_ord_dispe_note,
  		 mif_ord_dispe_descri_pag,
  		 mif_ord_dispe_descri_attoamm,
  		 mif_ord_dispe_capitolo_peg,*/
  		 --mif_ord_dispe_vincoli_dest,
  		 --mif_ord_dispe_vincolato,
  		 --mif_ord_dispe_voce_eco,
  		 --mif_ord_dispe_distinta,
--  		 mif_ord_dispe_data_scad_interna,
  		 --mif_ord_dispe_rev_vinc,
  --		 mif_ord_dispe_atto_all,
  		 --mif_ord_dispe_liquidaz,
  	/*	 mif_ord_missione,
  		 mif_ord_programma,
  		 mif_ord_conto_econ,*/
  		 --mif_ord_importo_econ,
--  		 mif_ord_cod_ue,
  --		 mif_ord_cofog_codice,
  		-- mif_ord_cofog_importo,
    --     mif_ord_dispe_beneficiario,
  		 --mif_ord_numero_imp,
  		 --mif_ord_numero_subimp,
  		 mif_ord_code_operatore,
  		 --mif_ord_nome_operatore,
  		 --mif_ord_fatture,
  		 mif_ord_descri_estesa_cap,
  		 --mif_ord_descri_cap,
  		 --mif_ord_prog_cap,
  		 --mif_ord_tipo_cap,
  		 mif_ord_siope_codice_cge,
  		 mif_ord_siope_descri_cge,
  		 --mif_ord_codfisc_funz_del,
  		-- mif_ord_importo_funz_del,
  		 --mif_ord_tpag_funz_del,
  		 --mif_ord_npag_funz_del,
  		 --mif_ord_prg_funz_del,
  		 --mif_ord_codice_cpv,
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
  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
                    '0' else mifFlussoOrdinativoRec.mif_ord_importo end),
 		 mifFlussoOrdinativoRec.mif_ord_flag_fin_loc,
  	     mifFlussoOrdinativoRec.mif_ord_documento,
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_ente_pag,
 	 	 mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag,
 		 mifFlussoOrdinativoRec.mif_ord_bci_conto_tes,
 		 mifFlussoOrdinativoRec.mif_ord_estremi_attoamm,
  		 mifFlussoOrdinativoRec.mif_ord_codice_uff_resp,
 		-- :mif_ord_data_attoamm,
 		--- :mif_ord_resp_attoamm,
 		-- :mif_ord_uff_resp_attomm,
 		mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,
 		mifFlussoOrdinativoRec.mif_ord_codice_ente,
		mifFlussoOrdinativoRec.mif_ord_desc_ente,
  		mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,
 		mifFlussoOrdinativoRec.mif_ord_anno_esercizio,
--  		annoBilancio||flussoElabMifDistOilId::varchar, -- flussoElabMifDistOilId -- 18.04.2016 Sofia
  		annoBilancio||flussoElabMifDistOilRetId::varchar,  -- 25.05.2016 Sofia - JIRA-3619
  		flussoElabMifOilId, --idflussoOil
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,
 		-- :mif_ord_progr_ord_struttura,
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,
		--mifFlussoOrdinativoRec.mif_ord_codice_cge,
 		--mifFlussoOrdinativoRec.mif_ord_descr_cge,
 		-- :mif_ord_tipo_contabilita,
 		mifFlussoOrdinativoRec.mif_ord_codice_raggrup,
 		mifFlussoOrdinativoRec.mif_ord_progr_benef,
 		-- :mif_ord_progr_impignor,
 		mifFlussoOrdinativoRec.mif_ord_progr_dest, -- 18.01.2016 Sofia ABI36
 		mifFlussoOrdinativoRec.mif_ord_bci_conto,
  		mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil, -- 14.03.2016 ABI36
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_class_importo,
 		-- :mif_ord_class_codice_cup,
 		-- :mif_ord_class_codice_cpv,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov, -- 23.02.2016 Sofia JIRA-SIAC-3032
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz,
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio,
        mifFlussoOrdinativoRec.mif_ord_capitolo,
  		mifFlussoOrdinativoRec.mif_ord_articolo,
 		-- :mif_ord_voce_eco,
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil, -- 11.01.2016 Sofia
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
        mifFlussoOrdinativoRec.mif_ord_stato_benef, -- 18.01.2016 Sofia ABI36
 		mifFlussoOrdinativoRec.mif_ord_partiva_benef,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_benef,
  		mifFlussoOrdinativoRec.mif_ord_anag_quiet,
        mifFlussoOrdinativoRec.mif_ord_indir_quiet,
  		mifFlussoOrdinativoRec.mif_ord_cap_quiet,
 		mifFlussoOrdinativoRec.mif_ord_localita_quiet,
  		mifFlussoOrdinativoRec.mif_ord_prov_quiet,
 		mifFlussoOrdinativoRec.mif_ord_partiva_quiet,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_quiet,
        mifFlussoOrdinativoRec.mif_ord_stato_quiet, -- 08.11.2016 Sofia ABI36 JIRA SIAC-4158
 		mifFlussoOrdinativoRec.mif_ord_anag_del,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_del,
 		-- :mif_ord_cap_del,
 		-- :mif_ord_localita_del,
 		-- :mif_ord_prov_del,
 		mifFlussoOrdinativoRec.mif_ord_invio_avviso,
 		-- :mif_ord_codfisc_avviso,
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
        mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr, -- 21.01.2016 SOfia ABI36
        mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr,
  		--:mif_ord_cod_ente_benef,
 		-- :mif_ord_fl_pagam_cond_benef,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
  		mifFlussoOrdinativoRec.mif_ord_bollo_carico,
  		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione,
 		-- 0,
 		-- :mif_ord_bollo_carico_spe,
 		-- :mif_ord_bollo_importo_spe,
 		mifFlussoOrdinativoRec.mif_ord_commissioni_carico,
		mifFlussoOrdinativoRec.mif_ord_commissioni_importo, -- 05.02.2016 Sofia
        mifFlussoOrdinativoRec.mif_ord_commissioni_natura, -- 16.02.2016 Sofia
  		mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_code,
	    mifFlussoOrdinativoRec.mif_ord_pagam_importo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_causale,
 		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec,
 		--	 :mif_ord_pagam_data_scad,
 		-- :mif_ord_pagam_flag_val_ant,
 		-- :mif_ord_pagam_divisa_estera,
 		-- :mif_ord_pagam_flag_ass_circ,
 		-- :mif_ord_pagam_flag_vaglia,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 			-- :mif_ord_tipo_utenza,
 		-- :mif_ord_codice_ute,
 -- :mif_ord_cod_generico,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
      /*  mifFlussoOrdinativoRec.mif_ord_dispe_cap_orig,
        mifFlussoOrdinativoRec.mif_ord_dispe_articolo,
        mifFlussoOrdinativoRec.mif_ord_dispe_descri_articolo,
		mifFlussoOrdinativoRec.mif_ord_dispe_somme_non_sogg,
		mifFlussoOrdinativoRec.mif_ord_dispe_cod_trib,
		mifFlussoOrdinativoRec.mif_ord_dispe_causale_770,
		mifFlussoOrdinativoRec.mif_ord_dispe_dtns_benef,
		mifFlussoOrdinativoRec.mif_ord_dispe_cmns_benef,
		mifFlussoOrdinativoRec.mif_ordinativo_dispe_prns_benef,
        mifFlussoOrdinativoRec.mif_ord_dispe_note,
        mifFlussoOrdinativoRec.mif_ord_dispe_descri_pag,
        mifFlussoOrdinativoRec.mif_ord_dispe_descri_attoamm,
        mifFlussoOrdinativoRec.mif_ord_dispe_capitolo_peg,*/
 -- :mif_ord_dispe_vincoli_dest,
 -- :mif_ord_dispe_vincolato,
 -- :mif_ord_dispe_voce_eco,
--  :mif_ord_dispe_distinta,
--        mifFlussoOrdinativoRec.mif_ord_dispe_data_scad_interna,
  --:mif_ord_dispe_rev_vinc,
  --      mifFlussoOrdinativoRec.mif_ord_dispe_atto_all,
--  :mif_ord_dispe_liquidaz,
    /*    mifFlussoOrdinativoRec.mif_ord_missione,
        mifFlussoOrdinativoRec.mif_ord_programma,
        mifFlussoOrdinativoRec.mif_ord_conto_econ,*/
 -- :mif_ord_importo_econ,
--		mifFlussoOrdinativoRec.mif_ord_cod_ue,
--		mifFlussoOrdinativoRec.mif_ord_cofog_codice,
 -- :mif_ord_cofog_importo,
  --      mifFlussoOrdinativoRec.mif_ord_dispe_beneficiario,
 -- :mif_ord_numero_imp,
 -- :mif_ord_numero_subimp,
        mifFlussoOrdinativoRec.mif_ord_code_operatore,
		--:mif_ord_nome_operatore,
--        mifFlussoOrdinativoRec.mif_ord_fatture,
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
--  :mif_ord_descri_cap,
  --:mif_ord_prog_cap,
 -- :mif_ord_tipo_cap,
       mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
       mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
 -- :mif_ord_codfisc_funz_del,
--  :mif_ord_importo_funz_del,
 -- :mif_ord_tpag_funz_del,
 -- :mif_ord_npag_funz_del,
--  :mif_ord_prg_funz_del,
 -- :mif_ord_codice_cpv,
    now(),
    enteProprietarioId,
    loginOperazione
   )
   returning mif_ord_id into mifOrdSpesaId;


	 -- <Capitolo_origine>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     codResult:=null;
     mifCountRec:=FLUSSO_MIF_ELAB_CAP_ORIGINE;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura id per attr '||CAP_ORIGINE_ATTR||'.';
            if capOrigAttrId is null then
               	select attr.attr_id into capOrigAttrId
                from siac_t_attr attr
                where attr.ente_proprietario_id=enteProprietarioId
                and   attr.attr_code=CAP_ORIGINE_ATTR
                and   attr.data_cancellazione is null
      			and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
-- 	 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal)); 19.01.2017
 	 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));
            end if;

            if  capOrigAttrId is null then
            	RAISE EXCEPTION ' Errore in lettura dato.';
            end if;

            if    capOrigAttrId is not null then
		     select rattr.testo into flussoElabMifValore
             from siac_r_movgest_ts_attr rattr
--             where rattr.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_id 16.02.2016 Sofia
             where rattr.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
             and   rattr.attr_id=capOrigAttrId
             and   rattr.data_cancellazione is null
             and   rattr.validita_fine is null;
    	   	 --and   date_trunc('day',dataElaborazione)>=date_trunc('day',rattr.validita_inizio)
	    	 --and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rattr.validita_fine,dataFineVal));

		    end if;

           	if flussoElabMifValore is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Inserimento mif_t_ordinativo_spesa_disp_ente.';

            	insert into mif_t_ordinativo_spesa_disp_ente
                ( mif_ord_id,
				  mif_ord_dispe_ordine,
				  mif_ord_dispe_nome,
				  mif_ord_dispe_valore,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
                )
                values
                (mifOrdSpesaId,
                 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                 flussoElabMifElabRec.flusso_elab_mif_ordine,
                 flussoElabMifElabRec.flusso_elab_mif_code,
                 flussoElabMifValore,
                 now(),
				 enteProprietarioId,
			     loginOperazione)
                returning mif_ord_dispe_id into codResult;
                if codResult is null then
                	RAISE EXCEPTION ' Inserimento non effettuato.';
                end if;
--               	mifFlussoOrdinativoRec.mif_ord_dispe_cap_orig:=flussoElabMifValore;
            end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	 end if;

     -- <Numero_capitolo_articolo>
     mifCountRec:=mifCountRec+1;

     /*if bilElemRec.elem_code2::INTEGER!=0 then*/
     flussoElabMifElabRec:=null;
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
        		 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
        		insert into mif_t_ordinativo_spesa_disp_ente
                ( mif_ord_id,
				  mif_ord_dispe_ordine,
				  mif_ord_dispe_nome,
				  mif_ord_dispe_valore,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
                )
                values
                (mifOrdSpesaId,
                 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                 flussoElabMifElabRec.flusso_elab_mif_ordine,
                 flussoElabMifElabRec.flusso_elab_mif_code,
                 bilElemRec.elem_code||'/'||bilElemRec.elem_code2, -- 11.02.2016 JIRA SIAC-3004 attivato per tutti UniIt
                 now(),
				 enteProprietarioId,
			     loginOperazione)
                returning mif_ord_dispe_id into codResult;

                if codResult is null then
                	RAISE EXCEPTION ' Inserimento non effettuato.';
                end if;

     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	  end if;
    /* end if;*/

     -- <Descrizione_articolo_capitolo>
     mifCountRec:=mifCountRec+1;
     if bilElemRec.elem_desc2 is not null and
        bilElemRec.elem_desc2!='' then
      flussoElabMifElabRec:=null;
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

         		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
               -- raise notice '%',strMessaggio;
               -- raise notice 'bilElemDesc2=%||',bilElemRec.elem_desc2 ;
        		insert into mif_t_ordinativo_spesa_disp_ente
                ( mif_ord_id,
				  mif_ord_dispe_ordine,
				  mif_ord_dispe_nome,
				  mif_ord_dispe_valore,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
                )
                values
                (mifOrdSpesaId,
                 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                 flussoElabMifElabRec.flusso_elab_mif_ordine,
                 flussoElabMifElabRec.flusso_elab_mif_code,
                 substring(bilElemRec.elem_desc2 from 1 for 150),
                 now(),
				 enteProprietarioId,
			     loginOperazione)
                returning mif_ord_dispe_id into codResult;

                if codResult is null then
                	RAISE EXCEPTION ' Inserimento non effettuato.';
                end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	  end if;
     end if;

	 -- <Somme_non_soggette>
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
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if splitEsenteCode is null then
                    	splitEsenteCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;

                    if splitEsenteCode is not null and splitEsenteCodeId is null then
                     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Calcolo Id Split/Reverse code='||splitEsenteCode||'.';
                    	select tipo.sriva_tipo_id into splitEsenteCodeId
                        from siac_d_splitreverse_iva_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.sriva_tipo_code=splitEsenteCode
                        and   tipo.data_cancellazione is null
                        and   tipo.validita_fine is null;
                    end if;

                    if splitEsenteCodeId is not null then
                    	flussoElabMifValore:=fnc_mif_ordinativo_somme_esenti(mifOrdinativoIdRec.mif_ord_ord_id,
 												            				 splitEsenteCodeId,
		                                                            	     enteProprietarioId,dataElaborazione,dataFineVal);
                    end if;
                    if flussoElabMifValore is not null then
                       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    	                   	||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
	     	                ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		        ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                    		||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                    ||' mifCountRec='||mifCountRec
        		            ||' tipo flusso '||MANDMIF_TIPO||'. Inserimento mif_t_ordinativo_spesa_disp_ente.';
                       insert into mif_t_ordinativo_spesa_disp_ente
		                ( mif_ord_id,
						  mif_ord_dispe_ordine,
						  mif_ord_dispe_nome,
						  mif_ord_dispe_valore,
						  validita_inizio,
						  ente_proprietario_id,
						  login_operazione
        		        )
		                values
        		        (mifOrdSpesaId,
                		 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                         flussoElabMifElabRec.flusso_elab_mif_ordine,
		                 flussoElabMifElabRec.flusso_elab_mif_code,
        		         flussoElabMifValore,
		                 now(),
						 enteProprietarioId,
			    		 loginOperazione)
		                returning mif_ord_dispe_id into codResult;

        		        if codResult is null then
		                	RAISE EXCEPTION ' Inserimento non effettuato.';
        		        end if;
                    end if;

                end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	  end if;



     -- <Codice_tributo>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     oneriCauRec:=null;
     codResult:=null;
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
            	if codiceTrib is null then
                	codiceTrib:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if codiceTrib is not null and codiceTribId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id codiceTributo '||codiceTrib||'.';

                	select tipo.onere_tipo_id into codiceTribId
                    from siac_d_onere_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.onere_tipo_code=codiceTrib
                    and   tipo.data_cancellazione is null
	    	   	 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--	    	 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
	    	 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
                end if;

                if codiceTribId is not null then
					select * into oneriCauRec
                    from fnc_mif_ordinativo_onere( mifOrdinativoIdRec.mif_ord_ord_id,
			 								       codiceTribId,
                                                   true,
				                                   enteProprietarioId,dataElaborazione, dataFineVal);
                    if oneriCauRec is not null then
                    	if oneriCauRec.listaOneri is not null then
                        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
		        		               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		        		       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
				                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                				       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
				                       ||' mifCountRec='||mifCountRec
                				       ||' tipo flusso '||MANDMIF_TIPO||'. Inserimento mif_t_ordinativo_spesa_disp_ente';
                        	insert into mif_t_ordinativo_spesa_disp_ente
		               		( mif_ord_id,
							  mif_ord_dispe_ordine,
							  mif_ord_dispe_nome,
							  mif_ord_dispe_valore,
							  validita_inizio,
							  ente_proprietario_id,
							  login_operazione
        		    	    )
		                	values
	        		        (mifOrdSpesaId,
    	            		 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                             flussoElabMifElabRec.flusso_elab_mif_ordine,
			                 flussoElabMifElabRec.flusso_elab_mif_code,
        			         oneriCauRec.listaOneri,
		        	         now(),
							 enteProprietarioId,
			    			 loginOperazione)
			                returning mif_ord_dispe_id into codResult;

    	   		       	    if codResult is null then
		                		RAISE EXCEPTION ' Inserimento non effettuato.';
	        		       	end if;

                        end if;
                    end if;
                end if;

            end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	 end if;

	 mifCountRec:=mifCountRec+1;
     -- <Causale_770>
	 if codResult is not null then --oneriCauRec is not null then
     	if oneriCauRec.listaCausali is not null then
	     flussoElabMifElabRec:=null;
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
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
            	insert into mif_t_ordinativo_spesa_disp_ente
		        ( mif_ord_id,
				  mif_ord_dispe_ordine,
				  mif_ord_dispe_nome,
				  mif_ord_dispe_valore,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
        		)
		        values
	        	(mifOrdSpesaId,
    	         --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                 flussoElabMifElabRec.flusso_elab_mif_ordine,
			     flussoElabMifElabRec.flusso_elab_mif_code,
        		 oneriCauRec.listaCausali,
		         now(),
				 enteProprietarioId,
			     loginOperazione)
			     returning mif_ord_dispe_id into codResult;

    	   		 if codResult is null then
		           		RAISE EXCEPTION ' Inserimento non effettuato.';
	        	 end if;
        	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    	end if;
		 end if;
     end if;

     -- <Data_nascita_beneficiario>
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     datiNascitaRec:=null;
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

     			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data di nascita soggetto.';

        		select pf.nascita_data, pf.comune_id_nascita into datiNascitaRec
                from siac_t_persona_fisica pf
                where pf.soggetto_id=soggettoRifId
                and   pf.data_cancellazione is null
                and   pf.validita_fine is null;
--    	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',pf.validita_inizio)
--	    		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(pf.validita_fine,dataFineVal));

                if datiNascitaRec is not null then
                 if datiNascitaRec.nascita_data is not null then
	     			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';


                    flussoElabMifValore:=
                        extract('year' from datiNascitaRec.nascita_data)||'-'||
    			        lpad(extract('month' from datiNascitaRec.nascita_data)::varchar,2,'0')||'-'||
			            lpad(extract('day' from datiNascitaRec.nascita_data)::varchar,2,'0');
					--raise notice 'Data nascita beneficiario %', flussoElabMifValore;
                    insert into mif_t_ordinativo_spesa_disp_ente
			        ( mif_ord_id,
					  mif_ord_dispe_ordine,
					  mif_ord_dispe_nome,
					  mif_ord_dispe_valore,
					  validita_inizio,
					  ente_proprietario_id,
					  login_operazione
        			)
		        	values
		        	(mifOrdSpesaId,
    		         --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        			 flussoElabMifValore,
                     now(),
					 enteProprietarioId,
				     loginOperazione)
				     returning mif_ord_dispe_id into codResult;

    	   			 if codResult is null then
		        	   		RAISE EXCEPTION ' Inserimento non effettuato.';
		        	 end if;

                 end if;
                end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  	end if;
      end if;


      -- <Luogo_nascita_beneficiario>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      --codResult:=null;
      mifCountRec:=mifCountRec+2;
      if codResult is not null then --datiNascitaRec is not null then
       codResult:=null;
       if datiNascitaRec.comune_id_nascita is not null then
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


				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura luogo di nascita soggetto.';

                select com.comune_desc into flussoElabMifValore
                from siac_t_comune com
                where com.comune_id=  datiNascitaRec.comune_id_nascita
                and   com.data_cancellazione is null
                and   com.validita_fine is null;
    	   	--	and   date_trunc('day',dataElaborazione)>=date_trunc('day',com.validita_inizio)
	    	--	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(com.validita_fine,dataFineVal));

                if flussoElabMifValore is not null then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
                	 insert into mif_t_ordinativo_spesa_disp_ente
 			        ( mif_ord_id,
					  mif_ord_dispe_ordine,
					  mif_ord_dispe_nome,
					  mif_ord_dispe_valore,
					  validita_inizio,
					  ente_proprietario_id,
					  login_operazione
        			)
		        	values
		        	(mifOrdSpesaId,
    		         --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        			 flussoElabMifValore,
                     now(),
					 enteProprietarioId,
				     loginOperazione)
				     returning mif_ord_dispe_id into codResult;

    	   			 if codResult is null then
		        	   		RAISE EXCEPTION ' Inserimento non effettuato.';
		        	 end if;

                end if;
     	 else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  	 end if;
        end if;

        -- <Prov_nascita_beneficiario>
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=null;
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

	           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura provincia di nascita soggetto.';


                select prov.sigla_automobilistica into flussoElabMifValore
           	    from siac_r_comune_provincia provRel, siac_t_provincia prov
            	where provRel.comune_id=datiNascitaRec.comune_id_nascita
            	and   provRel.data_cancellazione is null
                and   provRel.validita_fine is null
--         		and   date_trunc('day',dataElaborazione)>=date_trunc('day',provRel.validita_inizio)
-- 		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(provRel.validita_fine,dataFineVal))
           		and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
--         		and   date_trunc('day',dataElaborazione)>=date_trunc('day',prov.validita_inizio)
-- 		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(prov.validita_fine,dataFineVal))
            	order by provRel.data_creazione;


                if flussoElabMifValore is not null then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
                	 insert into mif_t_ordinativo_spesa_disp_ente
 			        ( mif_ord_id,
					  mif_ord_dispe_ordine,
					  mif_ord_dispe_nome,
					  mif_ord_dispe_valore,
					  validita_inizio,
					  ente_proprietario_id,
					  login_operazione
        			)
		        	values
		        	(mifOrdSpesaId,
    		         --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        			 flussoElabMifValore,
                     now(),
					 enteProprietarioId,
				     loginOperazione)
				     returning mif_ord_dispe_id into codResult;

    	   			 if codResult is null then
		        	   		RAISE EXCEPTION ' Inserimento non effettuato.';
		        	 end if;
--                 	mifFlussoOrdinativoRec.mif_ordinativo_dispe_prns_benef:=flussoElabMifValore;
                end if;
     	 else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  	 end if;
        end if;

       end if;
      end if;

     -- <Note>
     flussoElabMifValore:=null;
     flussoElabMifElabRec:=null;
     codResult:=null;
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

      			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura note.';


               /*
                if noteOrdAttrId is null then
                	select attr.attr_id into noteOrdAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=NOTE_ORD_ATTR
                    and   attr.data_cancellazione is null
         			and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 		 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal));
                end if;

                if noteOrdAttrId is  null then
	                RAISE EXCEPTION ' Errore in lettura dato.';
                end if;*/

  --              if noteOrdAttrId is not null then
				if mifOrdinativoIdRec.mif_ord_notetes_id is not null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura note.';

					select note.notetes_desc into flussoElabMifValore
				    from siac_d_note_tesoriere note
   					where note.notetes_id=mifOrdinativoIdRec.mif_ord_notetes_id
				    and   note.data_cancellazione is null
                    and   note.validita_fine is null;

/*                  27.11.2015 Sofia spostate in informazioni_tes
                	select attr.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr attr
                    where attr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   attr.attr_id=noteOrdAttrId
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;*/
--         			and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
-- 		 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal));
                end if;

                if flussoElabMifValore is not null and
                   flussoElabMifValore!='' then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
                	 insert into mif_t_ordinativo_spesa_disp_ente
 			        ( mif_ord_id,
					  mif_ord_dispe_ordine,
					  mif_ord_dispe_nome,
					  mif_ord_dispe_valore,
					  validita_inizio,
					  ente_proprietario_id,
					  login_operazione
        			)
		        	values
		        	(mifOrdSpesaId,
    		         --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        			 flussoElabMifValore,
                     now(),
					 enteProprietarioId,
				     loginOperazione)
				     returning mif_ord_dispe_id into codResult;

    	   			 if codResult is null then
		        	   		RAISE EXCEPTION ' Inserimento non effettuato.';
		        	 end if;

                end if;
   	 else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Descrizione_tipo_pagamento>
   flussoElabMifValore:=null;
   flussoElabMifElabRec:=null;
   codResult:=null;
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

			 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
             insert into mif_t_ordinativo_spesa_disp_ente
 			 ( mif_ord_id,
			   mif_ord_dispe_ordine,
		 	   mif_ord_dispe_nome,
		 	   mif_ord_dispe_valore,
		 	   validita_inizio,
		 	   ente_proprietario_id,
		 	   login_operazione
          	 )
		     values
		     (mifOrdSpesaId,
    		  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  codAccreRec.accredito_tipo_desc,
              now(),
		 	  enteProprietarioId,
		      loginOperazione)
		     returning mif_ord_dispe_id into codResult;

  			 if codResult is null then
      	   		RAISE EXCEPTION ' Inserimento non effettuato.';
        	 end if;
   	  else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	  end if;
   end if;

   -- <Descrizione_atto_autorizzativo>
   mifCountRec:=mifCountRec+1;
   if attoAmmRec is not null then
   	if attoAmmRec.attoAmmOggetto is not null then
    	flussoElabMifElabRec:=null;
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
         		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
         	    insert into mif_t_ordinativo_spesa_disp_ente
 				 ( mif_ord_id,
				   mif_ord_dispe_ordine,
			 	   mif_ord_dispe_nome,
			 	   mif_ord_dispe_valore,
		 		   validita_inizio,
			 	   ente_proprietario_id,
			 	   login_operazione
        	  	 )
		    	 values
			     (mifOrdSpesaId,
    			  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
--        		  attoAmmRec.attoAmmOggetto, JIRA SIAC-2998
                  replace(replace(attoAmmRec.attoAmmOggetto, chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR),
                  now(),
			 	  enteProprietarioId,
			      loginOperazione)
			     returning mif_ord_dispe_id into codResult;

  				 if codResult is null then
      	   			RAISE EXCEPTION ' Inserimento non effettuato.';
	        	 end if;

   	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	    end if;
       end if;
  end if;
 end if;

 -- <Capitolo_Peg> -- CMTO
 flussoElabMifElabRec:=null;
 codResult:=null;
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
     		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
         	    insert into mif_t_ordinativo_spesa_disp_ente
 				 ( mif_ord_id,
				   mif_ord_dispe_ordine,
			 	   mif_ord_dispe_nome,
			 	   mif_ord_dispe_valore,
		 		   validita_inizio,
			 	   ente_proprietario_id,
			 	   login_operazione
        	  	 )
		    	 values
			     (mifOrdSpesaId,
    			  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
        		  bilElemRec.elem_code,
                  now(),
			 	  enteProprietarioId,
			      loginOperazione)
			     returning mif_ord_dispe_id into codResult;

  				 if codResult is null then
      	   			RAISE EXCEPTION ' Inserimento non effettuato.';
	        	 end if;

     else
     	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
  end if;

  -- <Vincoli_di_destinazione>
  mifCountRec:=mifCountRec+1;

  -- 10.02.2017 Sofia  	SIAC-4423- gestione Vincolato per CmTo
  -- <Vincolato>
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
                   flussoElabMifElabRec.flussoElabMifDef is not null then -- 21.02.2016 Sofia HD-INC000001573104

                   if flussoElabMifElabRec.flussoElabMifParam is not null then -- 21.02.2016 Sofia HD-INC000001573104
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

                         select c.classif_code into flussoElabMifValore
                         from siac_r_ordinativo_class r, siac_t_class c
                         where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                         and   c.classif_id=r.classif_id
                         and   c.classif_tipo_id=classVincolatoCodeId
                         and   r.data_cancellazione is null
                         and   r.validita_fine is null
                         and   c.data_cancellazione is null;

                    end if;
				   end if;


           	   		-- 17.03.2017  	JIRA-SIAC-4621-CMTO
		           if flussoElabMifValore is null and
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


	    	       end if;
    	    	   -- 17.03.2017  	JIRA-SIAC-4621-CMTO


                   -- 21.02.2016 Sofia HD-INC000001573104
				   if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                   end if;

               	   if flussoElabMifValore is not null then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';



         	   	 	insert into mif_t_ordinativo_spesa_disp_ente
 					( mif_ord_id,
				      mif_ord_dispe_ordine,
				 	  mif_ord_dispe_nome,
				 	  mif_ord_dispe_valore,
			 		  validita_inizio,
				 	  ente_proprietario_id,
			 	   	  login_operazione
	        	  	)
			    	values
			        (mifOrdSpesaId,
	    			 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        		     flussoElabMifValore,
                     now(),
			 	     enteProprietarioId,
			         loginOperazione)
			        returning mif_ord_dispe_id into codResult;

  				    if codResult is null then
      	   				RAISE EXCEPTION ' Inserimento non effettuato.';
		        	end if;
                  end if;
               end if;
   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

 -- <Voce_Economica>
 -- <Numero_distinta_bilancio>
 mifCountRec:=mifCountRec+2;

  -- <Data_scadenza_interna>
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
     			if ordDataScadenza is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza interna.';

	        		select sub.ord_ts_data_scadenza into ordDataScadenza
	    	        from siac_t_ordinativo_ts sub
    	    	    where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;
                end if;

                if ordDataScadenza is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';

                      flussoElabMifValore:=
                    	extract('year' from ordDataScadenza)||'-'||
		             	lpad(extract('month' from ordDataScadenza)::varchar,2,'0')||'-'||
        		     	lpad(extract('day' from ordDataScadenza)::varchar,2,'0');

         	   	 	insert into mif_t_ordinativo_spesa_disp_ente
 					( mif_ord_id,
				      mif_ord_dispe_ordine,
				 	  mif_ord_dispe_nome,
				 	  mif_ord_dispe_valore,
			 		  validita_inizio,
				 	  ente_proprietario_id,
			 	   	  login_operazione
	        	  	)
			    	values
			        (mifOrdSpesaId,
	    			 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        		     flussoElabMifValore,
                     now(),
			 	     enteProprietarioId,
			         loginOperazione)
			        returning mif_ord_dispe_id into codResult;

  				    if codResult is null then
      	   				RAISE EXCEPTION ' Inserimento non effettuato.';
		        	end if;
                end if;
   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Numero_reversale_vincolata>
   mifCountRec:=mifCountRec+1;
   -- <Allegato_Atto>
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
      if flussoElabMifElabRec.flussoElabMifParam is not null then
      	if attoAmmTipoAllAll is null then
           		attoAmmTipoAllAll:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
        end if;

     	if attoAmmTipoAllAll is not null then
 	       flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
           												 attoAmmTipoAllAll,null,
                                                         dataElaborazione,dataFineVal);
        end if;
      end if;

      if flussoElabMifValore is not null then
      		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
        	insert into mif_t_ordinativo_spesa_disp_ente
 					( mif_ord_id,
				      mif_ord_dispe_ordine,
				 	  mif_ord_dispe_nome,
				 	  mif_ord_dispe_valore,
			 		  validita_inizio,
				 	  ente_proprietario_id,
			 	   	  login_operazione
	        	  	)
			    	values
			        (mifOrdSpesaId,
	    			 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        		     flussoElabMifValore,
                     now(),
			 	     enteProprietarioId,
			         loginOperazione)
			        returning mif_ord_dispe_id into codResult;

  				    if codResult is null then
      	   				RAISE EXCEPTION ' Inserimento non effettuato.';
		        	end if;
      end if;


   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Liquidazione> CMTO
   mifCountRec:=mifCountRec+1;

   -- <Codice_Programma>
   flussoElabMifElabRec:=null;
   flussoElabMifValore:=null;
   codResult:=null;
   programmaId:=mifOrdinativoIdRec.mif_ord_programma_id;
   mifCountRec:=mifCountRec+2;
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
      /*if flussoElabMifElabRec.flussoElabMifParam is not null then
      	if programmaCodeTipo is null then
           		programmaCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
        end if;

        if programmaCodeTipo is not null and programmaCodeTipoId is null then
        	select tipo.classif_tipo_id into  programmaCodeTipoId
            from siac_d_class_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.classif_tipo_code=programmaCodeTipo
            and   tipo.data_cancellazione is null
   			and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

        end if;

     	if programmaCodeTipoId is not null then
           select class.classif_code,class.classif_id into flussoElabMifValore, programmaId
           from siac_r_bil_elem_class rclass,siac_t_class  class
           where rclass.elem_id=mifOrdinativoIdRec.mif_ord_elem_id
           and   rclass.data_cancellazione is null
           and   rclass.validita_fine is null
   		  -- and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio)
 		 --  and	 date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal))
           and   class.classif_id=rclass.classif_id
           and   class.classif_tipo_id=programmaCodeTipoId
           and   class.data_cancellazione is null
   		   and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		   and	 date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
           order by rclass.elem_classif_id
           limit 1;


        end if;


      end if;*/

      flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_programma_code;
      if flussoElabMifValore is not null then
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
        	insert into mif_t_ordinativo_spesa_disp_ente
 					( mif_ord_id,
				      mif_ord_dispe_ordine,
				 	  mif_ord_dispe_nome,
				 	  mif_ord_dispe_valore,
			 		  validita_inizio,
				 	  ente_proprietario_id,
			 	   	  login_operazione
	        	  	)
			    	values
			        (mifOrdSpesaId,
	    			 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        		     flussoElabMifValore,
                     now(),
			 	     enteProprietarioId,
			         loginOperazione)
			        returning mif_ord_dispe_id into codResult;

  				    if codResult is null then
      	   				RAISE EXCEPTION ' Inserimento non effettuato.';
		        	end if;
      end if;


   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Codice_Missione>
   if programmaId is not null then
	   flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
       codResult:=null;
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
              if flussoElabMifElabRec.flussoElabMifParam is not null then
                if famMissProgrCode is null then
					famMissProgrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if famMissProgrCode is not null and famMissProgrCodeId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class_fam_tree.';

                	select fam.classif_fam_tree_id into famMissProgrCodeId
                    from siac_t_class_fam_tree fam
                    where fam.ente_proprietario_id=enteProprietarioId
                    and   fam.class_fam_code=famMissProgrCode
                    and   fam.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(fam.validita_fine,dataFineVal)); 19.01.2017
		 		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));

                end if;

                if famMissProgrCodeId is not null then
					strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class.';
                	select cp.classif_code into flussoElabMifValore
					from siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
--					where cf.classif_id=programmaId
					where cf.classif_id=mifOrdinativoIdRec.mif_ord_programma_id
                    and   cf.data_cancellazione is null
---		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',cf.validita_inizio) 19.01.2017
---		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cf.validita_fine,dataFineVal)) 19.01.2017
					and   r.classif_id=cf.classif_id
					and   r.classif_id_padre is not null
					and   r.classif_fam_tree_id=famMissProgrCodeId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null -- 19.01.2017
--		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) 19.01.2017
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(r.validita_fine,dataFineVal)) 19.01.2017
					and   cp.classif_id=r.classif_id_padre
                    and   cp.data_cancellazione is null
--		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',cp.validita_inizio)
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cp.validita_fine,dataFineVal))
                    order by cp.classif_id
                    limit 1;

                end if;

                if flussoElabMifValore is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 			       	insert into mif_t_ordinativo_spesa_disp_ente
 					( mif_ord_id,
				      mif_ord_dispe_ordine,
				 	  mif_ord_dispe_nome,
				 	  mif_ord_dispe_valore,
			 		  validita_inizio,
				 	  ente_proprietario_id,
			 	   	  login_operazione
	        	  	)
			    	values
			        (mifOrdSpesaId,
	    			 --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                     flussoElabMifElabRec.flusso_elab_mif_ordine,
				     flussoElabMifElabRec.flusso_elab_mif_code,
        		     flussoElabMifValore,
                     now(),
			 	     enteProprietarioId,
			         loginOperazione)
			        returning mif_ord_dispe_id into codResult;

  				    if codResult is null then
      	   				RAISE EXCEPTION ' Inserimento non effettuato.';
		        	end if;
			    end if;
			  end if;
    		 else
		    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  			 end if;
	   end if;

  end if;

  -- <Codice_Economico>
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
  if flussoElabMifElabRec.flussoElabMifAttivo=true or isTransElemAttiva=true then
 	 if flussoElabMifElabRec.flussoElabMifElab=true or isTransElemAttiva=true then
      if flussoElabMifElabRec.flussoElabMifParam is not null or isTransElemAttiva=true then

      	if eventoTipoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo evento '||flussoElabMifElabRec.flussoElabMifParam||'.';

        	select tipo.evento_tipo_id into eventoTipoCodeId
            from siac_d_evento_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
--            and   tipo.evento_tipo_code=flussoElabMifElabRec.flussoElabMifParam 15.02.2016 Sofia ABI36
            and   tipo.evento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   tipo.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

            if eventoTipoCodeId is null then
            	 RAISE EXCEPTION ' Dato non reperito.';
            end if;

        end if;

		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
        select conto.pdce_conto_code into flussoElabMifValore
        from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento, siac_d_evento evento
        where conto.ente_proprietario_id=enteProprietarioId
        and   conto.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',conto.validita_inizio)
--		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(conto.validita_fine,dataFineVal)) 19.01.2017
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(conto.validita_fine,dataElaborazione))
        and   regMovFin.pdce_conto_id=conto.pdce_conto_id
        and   rEvento.regmovfin_id=regmovfin.regmovfin_id
        and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
        and   evento.evento_id=revento.evento_id
        and   evento.evento_tipo_id=eventoTipoCodeId
        and   regMovFin.data_cancellazione is null
        and   regMovFin.validita_fine is null
--  	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',regMovFin.validita_inizio)
--        and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(regMovFin.validita_fine,dataFineVal))
        and   rEvento.data_cancellazione is null
        and   rEvento.validita_fine is null
--		and   date_trunc('day',dataElaborazione)>=date_trunc('day',rEvento.validita_inizio)
--		and	date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rEvento.validita_fine,dataFineVal))
        and   evento.data_cancellazione is null
 	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',evento.validita_inizio)
--	    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(evento.validita_fine,dataFineVal)); 19.01.2017
	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(evento.validita_fine,dataElaborazione));


	    -- 15.02.2016 Sofia ABI36
        if 	flussoElabMifValore is not null then
	        -- TBR
        	if isTransElemAttiva=true then
            	contoEconCodeTbr:=flussoElabMifValore;
            end if;
        end if;

        if flussoElabMifValore is null then
           if codiceFinVTbr is null then
	    	   codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
           end if;

           if codiceFinVTbr	is not null and codiceFinVTipoTbrId is null then
	           -- codiceFinVTipoTbrId
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura piano_conti_fin_V_code_tipo_id '||codiceFinVTbr||'.';

			   select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			   from siac_d_class_tipo tipo
		       where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.classif_tipo_code=codiceFinVTbr
		       and   tipo.data_cancellazione is null
		  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
--		   	   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal)); 19.01.2017
		   	   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
           	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||'.';
		     select class.classif_code into codiceFinVCodeTbr
		   	 from siac_r_ordinativo_class r, siac_t_class class
	         where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null; --19.01.2017
		     --and   class.validita_fine is null
             -- Sofia 10.11.2016 INC000001359464
--             and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--  		     and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017

             if codiceFinVCodeTbr is not null then
             	flussoElabMifValore:=codiceFinVCodeTbr;
             end if;
         end if;
        end if;

	    if 	flussoElabMifValore is not null then
            -- TBR spostato sopra
       -- 	if isTransElemAttiva=true then
       --           	contoEconCodeTbr:=flussoElabMifValore;
       --     end if;
			if flussoElabMifElabRec.flussoElabMifAttivo=true then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 			 insert into mif_t_ordinativo_spesa_disp_ente
 			 ( mif_ord_id,
			   mif_ord_dispe_ordine,
			   mif_ord_dispe_nome,
		  	   mif_ord_dispe_valore,
			   validita_inizio,
			   ente_proprietario_id,
			   login_operazione
	         )
			 values
			 (mifOrdSpesaId,
	    	  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  flussoElabMifValore,
              now(),
			  enteProprietarioId,
			  loginOperazione)
			 returning mif_ord_dispe_id into codResult;

  		     if codResult is null then
      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
		     end if;
           end if;
        end if;
      end if;
     else
   	 	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
  end if;

  -- <Importo_Codice_Economico> da fare non si sa ancora come
  mifCountRec:=mifCountRec+1;
  -- <Codice_Ue>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  codResult:=null;
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
  if flussoElabMifElabRec.flussoElabMifAttivo=true or isTransElemAttiva=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true or isTransElemAttiva=true then
     if flussoElabMifElabRec.flussoElabMifParam is not null or isTransElemAttiva=true then
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
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
		 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
        end if;

        if codiceUECodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class.';
        	select class.classif_code into flussoElabMifValore
--            from siac_r_bil_elem_class rclass, siac_t_class class
            from siac_r_ordinativo_class rclass, siac_t_class class
--            where rclass.elem_id=mifOrdinativoIdRec.mif_ord_elem_id
            where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and   rclass.data_cancellazione is null
            and   rclass.validita_fine is null
		--    and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio)
	--	 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal))
            and   class.classif_id=rclass.classif_id
            and   class.classif_tipo_id=codiceUECodeTipoId
            and   class.data_cancellazione is null
--		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)) 19.01.2017
            order by rclass.ord_classif_id
            limit 1;

        end if;
        if flussoElabMifValore is not null then
			-- TBR
	        if isTransElemAttiva=true then
            	codiceUeCodeTbr:=flussoElabMifValore;
            end if;
			if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 			 insert into mif_t_ordinativo_spesa_disp_ente
 			 ( mif_ord_id,
			   mif_ord_dispe_ordine,
			   mif_ord_dispe_nome,
		  	   mif_ord_dispe_valore,
			   validita_inizio,
			   ente_proprietario_id,
			   login_operazione
	         )
			 values
			 (mifOrdSpesaId,
	    	  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  flussoElabMifValore,
              now(),
			  enteProprietarioId,
			  loginOperazione)
			 returning mif_ord_dispe_id into codResult;

  		     if codResult is null then
      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
		     end if;
			end if;
        end if;
     end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <Codice_Cofog>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  codResult:=null;
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
  if flussoElabMifElabRec.flussoElabMifAttivo=true or isTransElemAttiva=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true or isTransElemAttiva=true then
     if flussoElabMifElabRec.flussoElabMifParam is not null or isTransElemAttiva=true then
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
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
		 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
        end if;

        if codiceCofogCodeTipoId is not null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class.';
        	select class.classif_code into flussoElabMifValore
--            from siac_r_bil_elem_class rclass, siac_t_class class
            from siac_r_ordinativo_class rclass, siac_t_class class
--            where rclass.elem_id=mifOrdinativoIdRec.mif_ord_elem_id
            where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and   rclass.data_cancellazione is null
            and   rclass.validita_fine is null
		   -- and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio)
		 	--and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal))
            and   class.classif_id=rclass.classif_id
            and   class.classif_tipo_id=codiceCofogCodeTipoId
            and   class.data_cancellazione is null
--		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)) 19.01.2017
            order by rclass.ord_classif_id
            limit 1;

        end if;
        if flussoElabMifValore is not null then
            -- TBR
        	if isTransElemAttiva=true then
            	cofogCodeTbr:=flussoElabMifValore;
            end if;
			if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 			 insert into mif_t_ordinativo_spesa_disp_ente
 			 ( mif_ord_id,
			   mif_ord_dispe_ordine,
			   mif_ord_dispe_nome,
		  	   mif_ord_dispe_valore,
			   validita_inizio,
			   ente_proprietario_id,
			   login_operazione
	         )
			 values
			 (mifOrdSpesaId,
	    	  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  flussoElabMifValore,
              now(),
			  enteProprietarioId,
			  loginOperazione)
			 returning mif_ord_dispe_id into codResult;

  		     if codResult is null then
      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
		     end if;
            end if;
        end if;
     end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;
  -- <Importo_Cofog> da fare ma non si sa ancora come
  mifCountRec:=mifCountRec+1;

 -- <Transazione_Elementare>
 mifCountTmpRec:=FLUSSO_MIF_ELAB_TBR;
 flussoElabMifElabRec:=null;
 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountTmpRec];
 flussoElabMifValore:=null;
 codResult:=null;
 if isTransElemAttiva=true then
 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare composizione.';
   -- missione-programma
   -- pdcFin-V
   -- codice_economico
   -- cofog
   -- codice_ue
   -- siope
   -- cup
   -- ricorrente
   -- asl
   -- progr_reg_unitaria

   -- mifOrdinativoIdRec.mif_ord_programma_code;
   -- codiceFinVCodeTbr
   if codiceFinVTipoTbrId is not null and codiceFinVCodeTbr is null then -- 15.02.2015 Sofia ABI36
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| codiceFinVTbr||'.';
	   select class.classif_code into codiceFinVCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=codiceFinVTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null; -- 19.01.2017
       -- Sofia 10.11.2016 INC000001359464
--       and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--       and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017
--       and   class.validita_fine is null;
   end if;
   -- contoEconCodeTbr
   -- cofogCodeTbr
   -- codiceUeCodeTbr
   -- siopeCodeTbr
   -- cupAttrTbr
   if cupAttrId is not null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '||cupTbr||' [siac_r_ordinativo_attr].';
	   select r.testo into cupAttrTbr
   	   from siac_r_ordinativo_attr r
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   r.attr_id=cupAttrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL;

       -- 16.02.2016 Sofia JIRA-SIAC-3035
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '||cupTbr||' [siac_r_liquidazione_attr].';

       if coalesce(cupAttrTbr,NVL_STR)=NVL_STR then
       	select r.testo into cupAttrTbr
	    from siac_r_liquidazione_attr r
        where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
        and   r.attr_id=cupAttrId
        and   r.data_cancellazione is null
        and   r.validita_fine is NULL;
       end if;
   end if;

   -- ricorrenteCodeTbr
   if ricorrenteTipoTbrId is not null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| ricorrenteTbr||'.';
	   select class.classif_code into ricorrenteCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=ricorrenteTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null; -- 19.01.2017
       -- Sofia 10.11.2016 INC000001359464
--       and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
--       and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));
--       and   class.validita_fine is null;
   end if;
   -- aslCodeTbr
   if aslTipoTbrId is not null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| aslTbr||'.';
	   select class.classif_code into aslCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=aslTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null; -- 19.01.2017
	   -- Sofia 10.11.2016 INC000001359464
--	   and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--  	   and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017
--       and   class.validita_fine is null;
   end if;

   -- progrRegUnitCodeTbr
   if progrRegUnitTipoTbrId is not null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| progrRegUnitTbr||'.';
	   select class.classif_code into progrRegUnitCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=progrRegUnitTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null; -- 19.01.2017
	   -- Sofia 10.11.2016 INC000001359464
--       and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--  	   and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017
--       and   class.validita_fine is null;
   end if;

   -- mifOrdinativoIdRec.mif_ord_programma_code;
   -- codiceFinVCodeTbr
   -- contoEconCodeTbr
   -- cofogCodeTbr
   -- codiceUeCodeTbr
   -- siopeCodeTbr
   -- cupAttrTbr
   -- ricorrenteCodeTbr
   -- aslCodeTbr
   -- progrRegUnitCodeTbr
   flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_programma_code;

   if codiceFinVCodeTbr is not null and  codiceFinVCodeTbr!='' then
   	flussoElabMifValore:=flussoElabMifValore||'-'||codiceFinVCodeTbr;
   end if;

   if contoEconCodeTbr is not null and contoEconCodeTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||contoEconCodeTbr
                           	   else contoEconCodeTbr end);
   end if;
   if cofogCodeTbr is not null and cofogCodeTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||cofogCodeTbr
                           	   else cofogCodeTbr end);
   end if;
   if codiceUeCodeTbr is not null and codiceUeCodeTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||codiceUeCodeTbr
                           	   else codiceUeCodeTbr end);
   end if;
   if siopeCodeTbr is not null and siopeCodeTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||siopeCodeTbr
                           	   else siopeCodeTbr end);
   end if;
   if cupAttrTbr is not null and cupAttrTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||cupAttrTbr
                           	   else cupAttrTbr end);
   end if;
   if ricorrenteCodeTbr is not null and ricorrenteCodeTbr!='' then
	flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||ricorrenteCodeTbr
                           	   else ricorrenteCodeTbr end);
   end if;
   if aslCodeTbr is not null and aslCodeTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||aslCodeTbr
                           	   else aslCodeTbr end);
   end if;
   if progrRegUnitCodeTbr is not null and progrRegUnitCodeTbr!='' then
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||progrRegUnitCodeTbr
                           	   else progrRegUnitCodeTbr end);
   end if;


   if flussoElabMifValore is not null then
   	 	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      flussoElabMifValore,
    	  now(),
		  enteProprietarioId,
		  loginOperazione
         )
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
   end if;

 end if;

  -- <Anagrafica_Beneficiario>
  mifCountRec:=mifCountRec+1;
  if anagraficaBenefCBI is not null then
	  flussoElabMifElabRec:=null;
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
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 			 insert into mif_t_ordinativo_spesa_disp_ente
 			 ( mif_ord_id,
			   mif_ord_dispe_ordine,
			   mif_ord_dispe_nome,
		  	   mif_ord_dispe_valore,
			   validita_inizio,
			   ente_proprietario_id,
			   login_operazione
	         )
			 values
			 (mifOrdSpesaId,
	    	  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  substring(anagraficaBenefCBI from 1 for 140),
              now(),
			  enteProprietarioId,
			  loginOperazione)
			 returning mif_ord_dispe_id into codResult;

  		     if codResult is null then
      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
		     end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  	end if;
	  end if;
 end if;

 -- <Codice_Soggetto>
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
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 			 insert into mif_t_ordinativo_spesa_disp_ente
 			 ( mif_ord_id,
			   mif_ord_dispe_ordine,
			   mif_ord_dispe_nome,
		  	   mif_ord_dispe_valore,
			   validita_inizio,
			   ente_proprietario_id,
			   login_operazione
	         )
			 values
			 (mifOrdSpesaId,
	    	  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  soggettoRec.soggetto_code,
              now(),
			  enteProprietarioId,
			  loginOperazione)
			 returning mif_ord_dispe_id into codResult;

  		     if codResult is null then
      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
		     end if;
	else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	end if;
 end if;

 -- <Carte_Corredo>
 mifCountRec:=mifCountRec+1;


 -- <Descrizione_ABI>
 mifCountRec:=mifCountRec+1;
 if mifFlussoOrdinativoRec.mif_ord_abi_benef is not null then
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
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
               ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
               ||' mifCountRec='||mifCountRec
               ||' tipo flusso '||MANDMIF_TIPO||'.Lettura descrizione ABI.';

        	select abi.abi_desc into flussoElabMifValore
            from siac_t_abi abi
            where abi.ente_proprietario_id=enteProprietarioId
            and   abi.abi_code=mifFlussoOrdinativoRec.mif_ord_abi_benef
            and   abi.data_cancellazione is null
            and   abi.validita_fine is null;

            if flussoElabMifValore is not null then
	        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 				 insert into mif_t_ordinativo_spesa_disp_ente
 				 ( mif_ord_id,
				   mif_ord_dispe_ordine,
				   mif_ord_dispe_nome,
			  	   mif_ord_dispe_valore,
				   validita_inizio,
				   ente_proprietario_id,
				   login_operazione
	        	 )
				 values
				 (mifOrdSpesaId,
	    		  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
	        	  flussoElabMifValore,
    	          now(),
				  enteProprietarioId,
				  loginOperazione)
				 returning mif_ord_dispe_id into codResult;

                 if codResult is null then
	      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
			     end if;
			 end if;
		else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		end if;
   end if;
 end if;

 -- <Descrizione_CAB>
 mifCountRec:=mifCountRec+1;
 if mifFlussoOrdinativoRec.mif_ord_cab_benef is not null then
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
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
               ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
               ||' mifCountRec='||mifCountRec
               ||' tipo flusso '||MANDMIF_TIPO||'.Lettura descrizione CAB.';

        	select cab.cab_desc into flussoElabMifValore
            from siac_t_cab cab
            where cab.ente_proprietario_id=enteProprietarioId
            and   cab.cab_abi=mifFlussoOrdinativoRec.mif_ord_abi_benef
            and   cab.cab_code=mifFlussoOrdinativoRec.mif_ord_cab_benef
            and   cab.data_cancellazione is null
            and   cab.validita_fine is null;

            if flussoElabMifValore is not null then
	        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 				 insert into mif_t_ordinativo_spesa_disp_ente
 				 ( mif_ord_id,
				   mif_ord_dispe_ordine,
				   mif_ord_dispe_nome,
			  	   mif_ord_dispe_valore,
				   validita_inizio,
				   ente_proprietario_id,
				   login_operazione
	        	 )
				 values
				 (mifOrdSpesaId,
	    		  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
	        	  flussoElabMifValore,
    	          now(),
				  enteProprietarioId,
				  loginOperazione)
				 returning mif_ord_dispe_id into codResult;

                 if codResult is null then
	      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
			     end if;
			 end if;
		else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		end if;
   end if;
 end if;

 -- <Tipo_Finanziamento>
 mifCountRec:=mifCountRec+1;
 flussoElabMifElabRec:=null;
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
 if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
 end if;
 if flussoElabMifElabRec.flussoElabMifAttivo=true then
 	if flussoElabMifElabRec.flussoElabMifElab=true then
     if flussoElabMifElabRec.flussoElabMifParam is not null then

     		if codiceFinanzTipo is null then
            	codiceFinanzTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;
            if codiceFinanzTipo is not null and codiceFinanzTipoId is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
               	||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
               	||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
               	||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
               	||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
               	||' mifCountRec='||mifCountRec
               	||' tipo flusso '||MANDMIF_TIPO||'.Lettura identificativo classif '||codiceFinanzTipo||'.';

            	select tipo.classif_tipo_id into codiceFinanzTipoId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=codiceFinanzTipo
                and   tipo.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
			 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                if codiceFinanzTipoId is null then
                	RAISE EXCEPTION ' Dato non reperito.';
                end if;
            end if;

            if codiceFinanzTipoId is not null then
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	           ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	   ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
	               ||' mifCountRec='||mifCountRec
    	           ||' tipo flusso '||MANDMIF_TIPO||'.Lettura code-desc classif '||codiceFinanzTipo||'.';

            	select class.classif_code,class.classif_desc into flussoElabMifValore, flussoElabMifValoreDesc
                from siac_r_bil_elem_class rclass, siac_t_class class
                where rclass.elem_id=bilElemRec.elem_id
                and   rclass.classif_id=class.classif_id
                and   class.classif_tipo_id=codiceFinanzTipoId
                and   class.data_cancellazione is null
                and   rclass.data_cancellazione is null -- 19.01.2017
                and   rclass.validita_fine is null -- 19.01.2017
--			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)) 19.01.2017
--			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio) 19.01.2017
--			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal)) 19.01.2017
                order by rclass.elem_classif_id desc limit 1;
            end if;

            if flussoElabMifValore is not null then
	        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 				 insert into mif_t_ordinativo_spesa_disp_ente
 				 ( mif_ord_id,
				   mif_ord_dispe_ordine,
				   mif_ord_dispe_nome,
			  	   mif_ord_dispe_valore,
				   validita_inizio,
				   ente_proprietario_id,
				   login_operazione
	        	 )
				 values
				 (mifOrdSpesaId,
	    		  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
	        	  flussoElabMifValore,
    	          now(),
				  enteProprietarioId,
				  loginOperazione)
				 returning mif_ord_dispe_id into codResult;

                 if codResult is null then
	      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
			     end if;
			 end if;
       end if;
	else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	end if;
 end if;

 -- <Descrizione_tipo_finanziamento>
 mifCountRec:=mifCountRec+1;
 if flussoElabMifValoreDesc is not null then
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
	        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
 				 insert into mif_t_ordinativo_spesa_disp_ente
 				 ( mif_ord_id,
				   mif_ord_dispe_ordine,
				   mif_ord_dispe_nome,
			  	   mif_ord_dispe_valore,
				   validita_inizio,
				   ente_proprietario_id,
				   login_operazione
	        	 )
				 values
				 (mifOrdSpesaId,
	    		  --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
	        	  flussoElabMifValoreDesc,
    	          now(),
				  enteProprietarioId,
				  loginOperazione)
				 returning mif_ord_dispe_id into codResult;

                 if codResult is null then
	      	  		RAISE EXCEPTION ' Inserimento non effettuato.';
			     end if;
	else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	end if;
  end if;
 end if;

 -- <Importo_Mandato_Lettere>
 mifCountRec:=mifCountRec+1;

 if isGestioneQuoteOK=true then
  quoteOrdinativoRec:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura quote ordinativo.';

  for quoteOrdinativoRec in
    (select *
	 from fnc_mif_ordinativo_quote(mifOrdinativoIdRec.mif_ord_ord_id,
 								   ordDetTsTipoId,movgestTsTipoSubId,
                                   classCdrTipoId,classCdcTipoId,
                                   enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
  		-- <Numero_quota_mandato>
		mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	    flussoElabMifElabRec:=null;
        codResult:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        -- 17.02.2016 Sofia devo tenere il numero quota attivo per avere attiva la sezione delle quote
        -- ma al momento non lo gestisco
		if false  then
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
     	insert into mif_t_ordinativo_spesa_disp_ente
  		( mif_ord_id,
          mif_ord_ts_id,
		  mif_ord_dispe_ordine,
		  mif_ord_dispe_nome,
		  mif_ord_dispe_valore,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      quoteOrdinativoRec.numeroQuota,
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

	    -- <Descrizione_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.descriQuota is not null and
           quoteOrdinativoRec.descriQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                        ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                        ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                        ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                        ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                        ||' mifCountRec='||mifCountRec
                        ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
  		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
--	      quoteOrdinativoRec.descriQuota, 09.02.2016 Sofia JIRA SIAC - 2998
          replace(replace(quoteOrdinativoRec.descriQuota , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR),
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
  		end if;

        -- <Data_scadenza_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
 	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.dataScadenzaQuota is not null and
           quoteOrdinativoRec.dataScadenzaQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      quoteOrdinativoRec.dataScadenzaQuota,
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

        -- <Importo_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.importoQuota is not null and
           quoteOrdinativoRec.importoQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      quoteOrdinativoRec.importoQuota,
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

        -- <Documento_collegato_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.documentoCollQuota is not null and
           quoteOrdinativoRec.documentoCollQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      quoteOrdinativoRec.documentoCollQuota,
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

        -- <Impegno_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.movgestQuota is not null and
           quoteOrdinativoRec.movgestQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      quoteOrdinativoRec.movgestQuota,
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

        -- <Descrizione_impegno_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.movgestDescriQuota is not null and
           quoteOrdinativoRec.movgestDescriQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
--	      quoteOrdinativoRec.movgestDescriQuota, 09.02.2016 Sofia JIRA SIAC-2998
          replace(replace(quoteOrdinativoRec.movgestDescriQuota , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR),
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

        -- <Determina_impegno_quota_mandato>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
           flussoElabMifElabRec.flussoElabMifElab=true and
           quoteOrdinativoRec.movgestAttoAmmQuota is not null and
           quoteOrdinativoRec.movgestAttoAmmQuota!='' then

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_spesa_disp_ente.';
    	 insert into mif_t_ordinativo_spesa_disp_ente
 		 ( mif_ord_id,
           mif_ord_ts_id,
		   mif_ord_dispe_ordine,
		   mif_ord_dispe_nome,
		   mif_ord_dispe_valore,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
	     )
		 values
		 (mifOrdSpesaId,
          quoteOrdinativoRec.ordTsId,
	      --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
--	      quoteOrdinativoRec.movgestAttoAmmQuota, 09.02.2016 Sofia JIRA SIAC-2998
          replace(replace(quoteOrdinativoRec.movgestAttoAmmQuota , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR),
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
        end if;

    end loop;

 end if;

 -- 19.01.2016 Sofia ABI36
 -- <dati_a_disposizione_ente_beneficiario>
 if datiDispEnteBenef=true then
  mifFlussoOrdDispeBenefRec:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_DISP_ABI36;

  -- <codice_missione>
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
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then
          if flussoElabMifElabRec.flussoElabMifParam is not null then
        	if famMissProgrCode is null then
				famMissProgrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if famMissProgrCode is not null and famMissProgrCodeId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class_fam_tree.';

                	select fam.classif_fam_tree_id into famMissProgrCodeId
                    from siac_t_class_fam_tree fam
                    where fam.ente_proprietario_id=enteProprietarioId
                    and   fam.class_fam_code=famMissProgrCode
                    and   fam.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(fam.validita_fine,dataFineVal)); 19.01.2017
		 		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));

            end if;

            if famMissProgrCodeId is not null then
					strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class.';
                	select cp.classif_code into flussoElabMifValore
					from siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
					where cf.classif_id=mifOrdinativoIdRec.mif_ord_programma_id
                    and   cf.data_cancellazione is null
--		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',cf.validita_inizio) 19.01.2017
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cf.validita_fine,dataFineVal)) 19.01.2017
					and   r.classif_id=cf.classif_id
					and   r.classif_id_padre is not null
					and   r.classif_fam_tree_id=famMissProgrCodeId
                    and   r.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(r.validita_fine,dataFineVal)) 19.01.2017
		 		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(r.validita_fine,dataElaborazione))
					and   cp.classif_id=r.classif_id_padre
                    and   cp.data_cancellazione is null
--		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',cp.validita_inizio) 19.01.2017
--		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cp.validita_fine,dataFineVal)) 19.01.2017
                    order by cp.classif_id
                    limit 1;

             end if;
	         if flussoElabMifValore is not null then
                       mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_missione:=flussoElabMifValore;
             end if;
           end if;
	else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	end if;
  end if;

  -- <codice_programma>
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
--      mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_programma:=mifOrdinativoIdRec.mif_ord_programma_code;
      -- 16.02.2016 Sofia ABI36
      mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_programma:=substring(mifOrdinativoIdRec.mif_ord_programma_code from 3 for 2);
   else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   end if;
  end if;

  -- <codice_economico>
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
  if flussoElabMifElabRec.flussoElabMifAttivo=true  then
 	 if flussoElabMifElabRec.flussoElabMifElab=true  then
      if flussoElabMifElabRec.flussoElabMifParam is not null then

      	if eventoTipoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo evento '||flussoElabMifElabRec.flussoElabMifParam||'.';

        	select tipo.evento_tipo_id into eventoTipoCodeId
            from siac_d_evento_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
--            and   tipo.evento_tipo_code=flussoElabMifElabRec.flussoElabMifParam 15.02.2016 Sofia ABI36
            and   tipo.evento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   tipo.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

            if eventoTipoCodeId is null then
            	 RAISE EXCEPTION ' Dato non reperito.';
            end if;

        end if;

		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
        select conto.pdce_conto_code into flussoElabMifValore
        from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento, siac_d_evento evento
        where conto.ente_proprietario_id=enteProprietarioId
        and   conto.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',conto.validita_inizio)
--		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(conto.validita_fine,dataFineVal)) 19.01.2017
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(conto.validita_fine,dataElaborazione))
        and   regMovFin.pdce_conto_id=conto.pdce_conto_id
        and   rEvento.regmovfin_id=regmovfin.regmovfin_id
        and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
        and   evento.evento_id=revento.evento_id
        and   evento.evento_tipo_id=eventoTipoCodeId
        and   regMovFin.data_cancellazione is null
        and   regMovFin.validita_fine is null
        and   rEvento.data_cancellazione is null
        and   rEvento.validita_fine is null
        and   evento.data_cancellazione is null
 	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',evento.validita_inizio)
--	    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(evento.validita_fine,dataFineVal)); 19.01.2017
	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(evento.validita_fine,dataElaborazione));

	    if 	flussoElabMifValore is not null then
	        mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico:=flussoElabMifValore;
	    end if;

        -- 15.02.2016 Sofia ABI36
        if flussoElabMifValore is null then
        	if codiceFinVTbr is null then
	    	   codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
           end if;

           if codiceFinVTbr	is not null and codiceFinVTipoTbrId is null then
	           -- codiceFinVTipoTbrId
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura piano_conti_fin_V_code_tipo_id '||codiceFinVTbr||'.';

			   select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			   from siac_d_class_tipo tipo
		       where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.classif_tipo_code=codiceFinVTbr
		       and   tipo.data_cancellazione is null
		  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
--		   	   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal)); 19.01.2017
		   	   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
           	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||'.';
		     select class.classif_code into codiceFinVCodeTbr
		   	 from siac_r_ordinativo_class r, siac_t_class class
	         where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null; -- 19.01.2017
		     -- Sofia 10.11.2016 INC000001359464
--             and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--  	 		 and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)); 19.01.2017
--		     and   class.validita_fine is null;

             if codiceFinVCodeTbr is not null then
                -- 16.02.2016 Sofia ABI36
                mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico:=
                  replace(substring(codiceFinVCodeTbr from 2 for length(codiceFinVCodeTbr)-1),'.','');
             end if;
          end if;
        end if;

      end if;
     else
   	 	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
  end if;

  -- <importo_codice_economico>
  mifCountRec:=mifCountRec+1;
  if mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico is not null then
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
      if flussoElabMifElabRec.flussoElabMifAttivo=true  then
	 	 if flussoElabMifElabRec.flussoElabMifElab=true  then
         	mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico_imp:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
         	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;
  end if;

  -- <codice_ue>
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
   	if flussoElabMifElabRec.flussoElabMifElab=true  then
     if flussoElabMifElabRec.flussoElabMifParam is not null  then
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
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
		 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
        end if;

        if codiceUECodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class.';
        	select class.classif_code into flussoElabMifValore
            from siac_r_ordinativo_class rclass, siac_t_class class
            where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and   rclass.data_cancellazione is null
            and   rclass.validita_fine is null
            and   class.classif_id=rclass.classif_id
            and   class.classif_tipo_id=codiceUECodeTipoId
            and   class.data_cancellazione is null
--		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)) 19.01.2017
            order by rclass.ord_classif_id
            limit 1;

        end if;
        if flussoElabMifValore is not null then
			mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_ue:=flussoElabMifValore;
        end if;
     end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;


  -- <codice_cofog>
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
  if flussoElabMifElabRec.flussoElabMifAttivo=true  then
   	if flussoElabMifElabRec.flussoElabMifElab=true  then
     if flussoElabMifElabRec.flussoElabMifParam is not null  then
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
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
		 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
        end if;

        if codiceCofogCodeTipoId is not null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class.';
        	select class.classif_code into flussoElabMifValore
            from siac_r_ordinativo_class rclass, siac_t_class class
            where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and   rclass.data_cancellazione is null
            and   rclass.validita_fine is null
            and   class.classif_id=rclass.classif_id
            and   class.classif_tipo_id=codiceCofogCodeTipoId
            and   class.data_cancellazione is null
--		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) 19.01.2017
--		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal)) 19.01.2017
            order by rclass.ord_classif_id
            limit 1;

        end if;
        if flussoElabMifValore is not null then
			mifFlussoOrdDispeBenefRec.mif_ord_dispe_cofog_codice:=flussoElabMifValore;
        end if;
     end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <importo_cofog>
  mifCountRec:=mifCountRec+1;
  if mifFlussoOrdDispeBenefRec.mif_ord_dispe_cofog_codice is not null then
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
     if flussoElabMifElabRec.flussoElabMifAttivo=true  then
   	  if flussoElabMifElabRec.flussoElabMifElab=true  then
      	mifFlussoOrdDispeBenefRec.mif_ord_dispe_cofog_imp:=mifFlussoOrdinativoRec.mif_ord_importo;
      else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
     end if;
  end if;

  codresult:=null;

  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_DISP_ABI36;
  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO
                       ||'. Inserimento dati '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' in mif_t_ordinativo_spesa_disp_ente_benef.';

  insert into mif_t_ordinativo_spesa_disp_ente_benef
  (mif_ord_id,mif_ord_ord_id,
   mif_ord_dispe_codice_missione,mif_ord_dispe_codice_programma,
   mif_ord_dispe_codice_economico,mif_ord_dispe_codice_economico_imp,
   mif_ord_dispe_codice_ue,
   mif_ord_dispe_cofog_codice,mif_ord_dispe_cofog_imp,
   validita_inizio, ente_proprietario_id,login_operazione )
  values
  (mifOrdSpesaId,mifOrdinativoIdRec.mif_ord_ord_id,
   mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_missione,mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_programma,
   mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico,mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico_imp,
   mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_ue,
   mifFlussoOrdDispeBenefRec.mif_ord_dispe_cofog_codice,mifFlussoOrdDispeBenefRec.mif_ord_dispe_cofog_imp,
   now(), enteProprietarioId,loginOperazione
   )
   returning mif_ord_dispe_ben_id into codResult;

   if codResult is null then
   	raise exception ' Inserimento non effettuato.';
   end if;
 end if;


 -- <InfSerMan_Fattura_Descr>
 if isGestioneFatture = true then
  flussoElabMifElabRec:=null;
--  execute  'ANALYZE mif_t_ordinativo_spesa_documenti;';
  mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.';
  ordRec:=null;
  for ordRec in
  (select * from fnc_mif_ordinativo_documenti( mifOrdinativoIdRec.mif_ord_ord_id,
											   numeroDocs::integer,tipoDocs,
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
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          ordRec.documentiColl,
          now(),
          enteProprietarioId,
          loginOperazione
         );

   end loop;
  end if;





   -- <ritenute>
   -- <ritenuta>
   -- <tipo_ritenuta>
   -- <importo_ritenuta>
   -- <numero_reversale>
   -- <progressivo_reversale>
   -- <progressivo_ritenuta> non gestito

   if  isRitenutaAttivo=true then
    ritenutaRec:=null;
--    execute  'ANALYZE mif_t_ordinativo_spesa_ritenute;';
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
                                      tipoOnereIrpegId, -- 30.08.2016 Sofia-HD-INC000001208683
									  ordStatoCodeAId,ordDetTsTipoId,
                                      flussoElabMifTipoDec, -- 20.01.2016 Sofia ABI36
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
 		 --mif_ord_rit_progr_rit,
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

   if  isRicevutaAttivo=true then
    ricevutaRec:=null;
--    execute  'ANALYZE mif_t_ordinativo_spesa_ricevute;';
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  ricevute'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
                                      flussoElabMifTipoDec, -- 21.01.2016 Sofia ABI36
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

   -- 11.02.2016 Sofia gestione pcc per enti che non gestiscono quietanze
   if comPccAttrId is not null and numeroOrdinativiTrasm>0 then
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
--          mif.ord_emissione_data, -- siac-3415
--		  mif.ord_emissione_data+(1*interval '1 day'), -- siac-3415
		  mif.ord_emissione_data, -- jira siac-4020 Sofia 26.09.2016
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
   end if;


   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   -- 18.04.2016 Sofia
   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
--   update siac_t_progressivo p set prog_value=flussoElabMifDistOilId
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId   -- 25.05.2016 Sofia - JIRA-3619
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   -- 18.04.2016 Sofia - aggiunto flusso_elab_mif_codice_flusso_oil
   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';
   -- 25.05.2016 Sofia - JIRA-3619
   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
--   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_spesa')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di spesa.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;

    -- 25.05.2016 Sofia - JIRA-3619
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

-- Sofia SIAC-5231 FINE

-- SIAC-5230 INIZIO
create or replace view siac_v_dwh_pcc (
ente_proprietario_id,
importo_quietanza,
numero_ordinativo,
data_emissione_ordinativo,
data_scadenza,
data_registrazione,
cod_esito,
desc_esito,
data_esito,
cod_tipo_operazione,
desc_tipo_operazione,
cod_ufficio,
desc_ufficio,
cod_debito,
desc_debito,
cod_causale_pcc,
desc_causale_pcc,
validita_inizio,
validita_fine,
anno_doc,
num_doc,
data_emissione_doc,
cod_tipo_doc,
cod_sogg_doc,
num_subdoc
)
as
select t_registro_pcc.ente_proprietario_id, 
       t_registro_pcc.rpcc_quietanza_importo,
       t_registro_pcc.ordinativo_numero, 
       t_registro_pcc.ordinativo_data_emissione, 
       t_registro_pcc.data_scadenza,
       t_registro_pcc.rpcc_registrazione_data,
       t_registro_pcc.rpcc_esito_code,
       t_registro_pcc.rpcc_esito_desc,
       t_registro_pcc.rpcc_esito_data,       
       d_pcc_oper_tipo.pccop_tipo_code,
       d_pcc_oper_tipo.pccop_tipo_desc,
       d_pcc_codice.pcccod_code, 
       d_pcc_codice.pcccod_desc,
       d_pcc_debito_stato.pccdeb_stato_code, 
       d_pcc_debito_stato.pccdeb_stato_desc,
       d_pcc_causale.pcccau_code,
       d_pcc_causale.pcccau_desc, 
       t_registro_pcc.validita_inizio,
       t_registro_pcc.validita_fine,              
       t_doc.doc_anno,
       t_doc.doc_numero, 
       t_doc.doc_data_emissione,
       d_doc_tipo.doc_tipo_code,
       t_soggetto.soggetto_code,
       t_subdoc.subdoc_numero      
from   siac_t_registro_pcc t_registro_pcc
inner join siac_d_pcc_operazione_tipo d_pcc_oper_tipo on d_pcc_oper_tipo.pccop_tipo_id = t_registro_pcc.pccop_tipo_id
inner join siac_t_doc t_doc on t_doc.doc_id = t_registro_pcc.doc_id
inner join siac_d_pcc_codice d_pcc_codice on d_pcc_codice.pcccod_id = t_doc.pcccod_id
inner join siac_t_subdoc t_subdoc on t_subdoc.subdoc_id = t_registro_pcc.subdoc_id
inner join siac_d_doc_tipo d_doc_tipo on d_doc_tipo.doc_tipo_id = t_doc.doc_tipo_id
left join siac_d_pcc_debito_stato d_pcc_debito_stato on (d_pcc_debito_stato.pccdeb_stato_id=t_registro_pcc.pccdeb_stato_id
        	                                             and d_pcc_debito_stato.data_cancellazione is null)
left join siac_d_pcc_causale d_pcc_causale on (d_pcc_causale.pcccau_id=t_registro_pcc.pcccau_id
        	                                   and d_pcc_causale.data_cancellazione is null)
left join siac_r_doc_sog r_doc_sog on (r_doc_sog.doc_id=t_doc.doc_id
        	                           and r_doc_sog.data_cancellazione is null)
left join siac_t_soggetto t_soggetto on (t_soggetto.soggetto_id= r_doc_sog.soggetto_id
        	                             and t_soggetto.data_cancellazione is null)                                               
where  d_pcc_oper_tipo.pccop_tipo_code = 'CP'
and    t_registro_pcc.data_cancellazione is null
and    d_pcc_codice.data_cancellazione is null
and    d_pcc_oper_tipo.data_cancellazione is null
and    t_doc.data_cancellazione is null
and    t_subdoc.data_cancellazione is null
and    d_doc_tipo.data_cancellazione is null;
-- SIAC-5230 FINE

-- SIAC-5265 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN

p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';


select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c where 
a.ente_proprietario_id=p_ente_prop_id and
a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
and c.anno=p_anno
;
/*
raise notice 'dati input  p_ente_prop_id % - 
  p_anno % - 
  p_data_reg_da % - 
  p_data_reg_a % - 
  p_pdce_v_livello % - 
  nome_ente_in % - 
  bil_id_in %', p_ente_prop_id::varchar , p_anno::varchar ,  p_data_reg_da::varchar ,
  p_data_reg_a::varchar ,  p_pdce_v_livello::varchar ,  nome_ente_in::varchar ,
  bil_id_in::varchar ;
*/
    select fnc_siac_random_user()
	into	user_table;

raise notice '1 - % ',clock_timestamp()::varchar;
	select --a.pdce_conto_code, 
    a.pdce_conto_id --, a.livello
    into --dati_pdce
    pdce_conto_id_in
    from siac_t_pdce_conto a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.pdce_conto_code=p_pdce_v_livello;
    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') e'' inesistente';
        return next;
    	return;
    END IF;
--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;      
    
--     carico l'intera struttura PDCE 
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO 
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
select 
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, 
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id, 
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre, 
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id, 
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre, 
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id, 
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre, 
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id, 
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre, 
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id, 
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre, 
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id, 
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre, 
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id, 
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre, 
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query  
select outp.* from (
with ord as (--ORD
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all       
select impacc.* from (          
--A,I 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q                
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL 
),
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest c,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_id=sogcla.movgest_id 
left join sog on 
movgest.movgest_id=sog.movgest_id 
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all         
select impsubacc.* from (          
--SA,SI 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r               
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL 
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all        
select impsubaccmod.* from (          
with movgest as (
/*SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest r,
 siac_t_movgest_ts q, siac_t_modifica s,siac_r_modifica_stato t,
 siac_t_movgest_ts_det_mod u
WHERE d.collegamento_tipo_code in ('MMGE','MMGS') and
  a.ente_proprietario_id=p_ente_prop_id
  and  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and r.movgest_id=q.movgest_id 
and s.mod_id=b.campo_pk_id
and t.mod_id=s.mod_id
and q.movgest_id=r.movgest_id
and u.mod_stato_r_id=t.mod_stato_r_id
and u.movgest_ts_id=q.movgest_ts_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL and 
s.data_cancellazione IS NULL and 
t.data_cancellazione IS NULL and 
u.data_cancellazione IS NULL  
union
select 
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o,
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where a.ente_proprietario_id=p_ente_prop_id
and b.pnota_id=a.pnota_id
and a.bil_id=bil_id_in
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and p.mod_stato_r_id=n.mod_stato_r_id
and q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and  a.data_cancellazione is null 
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
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null*/


with modge as (
select 
n.mod_stato_r_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null 
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
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from 
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id 
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from 
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
select 
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,     
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
modge.importo_dare,                    
modge.importo_avere           
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all 
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--DOC
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t                                       
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and 
        s.doc_id=r.doc_id and 
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL/*
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
'' tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'' tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
'' numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id and
  a.regmovfin_id = b.regmovfin_id AND
        c.	evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in and
        l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL*/
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--lib
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where 
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id 
and g.evento_tipo_id=dd.evento_tipo_id and
 m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND  
g.data_cancellazione IS NULL 
AND  n.validita_fine IS NULL
AND  cc.validita_fine IS NULL     
        )
        ,cc as 
        ( WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree 
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
        /* bb as (select pdce_conto.livello, pdce_conto.pdce_conto_id,pdce_conto.pdce_conto_code codice_conto,
        pdce_conto.pdce_conto_desc descr_pdce_livello,strutt_pdce.*
    	from siac_t_pdce_conto	pdce_conto,
            siac_rep_struttura_pdce strutt_pdce
        where ((pdce_conto.livello=0 
            		AND strutt_pdce.pdce_liv0_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=1 
            		AND strutt_pdce.pdce_liv1_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=2 
            		AND strutt_pdce.pdce_liv2_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=3 
            		AND strutt_pdce.pdce_liv3_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=4 
            		AND strutt_pdce.pdce_liv4_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=5 
            		AND strutt_pdce.pdce_liv5_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=6 
            		AND strutt_pdce.pdce_liv6_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=7 
            		AND strutt_pdce.pdce_liv7_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=8 
            		AND strutt_pdce.pdce_liv8_id=pdce_conto.pdce_conto_id))
         and pdce_conto.ente_proprietario_id=p_ente_prop_id 
         and pdce_conto.pdce_conto_code=p_pdce_v_livello
        and strutt_pdce.utente=user_table
         and pdce_conto.data_cancellazione is NULL)*/
         select   
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8, 
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto, 
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,                    
ord.importo_avere,             
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error 
from ord join cc on ord.pdce_conto_id=cc.pdce_conto_id
cross join bb 
) as outp
;
  
 delete from siac_rep_struttura_pdce 	where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5265 FINE

-- SIAC-5254 - INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_capitolospesa (
  _uid_capitolospesa integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
 rec record;
 attoamm_uid integer;
BEGIN

	for rec in
		select
			r.ord_id,
			y.ord_numero,
			y.ord_emissione_data,
			s.elem_id,
			s.elem_code,
			s.elem_code2,
			s.elem_code3,
			s.elem_desc
		from
			siac_r_ordinativo_bil_elem r,
			siac_t_bil_elem s,
			siac_t_ordinativo y,
			siac_d_ordinativo_tipo i
		where s.elem_id=r.elem_id
		and y.ord_id=r.ord_id
		and s.elem_id=_uid_capitolospesa
		and i.ord_tipo_id=y.ord_tipo_id
		and i.ord_tipo_code='P'
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and i.data_cancellazione is null
		and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
		and y.data_cancellazione is null
		order by 2,3
		LIMIT _limit
		OFFSET _offset
	
	loop
		uid:=rec.ord_id;
		uid_capitolo:=rec.elem_id;
		num_capitolo:=rec.elem_code;
		num_articolo:=rec.elem_code2;
		num_ueb:=rec.elem_code3;
		capitolo_desc:=rec.elem_desc;
		
		select
			a.ord_id,
			a.ord_numero,
			a.ord_desc,
			a.ord_emissione_data,
			e.ord_stato_desc,
			g.ord_ts_det_importo as imp,
			f.ord_ts_code
		into
			uid,
			ord_numero,
			ord_desc,
			ord_emissione_data,
			ord_stato_desc,
			importo,
			ord_ts_code
		from
			siac_t_ordinativo a,
			siac_r_ordinativo_stato d,
			siac_d_ordinativo_stato e,
			siac_t_ordinativo_ts f,
			siac_t_ordinativo_ts_det g,
			siac_d_ordinativo_ts_det_tipo h
		where a.ord_id=uid
		and d.ord_id=a.ord_id
		and d.ord_stato_id=e.ord_stato_id
		and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
		and f.ord_id=a.ord_id
		and g.ord_ts_id=f.ord_ts_id
		and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
		and h.ord_ts_det_tipo_code = 'A'
		and a.data_cancellazione is null
		and d.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null;
			
		select
			c.soggetto_code,
			c.soggetto_desc
		into
			soggetto_code,
			soggetto_desc
		from
			siac_r_ordinativo_soggetto b,
			siac_t_soggetto c
		where b.ord_id=uid
		and b.soggetto_id=c.soggetto_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and b.data_cancellazione is null
		and c.data_cancellazione is null;
		
		select
			n.attoamm_id,
			n.attoamm_numero,
			n.attoamm_anno,
			q.attoamm_stato_desc,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc
		into
			attoamm_uid,
			attoamm_numero,
			attoamm_anno,
			attoamm_stato_desc,
			attoamm_tipo_code,
			attoamm_tipo_desc
		from
			siac_r_ordinativo_atto_amm m,
			siac_t_atto_amm n,
			siac_d_atto_amm_tipo o,
			siac_r_atto_amm_stato p,
			siac_d_atto_amm_stato q
		where m.ord_id=uid
		and n.attoamm_id=m.attoamm_id
		and o.attoamm_tipo_id=n.attoamm_tipo_id
		and p.attoamm_id=n.attoamm_id
		and p.attoamm_stato_id=q.attoamm_stato_id
		and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
		and q.attoamm_stato_code<>'ANNULLATO'
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null;
		
		accredito_tipo_code := null;
		accredito_tipo_desc := null;
		
		select
			e2.accredito_tipo_code,
			e2.accredito_tipo_desc
		into
			accredito_tipo_code,
			accredito_tipo_desc
		FROM
			siac_r_ordinativo_modpag c2,
			siac_t_modpag d2,
			siac_d_accredito_tipo e2
		where c2.ord_id=uid
		and c2.modpag_id=d2.modpag_id
		and e2.accredito_tipo_id=d2.accredito_tipo_id
		and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
		and c2.data_cancellazione is null
		and d2.data_cancellazione is null
		and e2.data_cancellazione is null;
		
		IF accredito_tipo_code IS NULL THEN
			SELECT
				drt.relaz_tipo_code,
				drt.relaz_tipo_desc
			into
				accredito_tipo_code,
				accredito_tipo_desc
			FROM
				siac_r_ordinativo_modpag rom,
				siac_r_soggetto_relaz rsr,
				siac_d_relaz_tipo drt
			where rom.ord_id=uid
			and rsr.soggetto_relaz_id = rom.soggetto_relaz_id
			and drt.relaz_tipo_id = rsr.relaz_tipo_id
			and now() BETWEEN rom.validita_inizio and coalesce (rom.validita_fine,now())
			and now() BETWEEN rsr.validita_inizio and coalesce (rsr.validita_fine,now())
			and rom.data_cancellazione is null
			and rsr.data_cancellazione is null
			and drt.data_cancellazione is null;
		END IF;
		
		attoamm_sac_code:=null;
		attoamm_sac_desc:=null;
		
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
		where z.attoamm_id=attoamm_uid
		and z.classif_id=y.classif_id
		and x.classif_tipo_id=y.classif_tipo_id
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and x.classif_tipo_code IN ('CDC', 'CDR')
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL;
		
		select
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		into
			provc_anno,
			provc_numero,
			provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where a2.ord_id=uid
		and b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL;
		
		return next;
		
	end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5254 - FINE