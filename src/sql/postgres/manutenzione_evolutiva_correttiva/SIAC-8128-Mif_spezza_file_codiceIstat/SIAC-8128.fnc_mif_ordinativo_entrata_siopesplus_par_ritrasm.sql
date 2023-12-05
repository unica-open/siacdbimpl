/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists 
siac.fnc_mif_ordinativo_entrata_splus 
(
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
);

CREATE OR REPLACE FUNCTION siac.fnc_mif_ordinativo_entrata_splus (
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

 mifFlussoOrdinativoRec  mif_t_ordinativo_entrata%rowtype;
-- ordinativoRec record;


 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 isIndirizzoBenef boolean:=false;
 ordRec record;

 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;




 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;

 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 descCge    varchar(500):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 siopeClassTipoId integer:=null;

 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;
 ordRelazCodeTipoId integer :=null;
 ordDetTsTipoId integer :=null;



 ambitoFinId integer:=null;

 isDefAnnoRedisuo  varchar(5):=null;
 isRicevutaAttivo boolean:=false;
 isGestioneFatture boolean:=false;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;


 ordAllegatoCartAttrId integer:=null;
 ordinativoTsDetTipoId integer:=null;
 movgestTsTipoSubId integer:=null;
 ordinativoSpesaTipoId integer:=null;


 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;

 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 NVL_STR               CONSTANT VARCHAR:='';
 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 -- siope plus
 tipoIncassoCode    varchar(100):=null;
 tipoIncassoCodeId  integer:=null;
 tipoRitOrdInc      varchar(100):=null;
 tipoSplitOrdInc    varchar(100):=null;
 tipoSubOrdInc      varchar(100):=null;
 tipoRitenuteInc    varchar(100):=null;
 tipoIncassoCompensazione varchar(100):=null;
 tipoIncassoRegolarizza varchar(100):=null;
 tipoIncassoCassa varchar(100):=null;
 tipoContoCCPCode varchar(100):=null;
 tipoContoCCPCodeId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 codiceFinVTbr varchar(50):=null;
 codiceFinVTipoTbrId integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;
 ricorrenteCodeTipoId integer:=null;
 ricorrenteCodeTipo varchar(100):=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;

 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 codiceBolloPlusDesc   varchar(100):=null;

 codiceBolloPlusEsente boolean:=false;
 isOrdCommerciale boolean:=false;

 attoAmmTipoAllRag varchar(50):=null;
 attoAmmStrTipoRag varchar(50):=null;
 -- siope plus

 -- 11.05.2021 Sofia Jira SIAC-8128 
 codiceContoSanita varchar(30):='';
 codiceIstatSanita varchar(30):='';
 
 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_TIPO_CODE_I  CONSTANT  varchar :='I';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_TIPO_IMPORTO_A CONSTANT  varchar :='A';


 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';
 ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO';
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE';
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO';

 -- annullamenti e variazioni dopo trasmissione
 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO';
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE';

 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Avere';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='REVMIF_SPLUS';


 SEPARATORE     CONSTANT  varchar :='|';

 mifFlussoElabMifArr flussoElabMifRecType[];

 mifCountTmpRec integer :=null;
 mifCountRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 tipologiaTipoId integer:=null;
 categoriaTipoId integer:=null;
 famTitEntTipoCategId integer:=null;
 ordinativoSplitId integer:=null;

 -- 20.03.2018 Sofia SIAC-5968
 ordinativoReintroitoId  integer:=null;
 tipoRelREIORD varchar(20):=null;
 tipoRelSPR  varchar(20):=null;
 tipoDocsComm  varchar(50):=null;
 tipoPdcIVA    varchar(50):=null;
 codePdcIVA    varchar(50):=null;

 numeroDocs  varchar(10):=null;
 tipoDocs    varchar(50):=null;
 tipoGruppoDocs   varchar(50):=null;
 docAnalogico varchar(50):=null;
 attrCodeDataScad varchar(50):=null;

 titoloCorrente varchar(10):=null;
 descriTitoloCorrente varchar(50):=null;
 titoloCapitale varchar(10):=null;
 descriTitoloCapitale varchar(50):=null;
 titoloCap varchar(10):=null;
 macroAggrTipoCode varchar(20):=null;
 macroAggrTipoCodeId integer:=null;


 -- 23.02.2018 Sofia jira siac-5849
 defNaturaPag    varchar(100):=null;
 famMacroTitCode varchar(100):=null;
 famMacroTitCodeId integer:=null;

 -- 12.10.2020 Sofia SIAC-7448
 docTipoCodeFSN varchar(10):=null;
 defNaturaPagFSN varchar(10):=null;
 utilizzoNCDSPR varchar(100):=null;
 utilizzoNCDFSN varchar(100):=null;
 docElettronico varchar(50):=null;

 FAM_TIT_ENT_TIPCATEG CONSTANT varchar:='Entrata - TitoliTipologieCategorie';
 CATEGORIA CONSTANT varchar:='CATEGORIA';
 TIPOLOGIA CONSTANT varchar:='TIPOLOGIA';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12;  -- esercizio

 FLUSSO_MIF_ELAB_INIZIO_ORD         CONSTANT integer:=13;  -- tipo_operazione
 FLUSSO_MIF_ELAB_FATTURE            CONSTANT integer:=35;  -- codice_ipa_ente_siope
 -- 12.10.2020 Sofia SIAC-7448
 FLUSSO_MIF_ELAB_FATT_DOC_ELETTRONICO CONSTANT integer:=36;  -- codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC       CONSTANT integer:=40;  -- codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG  CONSTANT integer:=44;  -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG    CONSTANT integer:=46;  -- natura_spesa_siope
 -- 12.10.2020 Sofia SIAC-7448
 FLUSSO_MIF_ELAB_FATT_UT_NOTA_CRED  CONSTANT integer:=74;  -- utilizzo_nota_di_credito
 FLUSSO_MIF_ELAB_NUM_SOSPESO        CONSTANT integer:=62;  -- numero_provvisorio




BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di entrata a SIOPE PLUS.';


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
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo_flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
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
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_entrata_id].';
    codResult:=null;

    select distinct 1 into codResult
    from mif_t_ordinativo_entrata_id mif
    where mif.ente_proprietario_id=enteProprietarioId;


    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_I||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordinativoSpesaTipoId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordinativoSpesaTipoId
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


		-- ordAllegatoCartAttrId
        strMessaggio:='Lettura attributo ordinativo  Code Id '||ALLEG_CART_ATTR||'.';
        select attr.attr_id into strict ordAllegatoCartAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ALLEG_CART_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TIPO_IMPORTO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TIPO_IMPORTO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));



		-- ordinativoTsDetTipoId
        strMessaggio:='Lettura ordinativo_ts_det_tipo '||ORD_TS_DET_TIPO_A||'.';
		select ord_tipo.ord_ts_det_tipo_id into strict ordinativoTsDetTipoId
    	from siac_d_ordinativo_ts_det_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
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

        -- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

		-- tipologiaTipoId
        strMessaggio:='Lettura tipologia_code_tipo_id  '||TIPOLOGIA||'.';
		select tipo.classif_tipo_id into strict tipologiaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TIPOLOGIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

   	    -- categoriaTipoId
        strMessaggio:='Lettura categoria_code_tipo_id  '||CATEGORIA||'.';
		select tipo.classif_tipo_id into strict categoriaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=CATEGORIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));


		-- famTitEntTipoCategId
		-- FAM_TIT_ENT_TIPCATEG='Entrata - TitoliTipologieCategorie'
        strMessaggio:='Lettura fam_tit_ent_tipcategorie_code_tipo_id  '||FAM_TIT_ENT_TIPCATEG||'.';
		select fam.classif_fam_tree_id into strict famTitEntTipoCategId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_ENT_TIPCATEG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
  		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile,flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;


        strMessaggio:='Lettura flusso struttura SIOPE PLUS  per tipo '||MANDMIF_TIPO||'.';
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


        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';

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


        -- calcolo progressivo "distinta" per flusso REVMIF
	    -- calcolo su progressi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso SIOPE PLUS tipo '||MANDMIF_TIPO||'.';
        codResult:=null;

        select prog.prog_value into flussoElabMifDistOilRetId
          from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then
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


	    -- calcolo su progressi di flussoElabMifOilId flussoOIL univoco
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




    --- popolamento mif_t_ordinativo_entrata_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I'
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_entrata_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_codbollo_id,
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
     (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,ord.contotes_id mif_ord_contotes_id,
             ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id, ord.ord_desc mif_ord_desc ,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.codbollo_id mif_ord_codbollo_id,
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
         and  ord.ord_da_trasmettere=true -- 19.06.2018 Sofia Sofia siac-6175
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
      )
      select   o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
      from ordinativi o
	  where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
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
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
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
          and  ord.ord_da_trasmettere=true -- 19.06.2018 Sofia Sofia siac-6175
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
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
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
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
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
         and  ord.ord_da_trasmettere=true -- 19.06.2018 Sofia Sofia siac-6175
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
   		 and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        ),
        -- 16.04.2018 Sofia siac-6067
        enteOil as
        (
         select false esclAnnull
         from siac_t_ente_oil oil
         where oil.ente_proprietario_id=enteProprietarioId
         and   oil.ente_oil_invio_escl_annulli=false
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o, enteOil -- 16.04.2018 Sofia siac-6067
	    where
        ( mifOrdRitrasmElabId is null
	      or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        ) -- 16.04.2018 Sofia siac-6067
        and  enteOil.esclAnnull=false -- 16.04.2018 Sofia siac-6067
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
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
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id, ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
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
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
         and  ord.ord_da_trasmettere=true -- 19.06.2018 Sofia Sofia siac-6175
         and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		 and  ord.ord_trasm_oil_data is not null
 		 and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
         and  ord_stato.validita_fine is null -- SofiaData
         and  ord_stato.ord_stato_id=ordStatoCodeAId
--         and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)-- 30.07.2019 Sofia siac-6950
         and  ( ord.ord_spostamento_data is null or date_trunc('DAY',ord.ord_spostamento_data)<=date_trunc('DAY',ord_stato.validita_inizio))  -- 30.07.2019 Sofia siac-6950
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati )
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil ,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_codbollo_id,
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
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.codbollo_id mif_ord_codbollo_id,
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
         and  ord.ord_da_trasmettere=true -- 19.06.2018 Sofia Sofia siac-6175
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
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_codbollo_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );

      -- aggiornamento mif_t_ordinativo_entrata_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per soggetto_id.';
      -- soggetto_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_soggetto_id = (select s.soggetto_id from siac_r_ordinativo_soggetto s
                                 where s.ord_id=m.mif_ord_ord_id
                                   and s.data_cancellazione is null
                                   and s.validita_fine is null);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);



     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_ts_id = (select ts.movgest_ts_id from siac_t_ordinativo_ts s, siac_r_ordinativo_ts_movgest_ts ts
	                              where s.ord_id=m.mif_ord_ord_id
                                  and   ts.ord_ts_id=s.ord_ts_id
                                  and   s.data_cancellazione is null
                                  and   s.validita_fine is null
                                  and   ts.data_cancellazione is null
                                  and   ts.validita_fine is null
                                  order by s.ord_ts_id
                                  limit 1);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_entrata_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_ordinativo_atto_amm s
                                where s.ord_id = m.mif_ord_ord_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);


    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);


	-- mif_ord_tipologia_id
    -- mif_ord_tipologia_code
    -- mif_ord_tipologia_desc
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per mif_ord_tipologia_id mif_ord_tipologia_code mif_ord_tipologia_desc.';
	update mif_t_ordinativo_entrata_id m
    set (mif_ord_tipologia_id, mif_ord_tipologia_code,mif_ord_tipologia_desc) = (cp.classif_id,cp.classif_code,cp.classif_desc)
    from  siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id= m.mif_ord_elem_id
	and   cf.classif_id=classElem.classif_id
	and   cf.data_cancellazione is null
	and   cf.classif_tipo_id= categoriaTipoid -- categoria
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitEntTipoCategId -- famiglia
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	and   classElem.data_cancellazione is null
	and   classElem.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
	and   cp.data_cancellazione is null
	and   cp.classif_tipo_id=tipologiaTipoid; --tipologia

    strMessaggio:='Verifica esistenza ordinativi di entrata da trasmettere.';
    codResult:=null;

    select 1 into codResult
    from mif_t_ordinativo_entrata_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di entrata da trasmettere.';
    end if;




   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];

   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   raise notice 'numero_provvisorio FLUSSO_MIF_ELAB_NUM_SOSPESO=% strMessaggio=%',FLUSSO_MIF_ELAB_NUM_SOSPESO,strMessaggio;

   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			isRicevutaAttivo:=true;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
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
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            /* 23.02.2018 Sofia JIRA siac-5849
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
            macroAggrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
            if macroAggrTipoCode is not null then
            	strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato classificatore tipo='||macroAggrTipoCode||'.';
            	select tipo.classif_tipo_id into macroAggrTipoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=macroAggrTipoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

            end if;*/

            -- 23.02.2018 Sofia JIRA siac-5849
            macroAggrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            if macroAggrTipoCode is not null then
            	strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato classificatore tipo='||macroAggrTipoCode||'.';
            	select tipo.classif_tipo_id into macroAggrTipoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=macroAggrTipoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

            end if;
            -- 23.02.2018 Sofia JIRA siac-5849
            famMacroTitCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            if famMacroTitCode is not null then
	            strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificato famiglia tipo='||famMacroTitCode||'.';
	            select tree.classif_fam_tree_id into famMacroTitCodeId
				from siac_t_class_fam_tree tree, siac_d_class_fam d
				where d.ente_proprietario_id=enteProprietarioId
				and   d.classif_fam_desc=famMacroTitCode --'Spesa - TitoliMacroaggregati'
				and   tree.classif_fam_id=d.classif_fam_id
                and   tree.data_cancellazione is null
                and   tree.validita_fine is null
                and   d.data_cancellazione is null
                and   d.validita_fine is null;

            end if;

			-- 23.02.2018 Sofia JIRA siac-5849
	        if flussoElabMifElabRec.flussoElabMifDef is not null then
        		defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
    	    end if;

		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   -- 12.10.2020 Sofia SIAC-7448 - inizio
   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_UT_NOTA_CRED;
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
            docTipoCodeFSN:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            defNaturaPagFSN:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            utilizzoNCDSPR:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
            utilizzoNCDFSN:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
		end if;
     else
          RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

    if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DOC_ELETTRONICO;
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
 		    docElettronico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   -- 12.10.2020 Sofia SIAC-7448 - fine

    --- lettura mif_t_ordinativo_entrata_id per popolamento mif_t_ordinativo_entrata
    codResult:=null;
    strMessaggio:='Lettura ordinativi di entrata da migrare [mif_t_ordinativo_entrata_id].Inizio ciclo.';
    for mifOrdinativoIdRec IN
    (select ms.*
     from mif_t_ordinativo_entrata_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
    )
    loop

--		raise notice 'Inizio ciclo numero_ord=%',mifOrdinativoIdRec.mif_ord_ord_numero;
		mifFlussoOrdinativoRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;

        soggettoRifId:=null;

		indirizzoRec:=null;
        mifOrdSpesaId:=null;
	    mifCountRec:=1;
		isIndirizzoBenef:=true;
        bAvvioSiopeNew:=false;

        -- lettura importo ordinativo
		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        										flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura dati soggetto ordinativo
        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;


        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

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
			-- 11.05.2021 Sofia Jira SIAC-8128
			--raise notice '@@@@@@@@@@@@@@@@@@@@@@@@SANITA@@@@@@@@@@@@@@@@@@@@@@@@@=%',flussoElabMifElabRec.flussoElabMifParam;

		    if flussoElabMifElabRec.flussoElabMifParam is not null then
				if coalesce(codiceIstatSanita,'')='' or coalesce(codiceContoSanita,'')='' then
					codiceContoSanita:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
					codiceIstatSanita:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
				--	raise notice '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
				--	raise notice '@@@@@@@@@@@@@@@@@@@@@@@@SANITA@@@@@@@@@@@@@@@@@@@@@@@@@=%',mifOrdinativoIdRec.mif_ord_ord_numero::varchar;
				--	raise notice '@@@@@@@@@@@@@@@@@@@@@@@@codiceContoSanita=%@@@@@@@@@@@@@@@@@@@@@@@@',codiceContoSanita;
				--	raise notice '@@@@@@@@@@@@@@@@@@@@@@@@codiceIstatSanita=%@@@@@@@@@@@@@@@@@@@@@@@@',codiceIstatSanita;
				end if;
		    end if;
		    -- 11.05.2021 Sofia Jira SIAC-8128		 
			
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

		-- <reversale>
        mifCountRec :=FLUSSO_MIF_ELAB_INIZIO_ORD;

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

        raise notice 'tipo_operazione strMessaggio=%',strMessaggio;
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

        -- <numero_reversale>
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
         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_reversale>
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

		-- <importo_reversale>
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
             mifFlussoOrdinativoRec.mif_ord_destinazione:=flussoElabMifValore;
            end if;
			
			-- 11.05.2021 Sofia Jira SIAC-8128 
			--raise notice '@@@@@@@@@@@@@@@@ PRIMA mifFlussoOrdinativoRec.mif_ord_destinazione=%',mifFlussoOrdinativoRec.mif_ord_destinazione;
			if codiceContoSanita=mifFlussoOrdinativoRec.mif_ord_destinazione then
				mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=codiceIstatSanita;
			end if;
			-- 11.05.2021 Sofia Jira SIAC-8128 
			--raise notice '@@@@@@@@@@@@@@@@ DOPO  mifFlussoOrdinativoRec.mif_ord_destinazione=%',mifFlussoOrdinativoRec.mif_ord_destinazione;
			
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


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
        raise notice 'codifica_bilancio strMessaggio=%',strMessaggio;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

         		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=
                    substring(mifOrdinativoIdRec.mif_ord_tipologia_code from 1 for 5) ;
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
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_tipologia_desc from 1 for 30);
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
		  if mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
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

	    -- <informazioni_versante>

        -- <progressivo_versante>
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
        raise notice 'progressivo_versante strMessaggio=%',strMessaggio;

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_vers:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <importo_versante>
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
     		mifFlussoOrdinativoRec.mif_ord_vers_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
        end if;

	    -- <tipo_riscossione>
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
            if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR and
               coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
              if  tipoIncassoCode is null then
            	tipoIncassoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
              end if;
              if tipoRitOrdInc is null then
	              tipoRitOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;
              if tipoSplitOrdInc is null then
	              tipoSplitOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
              if tipoSubOrdInc is null then
	              tipoSubOrdInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;

              if tipoRitenuteInc is null then
              	tipoRitenuteInc:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))||','||
                                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6))||','||
                                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7));
              end if;

			  if tipoIncassoCompensazione is null then
              	tipoIncassoCompensazione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
   			  if tipoIncassoRegolarizza is null then
              	tipoIncassoRegolarizza:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
              end if;

   			  if tipoIncassoCassa is null then
              	tipoIncassoCassa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,3));
              end if;

              if tipoIncassoCode is not null and tipoIncassoCodeId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classif_tipo_id per classicatore '||tipoIncassoCode||'.';
              	select tipo.classif_tipo_id into tipoIncassoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=tipoIncassoCode
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;

              end if;

              if tipoIncassoCodeId is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura tipoIncasso '||tipoIncassoCode||' per ordinativo.';

                flussoElabMifValore:=fnc_mif_tipo_incasso_splus
                                     ( mifOrdinativoIdRec.mif_ord_ord_id,
  									   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC,
                                       tipoRitOrdInc,
                                       tipoSplitOrdInc,
                                       tipoSubOrdInc,
                                       tipoRitenuteInc,
 									   tipoIncassoCodeId,
                                       tipoIncassoCompensazione,
                                       tipoIncassoRegolarizza,
                                       tipoIncassoCassa,
                                       dataElaborazione,
                                       dataFineVal,
                                       enteProprietarioId
                                     );
              end if;

		     if flussoElabMifValore is not null then
	           mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos:=flussoElabMifValore;
             end if;
           end if;
          else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;

	    -- <numero_ccp>
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
          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos is not null then
               if mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  if tipoContoCCPCode is null then
                  	tipoContoCCPCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                  end if;
                  if tipoContoCCPCodeId is null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classificatore tipo='||tipoContoCCPCode||'.';
                  	select tipo.classif_tipo_id into tipoContoCCPCodeId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoContoCCPCode
                    and   tipo.data_cancellazione is null;
                  end if;

                  if tipoContoCCPCodeId is not null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore classificatore tipo='||tipoContoCCPCode||'.';
                  	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoContoCCPCodeId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null;
                  end if;
               end if;
               if flussoElabMifValore is not null then
               	mifFlussoOrdinativoRec.mif_ord_vers_cc_postale:=flussoElabMifValore;
               end if;
            end if;
           else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;

		-- <tipo_entrata>
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
			if coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
              if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR then
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


	             if flussoElabMifValore is null and
     	            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	        mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

    	            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
        	               ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
            	           ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                	       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
	                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
    	                   ||' mifCountRec='||mifCountRec
        	               ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	                -- 16.02.2018 Sofia siac-5874
                    select mif.fruttifero_oi into flussoElabMifValore
    	            from mif_r_conto_tesoreria_fruttifero mif
	                where mif.ente_proprietario_id=enteProprietarioId
    	            and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	                and   mif.validita_fine is null
    	            and   mif.data_cancellazione is null;


	             end if;


                 if flussoElabMifValore is null then
                   	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                 end if;

                 mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


		-- <destinazione>
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

           	if classVincolatoCode is null then
            	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCodeId is null and classVincolatoCode is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into strict classVincolatoCodeId
    		    from siac_d_class_tipo tipo
		        where tipo.ente_proprietario_id=enteProprietarioId
        		and   tipo.classif_tipo_code=classVincolatoCode
		        and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null;
            end if;

            if classVincolatoCodeId is not null then
	            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore classVincolatoCode='||classVincolatoCode||'.';


                 select c.classif_desc into flussoElabMifValore
                 from siac_r_ordinativo_class r, siac_t_class c
                 where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                 and   c.classif_id=r.classif_id
                 and   c.classif_tipo_id=classVincolatoCodeId
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
                 and   c.data_cancellazione is null;
            end if;
           end if;

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

		   if flussoElabMifValore is null and
           	flussoElabMifElabRec.flussoElabMifDef is not null then
            flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
           end if;

           if flussoElabMifValore is not null then
           	mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos:=flussoElabMifValore;
           end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <classificazione>
        -- <codice_cge>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codiceCge:=null;
        descCge:=null;
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
        raise notice 'codice_cge strMessaggio=%',strMessaggio;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if flussoElabMifElabRec.flussoElabMifElab=true  then
         		if flussoElabMifElabRec.flussoElabMifParam is not null  then
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

                    if  bAvvioSiopeNew=true then
                     -- lettura da PDC_V
                  	 if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then --1
						-- codiceFinVTipoTbrId
                        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||codiceFinVTbr||'.';
			   		    select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
				    	from siac_d_class_tipo tipo
						where tipo.ente_proprietario_id=enteProprietarioId
						and   tipo.classif_tipo_code=codiceFinVTbr
						and   tipo.data_cancellazione is null
						and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
						and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
                     end if; --1

                     if codiceFinVTipoTbrId is not null then --2
      		 		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
		    		  select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                       into flussoElabMifValore,flussoElabMifValoreDesc
			  		  from siac_r_ordinativo_class r, siac_t_class class
	       		      where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	      		      and   class.classif_id=r.classif_id
 		              and   class.classif_tipo_id=codiceFinVTipoTbrId
		 	          and   r.data_cancellazione is null
				      and   r.validita_fine is NULL
	  		          and   class.data_cancellazione is null;

			 		  if flussoElabMifValore is null then --3
		               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             		   select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                    	into flussoElabMifValore,flussoElabMifValoreDesc
		    	       from siac_r_movgest_class rclass, siac_t_class class
		               where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
    		           and   rclass.data_cancellazione is null
        		       and   rclass.validita_fine is null
            		   and   class.classif_id=rclass.classif_id
		               and   class.classif_tipo_id=codiceFinVTipoTbrId
    		           and   class.data_cancellazione is null
		               order by rclass.movgest_classif_id
    		           limit 1;
        	           end if; --3
                      end if;--2
                    else
                	 if siopeCodeTipoId is null then --1
                    	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||siopeCodeTipo||'.';

                    	select class.classif_tipo_id into siopeCodeTipoId
                        from siac_d_class_tipo class
                        where class.classif_tipo_code=siopeCodeTipo
                        and   class.ente_proprietario_id=enteProprietarioId
                        and   class.data_cancellazione is null
 				    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	 		 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,dataElaborazione));
                     end if;
                   if siopeCodeTipoId is not null then --2
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore class tipo='||flussoElabMifElabRec.flussoElabMifParam||'.';


                	select class.classif_code, class.classif_desc
                           into flussoElabMifValore,flussoElabMifValoreDesc
                    from siac_r_ordinativo_class cord, siac_t_class class
                    where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and cord.data_cancellazione is null
                    and cord.validita_fine is null
                    and class.classif_id=cord.classif_id
                    and class.classif_tipo_id=siopeCodeTipoId
                    and class.classif_code!=siopeDef
                    and class.data_cancellazione is null;

                    if flussoElabMifValore is null then --3
	                    select class.classif_code, class.classif_desc
    		                   into flussoElabMifValore,flussoElabMifValoreDesc
	                    from siac_r_movgest_class  r,  siac_t_class class
    	                where r.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
        	            and   r.data_cancellazione is null
            	        and   r.validita_fine is null
                	    and class.classif_id=r.classif_id
                    	and class.classif_tipo_id=siopeCodeTipoId
	                    and class.classif_code!=siopeDef
    	                and class.data_cancellazione is null;
                   end if; --3
                  end if; --2
                end if; --if  bAvvioSiopeNew=true then

                if flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
                    codiceCge:=flussoElabMifValore;
	                descCge:=flussoElabMifValoreDesc;


               end if;
            end if; --param
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if; -- elab
        end if; -- attivo

	    -- <importo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
	    if codiceCge is not null then
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
	   end if;

       -- <classificazione_dati_siope_entrate>

       -- <tipo_debito_siope_c> COMMERCIALE
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       isOrdCommerciale:=false;
       ordinativoSplitId:=null;
       ordinativoReintroitoId:=null;
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
	          if flussoElabMifElabRec.flussoElabMifDef is not null and
                 flussoElabMifElabRec.flussoElabMifParam is not null then
				 -- 20.03.2018 Sofia SIAC-5968
                 if  tipoRelSPR is null then
                 		tipoRelSPR:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                 end if;
   				 -- 20.03.2018 Sofia SIAC-5968
                 if tipoRelREIORD is null then
                    tipoRelREIORD:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                 end if;

                 -- 12.10.2020 Sofia SIAC-7448 - spostato da sotto a qui
                 if coalesce(tipoDocsComm,'')='' then
                      tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                        trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))||'|'||
                        trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                 end if;

                 -- 20.03.2018 Sofia SIAC-5968
			     if tipoRelSPR is not null and tipoRelSPR!='' then
				  -- caso di ordinativo di incasso collegato a ordinativo di pagamento per Split
                  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento SPLIT.';

  		          select ord.ord_id into ordinativoSplitId
			      from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			          siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
				  where rord.ord_id_a=mifOrdinativoIdRec.mif_ord_ord_id
				  and   ord.ord_id=rord.ord_id_da
				  and   tipo.ord_tipo_id=ord.ord_tipo_id
				  and   tipo.ord_tipo_code='P'
			      and   rstato.ord_id=ord.ord_id
	              and   stato.ord_stato_id=rstato.ord_stato_id
--	              and   stato.ord_stato_code!='A' -- 15.10.2020 Sofia Jira SIAC-7448
				  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
                  --and   tiporel.relaz_tipo_code=flussoElabMifElabRec.flussoElabMifParam -- 20.03.2018 Sofia SIAC-5968
                  and   tiporel.relaz_tipo_code=tipoRelSPR
				  and   rord.data_cancellazione is null
				  and   rord.validita_fine is null
				  and   ord.data_cancellazione is null
			      and   ord.validita_fine is null
			      and   rstato.data_cancellazione is null
	              and   rstato.validita_fine is null
                  limit 1;

            	  if ordinativoSplitId is not null then
                    -- 20.03.2018 Sofia SIAC-5968
                    --mifFlussoOrdinativoRec.mif_ord_class_tipo_debito=flussoElabMifElabRec.flussoElabMifDef;
                    isOrdCommerciale:=true;
        	      end if;
                end if;

                -- 20.03.2018 Sofia SIAC-5968
                if isOrdCommerciale=false and  tipoRelREIORD is not null and tipoRelREIORD!='' then

                  -- caso di ordinativo di incasso collegato a ordinativo di pagamento per Reintroito
                  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento Rentroito.';

  		          select ord.ord_id into ordinativoReintroitoId
			      from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			           siac_d_relaz_tipo tiporel
				  where rord.ord_id_da=mifOrdinativoIdRec.mif_ord_ord_id
				  and   ord.ord_id=rord.ord_id_a
				  and   tipo.ord_tipo_id=ord.ord_tipo_id
				  and   tipo.ord_tipo_code='P'
				  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
                  and   tiporel.relaz_tipo_code=tipoRelREIORD
				  and   rord.data_cancellazione is null
				  and   rord.validita_fine is null
				  and   ord.data_cancellazione is null
			      and   ord.validita_fine is null
                  limit 1;


                  if ordinativoReintroitoId is not null then
                  	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
        			   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento Rentroito. Commerciale.';

                     -- 12.10.2020 Sofia SIAC-7448 - spostato sopra
                    /*if coalesce(tipoDocsComm,'')='' then
                      tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                        trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))||'|'||
                        trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    end if;*/

                  	isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_splus(ordinativoReintroitoId,
			                                                                    tipoDocsComm,
                  				                                   	            enteProprietarioId
                                                                               );
                    if isOrdCommerciale=true then
                    	ordinativoSplitId:=ordinativoReintroitoId;
                    end if;

                  end if;

               end if;

			   -- 12.10.2020 Sofia SIAC-7448
               if isOrdCommerciale=false then
               	isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_e_splus(mifOrdinativoIdRec.mif_ord_ord_id,
																	  		  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6)),
                  				                                   	          enteProprietarioId
                                                                              );
               end if;

               -- 20.03.2018 Sofia SIAC-5968
 			   if isOrdCommerciale=true then
	               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito=flussoElabMifElabRec.flussoElabMifDef;

               end if;

              end if;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	      end if;
       end if;

	   -- <tipo_debito_siope_nc> NON_COMMERCIALE se non COMMERCIALE -- NON COMMERCIALE
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       codResult:=null;
       mifCountRec:=mifCountRec+1;
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
           if flussoElabMifElabRec.flussoElabMifDef is not null then -- 20.03.2018 Sofia SIAC-5968
/*	          if flussoElabMifElabRec.flussoElabMifDef is not null then -- 20.03.2018 Sofia SIAC-5968
                   mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc=flussoElabMifElabRec.flussoElabMifDef;
              end if;*/

              -- 20.03.2018 Sofia SIAC-5968 - test sul pdcFin di OP per verificare se IVA
              if ordinativoReintroitoId is not null and
                 flussoElabMifElabRec.flussoElabMifParam is not null then
                 tipoPdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                 codePdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                 if coalesce(tipoPdcIVA ,'')!='' and
                    coalesce(codePdcIVA ,'')!='' then
                        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
		                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                		       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
        		               ||' mifCountRec='||mifCountRec
        					   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura ordinativo di pagamento Rentroito. Iva.';
                    	select 1 into codResult
                        from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipo
                        where rc.ord_id=ordinativoReintroitoId
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
              -- 20.03.2018 Sofia SIAC-5968
              if flussoElabMifValore is null then
              	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
              -- 20.03.2018 Sofia SIAC-5968
              if flussoElabMifValore is not null then
	              mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc=flussoElabMifValore;
              end if;
            end if;
	      else
    	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	      end if;
        end if;
       end if;


       mifCountRec:=mifCountRec+12;
       -- <fatture_siope>
	   -- </fatture_siope>

       -- <dati_ARCONET_siope>
       -- <codice_economico_siope>
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

         	if codiceFinVTbr is null then
            	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;
 			if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then --1
				-- codiceFinVTipoTbrId
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||codiceFinVTbr||'.';
			   select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			   from siac_d_class_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.classif_tipo_code=codiceFinVTbr
			   and   tipo.data_cancellazione is null
			   and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
			   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
            end if; --1

            if codiceFinVTipoTbrId is not null then --2
      			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
		    	select class.classif_code into flussoElabMifValore
  	  		    from siac_r_ordinativo_class r, siac_t_class class
	       	    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	      	      and   class.classif_id=r.classif_id
 		          and   class.classif_tipo_id=codiceFinVTipoTbrId
		 	      and   r.data_cancellazione is null
			      and   r.validita_fine is NULL
	  		      and   class.data_cancellazione is null;

			   if flussoElabMifValore is null then --3
		     	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             	   select class.classif_desc into flussoElabMifValore
	    	       from siac_r_movgest_class rclass, siac_t_class class
	               where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
   		           and   rclass.data_cancellazione is null
       		       and   rclass.validita_fine is null
           		   and   class.classif_id=rclass.classif_id
	               and   class.classif_tipo_id=codiceFinVTipoTbrId
   		           and   class.data_cancellazione is null
	               order by rclass.movgest_classif_id
   		           limit 1;
   	           end if; --3
           end if;--2
 /*      	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo evento '||flussoElabMifElabRec.flussoElabMifParam||'.';

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
          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_collegamento_tipo coll, siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where coll.ente_proprietario_id=enteProprietarioId
          and   coll.collegamento_tipo_id=collEventoCodeId
          and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Avere
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
         end if;*/

	    end if; -- param
        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
			-- SIAC-7807 06.10.2020 Sofia
            mifFlussoOrdinativoRec.mif_ord_class_economico:=mifFlussoOrdinativoRec.mif_ord_class_codice_cge;
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

	  -- <codice_ue_siope>
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
		 	 and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       		end if;

	        if codiceUECodeTipoId is not null then

        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_ordinativo_class].';
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

		     if flussoElabMifValore is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_movgest_class].';
				select class.classif_code into flussoElabMifValore
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	            and   rclass.data_cancellazione is null
	            and   rclass.validita_fine is null
	            and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=codiceUECodeTipoId
	            and   class.data_cancellazione is null
	            order by rclass.movgest_classif_id
	            limit 1;
             end if;
        	end if;

	        if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
    	    end if;
          end if;
	   else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
      end if;

	  -- <codice_entrata_siope>
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
		 	 and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
       		end if;

	        if ricorrenteCodeTipoId is not null then

        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_ordinativo_class].';
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_t_class [siac_r_movgest_class].';
				select upper(class.classif_desc) into flussoElabMifValore
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	            and   rclass.data_cancellazione is null
	            and   rclass.validita_fine is null
	            and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=ricorrenteCodeTipoId
	            and   class.data_cancellazione is null
	            order by rclass.movgest_classif_id
	            limit 1;
             end if;
        	end if;

	        if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_class_ricorrente_entrata:=flussoElabMifValore;
    	    end if;
          end if;
	   else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
      end if;



       -- </dati_ARCONET_siope>
       -- </classificazione_dati_siope_entrate>
       -- </classificazione>

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
            -- se REGOLARIZZAZIONE IMPOSTAZIONE DI ESENTE BOLLO
            if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos is not null and
/*               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos=
                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) -- REGOLARIZZAZIONE*/
               mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos in  -- siac-5652 14.12.2017 Sofia
               ( trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                 trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- REGOLARIZZAZIONE ACCREDITO BANCA d'ITALIA
               )
                  then
                   mifFlussoOrdinativoRec.mif_ord_bollo_carico:=
                       trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                   mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=
                    trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));

                   codiceBolloPlusEsente:=true;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico  is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , replace(plus.codbollo_plus_desc,'BENEFICIARIO','VERSANTE'), plus.codbollo_plus_esente
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
--              27.06.2018 Sofia siac-6272
--			mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
          	mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=ordCodiceBolloDesc;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
	  -- </bollo>

      -- <versante>
      -- <anagrafica_versante>
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
            	flussoElabMifValore:=soggettoRec.soggetto_desc;

                if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_anag_versante:=substring(flussoElabMifValore from 1 for 140);
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	   -- <indirizzo_versante>
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
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;
	            if indirizzoRec is null then
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

	             if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_indir_versante:=substring(flussoElabMifValore from 1 for 30);
        	     end if;
               end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

   	   -- <cap_versante>
       mifCountRec:=mifCountRec+1;
	   if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null  then
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
	            mifFlussoOrdinativoRec.mif_ord_cap_versante:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
       end if;


       -- <localita_beneficiario>
       mifCountRec:=mifCountRec+1;
	   if isIndirizzoBenef=true then
        if indirizzoRec.comune_id is not null  then
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
	            mifFlussoOrdinativoRec.mif_ord_localita_versante:=substring(flussoElabMifValore from 1 for 30);
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
        if indirizzoRec.comune_id is not null  then
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
	            mifFlussoOrdinativoRec.mif_ord_prov_versante:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	 end if;


	 -- <stato_versante>
  	 mifCountRec:=mifCountRec+1;

     -- <partita_iva_versante>
     mifCountRec:=mifCountRec+1;
     if soggettoRec.partita_iva is not null or
        (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11) then
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
                	 mifFlussoOrdinativoRec.mif_ord_partiva_versante:=soggettoRec.partita_iva;
                else
                	mifFlussoOrdinativoRec.mif_ord_partiva_versante:=trim ( both ' ' from soggettoRec.codice_fiscale);
                end if;

          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;
      end if;

      -- <codice_fiscale_versante>
      mifCountRec:=mifCountRec+1;
      if soggettoRec.partita_iva is null  then
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
          	if soggettoRec.codice_fiscale is not null and
  			   length(soggettoRec.codice_fiscale)=16 then
				flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		            mifFlussoOrdinativoRec.mif_ord_codfisc_versante:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;
     -- </versante>

     -- <causale>
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
            mifFlussoOrdinativoRec.mif_ord_vers_causale:=
	            replace(replace(substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <sospeso>
      -- <sospesi>
      -- <numero_provvisorio>
      -- <importo_provvisorio>
      mifCountRec:=mifCountRec+2;


      -- <mandato_associato>
      -- <numero_mandato>
      -- <progressivo_associato>
      mifCountRec:=mifCountRec+2;

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
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <riferimento_documento_esterno>
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
        		if flussoElabMifElabRec.flussoElabMifDef is not null AND
                   flussoElabMifElabRec.flussoElabMifParam is not null then -- 30.07.2018 Sofia siac-6202

					-- 30.07.2018 Sofia siac-6202
                    if coalesce(trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)),'')!='' then
                       codResult:=null;
                       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura presenza classificatore ritenute stipendi.';
                       select 1 into codResult
                       from siac_r_ordinativo_class rc, siac_t_class c , siac_d_class_tipo tipo
                       where tipo.ente_proprietario_id=enteProprietarioId
                       and   tipo.classif_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
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
                       	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2))
                                             ||' '||flussoElabMifValore;
                       end if;
                    end if;
                    -- 30.07.2018 Sofia siac-6202



                    -- 30.07.2018 Sofia siac-6202
                    if  coalesce(flussoElabMifValore,'')=''   then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura presenza allegati cartacei.';
					 codResult:=null;
                	 select 1 into codResult
				     from siac_r_ordinativo_attr rattr
					 where rattr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                     and   rattr.attr_id=ordAllegatoCartAttrId
				     and   rattr.boolean='S'
					 and   rattr.data_cancellazione is null
				     and   rattr.validita_fine is null;

/*                     if codResult is not null then
		                mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifElabRec.flussoElabMifDef;
			         end if;*/
                     if codResult is not null then
		                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
			         end if;
                    end if;

					-- 30.07.2018 Sofia siac-6202
			    	if  coalesce(flussoElabMifValore,'')!=''   then
                    	mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifValore;

                    end if;

             end if;
		else
    		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;
      -- </informazioni_aggiuntive>

      -- <sostituzione_reversale>
      -- <numero_reversale_da_sostituire>
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
        			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ordinativi di sostituzione.';
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);

                    if ordSostRec is not null then
                    	mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                    end if;
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

      end if;

      mifCountRec:=mifCountRec+1;
      -- <progressivo_reversale_da_sostituire>
      if mifFlussoOrdinativoRec.mif_ord_num_ord_colleg is not null then
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
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;
 	 end if;

     -- <esercizio_reversale_da_sostituire>
     mifCountRec:=mifCountRec+1;
     if mifFlussoOrdinativoRec.mif_ord_num_ord_colleg is not null then
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
	-- </sostituzione_reversale>

    -- <dati_a_disposizione_ente_versante> facoltativo non valorizzato
    -- </informazioni_versante>

    -- <dati_a_disposizione_ente_reversale>
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
    -- </dati_a_disposizione_ente_reversale>
    -- </reversale>



  /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
  raise notice 'numero_reversale= %',mifFlussoOrdinativoRec.mif_ord_numero;
  raise notice 'data_reversale= %',mifFlussoOrdinativoRec.mif_ord_data;
  raise notice 'importo_reversale= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

  strMessaggio:='Inserimento mif_t_ordinativo_entrata per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_entrata
        (
		 mif_ord_flusso_elab_mif_id,
		 mif_ord_ord_id,
		 mif_ord_bil_id,
		 mif_ord_anno,
		 mif_ord_numero,
         mif_ord_codice_funzione,
		 mif_ord_data,
		 mif_ord_importo,
		 mif_ord_bci_tipo_contabil,
		 mif_ord_bci_tipo_entrata,
		 --mif_ord_bci_numero_doc,
		 mif_ord_destinazione,
		 mif_ord_codice_abi_bt,
		 mif_ord_codice_ente,
		 mif_ord_desc_ente,
		 mif_ord_codice_ente_bt,
		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
		 mif_ord_data_creazione_flusso,
		 mif_ord_anno_flusso,
         mif_ord_id_flusso_oil,
		 mif_ord_codice_struttura,
		 mif_ord_ente_localita,
		 mif_ord_ente_indirizzo,
		 mif_ord_cod_raggrup,
		 mif_ord_progr_vers,
		 mif_ord_class_codice_cge,
		 mif_ord_class_importo,
		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
		 mif_ord_articolo,
		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
		 mif_ord_gestione,
		 mif_ord_anno_res,
		 mif_ord_importo_bil,
		 mif_ord_anag_versante,
		 mif_ord_indir_versante,
		 mif_ord_cap_versante,
		 mif_ord_localita_versante,
		 mif_ord_prov_versante,
		 mif_ord_partiva_versante,
		 mif_ord_codfisc_versante,
		 mif_ord_bollo_esenzione,
		 mif_ord_vers_tipo_riscos,
		 mif_ord_vers_cod_riscos,
		 mif_ord_vers_importo,
		 mif_ord_vers_causale,
		 mif_ord_lingua,
		 mif_ord_rif_doc_esterno,
		 mif_ord_info_tesoriere,
		 mif_ord_flag_copertura,
		 mif_ord_sost_rev,
		 mif_ord_num_ord_colleg,
		 mif_ord_progr_ord_colleg,
		 mif_ord_anno_ord_colleg,
		 mif_ord_numero_acc,
		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
		 mif_ord_siope_codice_cge,
		 mif_ord_siope_descri_cge,
		 mif_ord_descri_estesa_cap,
         mif_ord_codice_ente_ipa, -- newSiope+
	     mif_ord_codice_ente_istat,
		 mif_ord_codice_ente_tramite,
		 mif_ord_codice_ente_tramite_bt,
		 mif_ord_riferimento_ente,
         mif_ord_vers_cc_postale,
		 mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
		 mif_ord_class_economico,
		 mif_ord_class_importo_economico,
		 mif_ord_class_transaz_ue,
		 mif_ord_class_ricorrente_entrata,
		 mif_ord_bollo_carico,
		 mif_ord_stato_versante,
		 mif_ord_codice_distinta,
		 mif_ord_codice_atto_contabile, -- newSiope+
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
  		 flussoElabMifLogId, --idElaborazione univoco -- mif_ord_flusso_elab_mif_id
  		 mifOrdinativoIdRec.mif_ord_ord_id,     -- mif_ord_ord_id
		 mifOrdinativoIdRec.mif_ord_bil_id,     -- mif_ord_bil_id
  		 mifOrdinativoIdRec.mif_ord_ord_anno,   -- mif_ord_anno
  		 mifFlussoOrdinativoRec.mif_ord_numero, -- mif_ord_numero
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione, -- mif_ord_codice_funzione
  		 mifFlussoOrdinativoRec.mif_ord_data, -- mif_ord_data
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end), -- mif_ord_importo
         mifFlussoOrdinativoRec.mif_ord_importo,  -- mif_ord_importo
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,  -- mif_ord_bci_tipo_contabil
  	     mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata,   -- mif_ord_bci_tipo_entrata
 		 --mifFlussoOrdinativoRec.mif_ord_bci_numero_doc,   -- mif_ord_bci_numero_doc
 	 	 mifFlussoOrdinativoRec.mif_ord_destinazione,       -- mif_ord_destinazione
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,      -- mif_ord_codice_abi_bt
 		mifFlussoOrdinativoRec.mif_ord_codice_ente,         -- mif_ord_codice_ente
		mifFlussoOrdinativoRec.mif_ord_desc_ente,           -- mif_ord_desc_ente
  		mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,      -- mif_ord_codice_ente_bt
 		mifFlussoOrdinativoRec.mif_ord_anno_esercizio,      -- mif_ord_anno_esercizio
--  		annoBilancio||flussoElabMifDistOilId::varchar,  -- flussoElabMifDistOilId
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,                  -- mif_ord_anno_flusso
		flussoElabMifOilId, --idflussoOil                   -- mif_ord_id_flusso_oil
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,  -- mif_ord_codice_struttura
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,     -- mif_ord_ente_localita
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,    -- mif_ord_ente_indirizzo
        mifFlussoOrdinativoRec.mif_ord_cod_raggrup,       -- mif_ord_cod_raggrup
 		mifFlussoOrdinativoRec.mif_ord_progr_vers,        -- mif_ord_progr_vers
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,  -- mif_ord_class_codice_cge
        mifFlussoOrdinativoRec.mif_ord_class_importo,     -- mif_ord_class_importo
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio, -- mif_ord_codifica_bilancio
        mifFlussoOrdinativoRec.mif_ord_capitolo,          -- mif_ord_capitolo
  		mifFlussoOrdinativoRec.mif_ord_articolo,          -- mif_ord_articolo
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,     -- mif_ord_desc_codifica
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil, -- mif_ord_desc_codifica_bil
		mifFlussoOrdinativoRec.mif_ord_gestione,          -- mif_ord_gestione
 		mifFlussoOrdinativoRec.mif_ord_anno_res,          -- mif_ord_anno_res
        mifFlussoOrdinativoRec.mif_ord_importo_bil,       -- mif_ord_importo_bil
        mifFlussoOrdinativoRec.mif_ord_anag_versante,     -- mif_ord_anag_versante
  		mifFlussoOrdinativoRec.mif_ord_indir_versante,    -- mif_ord_indir_versante
		mifFlussoOrdinativoRec.mif_ord_cap_versante,      -- mif_ord_cap_versante
 		mifFlussoOrdinativoRec.mif_ord_localita_versante, -- mif_ord_localita_versante
  		mifFlussoOrdinativoRec.mif_ord_prov_versante,     -- mif_ord_prov_versante
 		mifFlussoOrdinativoRec.mif_ord_partiva_versante,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_versante,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
        mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos,
        mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos,
        mifFlussoOrdinativoRec.mif_ord_vers_importo,
        mifFlussoOrdinativoRec.mif_ord_vers_causale,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
        mifFlussoOrdinativoRec.mif_ord_sost_rev,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_numero_acc,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa, -- newSiope+
	    mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
		mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
		mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
		mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_vers_cc_postale,
	    mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,    -- commerciale
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc, -- non_commerciale
	    mifFlussoOrdinativoRec.mif_ord_class_economico,
	    mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
	    mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
	    mifFlussoOrdinativoRec.mif_ord_class_ricorrente_entrata,
	    mifFlussoOrdinativoRec.mif_ord_bollo_carico,
	    mifFlussoOrdinativoRec.mif_ord_stato_versante,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
	    mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile, -- newSiope+
        now(),
        enteProprietarioId,
        loginOperazione
     )
     returning mif_ord_id into mifOrdSpesaId;



   /* da vedere
     if isGestioneQuoteOK=true then
	  quoteOrdinativoRec:=null;
	  mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura quote ordinativo.';

	for quoteOrdinativoRec in
    (select *
	 from fnc_mif_ordinativo_quote_entrata(mifOrdinativoIdRec.mif_ord_ord_id,
		 								   ordinativoTsDetTipoId,movgestTsTipoSubId,
                                           classCdrTipoId,classCdcTipoId,
        		                           enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
  		-- <Numero_quota_reversale>
		mifCountRec:=FLUSSO_MIF_ELAB_NUM_QUOTA_MAND;
	    flussoElabMifElabRec:=null;
        codResult:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];


    end loop;

 end if; */





 -- <sospesi>
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
                       ||' in mif_t_ordinativo_entrata_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_entrata_ricevute
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

  -- dati fatture da valorizzare se ordinativo commerciale
  -- @@@@ sicuramente da completare
  -- <fattura_siope>
  if isGestioneFatture = true and isOrdCommerciale=true
     and ordinativoSplitId is not null then -- 13.10.2020 Sofia SIAC-7448
   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   titoloCap:=null;
   codResult:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];

   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura macroaggregato ordinativo di spesa collegato.';
--   select c.classif_code into titoloCap
   -- 23.02.2018 Sofia JIRA siac-5849
   select c.classif_id into codResult
   from siac_r_ordinativo_bil_elem re, siac_r_bil_elem_class rc,
        siac_t_class c
   where re.ord_id=ordinativoSplitId
   and   rc.elem_id=re.elem_id
   and   c.classif_id=rc.classif_id
   and   c.classif_tipo_id=macroAggrTipoCodeId
   and   re.data_cancellazione is null
   and   re.validita_fine is null
   and   rc.data_cancellazione is null
   and   rc.validita_fine is null
   and   c.data_cancellazione is null;

   -- 23.02.2018 Sofia JIRA siac-5849
   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa ordinativo di spesa collegato.';
   select oil.oil_natura_spesa_desc into titoloCap
   from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r,
        siac_r_class_fam_tree rtree
   where rtree.classif_fam_tree_id=famMacroTitCodeId
   and   rtree.classif_id=codResult -- macroaggregatoId
   and   r.oil_natura_spesa_titolo_id=rtree.classif_id_padre
   and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
   and   rtree.data_cancellazione is null
   and   rtree.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null;

  if titoloCap is null then titoloCap:=defNaturaPag; end if;
  -- 26.02.2018 Sofia JIRA siac-5849 - esclusione note credito  per ordinativi di incasso
  titoloCap:=titoloCap||'|S';

  /**  -- 23.02.2018 Sofia JIRA siac-5849
  if titoloCap is not null then
    if substring(titoloCap from 1 for 1)=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
    else
     if substring(titoloCap from 1 for 1)=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
     end if;
    end if;
   end if; **/

   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.';
   ordRec:=null;
   for ordRec in
   (select * from fnc_mif_ordinativo_documenti_splus( ordinativoSplitId, -- cerco i documenti relativi a ordinativo di pagamento collegato per split
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
           -- 12.10.2020 Sofia SIAC-7448
           mif_ord_doc_ut_nota_credito,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
--          ordRec.numero_fattura_siope,
          'E', -- 07.06.2018 Sofia SIAC-6228
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          --ordRec.importo_siope,     -- 22.12.2017 Sofia siac-5665
          ordRec.importo_siope_split, -- 22.12.2017 Sofia siac-5665
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          (case when ordinativoReintroitoId is null then utilizzoNCDSPR else null end), -- 12.10.2020 Sofia SIAC-7448
          now(),
          enteProprietarioId,
          loginOperazione
         );
    end loop;
   end if;

   -- 12.10.2020 Sofia SIAC-7448  - inizio
   -- -- <fattura_siope> - documenti FSN - fatture attive collegate direttamente alla reversale
   -- provenienti da NCD negative non integrabili nel pagamento
   if isGestioneFatture = true and isOrdCommerciale=true then
   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   codResult:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];


   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Gestione fatture - FSN.';
   ordRec:=null;
   for ordRec in
   (select * from fnc_mif_ordinativo_documenti_fsn_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											          numeroDocs::integer,
                                                      docTipoCodeFSN,
                                                      docAnalogico,
                                                      docElettronico,
                                                      attrCodeDataScad,
                                                      defNaturaPagFSN,
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
           mif_ord_doc_ut_nota_credito,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          'E',
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
          utilizzoNCDFSN, -- 12.10.2020 Sofia SIAC-7448
          now(),
          enteProprietarioId,
          loginOperazione
         );
    end loop;
   end if;
   -- 12.10.2020 Sofia SIAC-7448  - fine

   numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;

   end loop;

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
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_entrata')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di entrata.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;
    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1000),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'') ||' '||mifCountRec||'.';
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1500),'')||' '||mifCountRec||'.' ;
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
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
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
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
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
		raise notice '% % Errore DB % % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1000),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500)||' '||mifCountRec||'.' ;
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

alter function siac.fnc_mif_ordinativo_entrata_splus 
(
   integer, varchar, varchar, varchar, timestamp, integer,
   out integer, out integer, out integer, out varchar, out integer, out varchar
) owner to siac;