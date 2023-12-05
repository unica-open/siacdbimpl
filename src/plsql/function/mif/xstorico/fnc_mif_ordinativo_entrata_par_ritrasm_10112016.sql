/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 20.04.2016 Sofia - compilata in prod bilmult
-- 18.04.2016 Sofia - versione con paramentro di ritrasmissione e join con mif_t_ordinativo_ritrasmesso
-- 27.05.2016 Sofia - JIRA-3619- aggiunto parametro di ritorno x restituire flussoElabMifDistOilId

drop FUNCTION fnc_mif_ordinativo_entrata
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  mifOrdRitrasmElabId integer,
    out flussoElabMifDistOilId integer, -- 25.05.2016 Sofia - JIRA-3619

  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
  out nomeFileMif varchar,
  out codiceRisultato integer,
  out messaggioRisultato varchar );


CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_entrata
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  mifOrdRitrasmElabId integer,
  out flussoElabMifDistOilId integer, -- 27.05.2016 Sofia - JIRA-3619
  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
  out nomeFileMif varchar,
  out codiceRisultato integer,
  out messaggioRisultato varchar )
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
 mifFlussoOrdDispeBenefRec mif_t_ordinativo_entrata_disp_ente_vers%rowtype;

 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;


 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;
 datiNascitaRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;
 ordinativoAssocRec record;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;


 -- 26.01.2016 SofiaJira
 isIndirizzoBenef boolean:=false;

 annoAttoAmm varchar(10):=null;
 numeroAttoAmm varchar(50):=null;
 tipoAttoAmm varchar(10):=null;
 sacAttoAmm varchar(10):=null;
 classifCdrTipoId integer :=null;
 classifCdcTipoId integer :=null;
 classifCdrTipoCode varchar(10):=null;
 classifCdcTipoCode varchar(10):=null;

 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;

 -- 22.01.2016 Sofia ABI36
 codiceEntrataCodeTipo varchar(50):=null;
 codiceEntrataCodeTipoId integer :=null;

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


 capOrigAttrId integer:=null;
 noteOrdAttrId integer:=null;


 ambitoFinId integer:=null;

 isDefAnnoRedisuo  varchar(5):=null;

 -- ritenute
 isRicevutaAttivo boolean:=false;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;
 eventoTipoCodeId integer:=null;
 codiceFinanzTipo varchar(50):=null;
 codiceFinanzTipoId integer :=null;


 -- 15.03.2016 Sofia ABI36
 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;
 tipoIncassoCode  varchar(100):=null;
 tipoIncassoCodeId  integer:=null;

 ordAllegatoCartAttrId integer:=null;
 ordinativoTsDetTipoId integer:=null;
 movgestTsTipoSubId integer:=null;
 ordinativoSpesaTipoId integer:=null;
 isGestioneQuoteOK boolean:=false;
 isGestioneMandAssQuoteOK boolean:=false;

 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false; -- 21.01.2016 Sofia ABI36

 flussoElabMifOilId integer :=null;
-- flussoElabMifDistOilId integer:=null; -- 27.05.2016 Sofia - JIRA-3619
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 NVL_STR               CONSTANT VARCHAR:='';
 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;

 -- Transazione elementare
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;

 codiceFinVTbr varchar(50):=null;
 codiceEconPatTbr varchar(50):=null;
 transazioneUeTbr varchar(50):=null;
 siopeTbr varchar(50):=null;
 ricorrenteTbr varchar(50):=null;
 aslTbr varchar(50):=null;

 codiceFinVTipoTbrId integer:=null;
 ricorrenteTipoTbrId integer:=null;
 aslTipoTbrId integer:=null;

 codiceFinVCodeTbr varchar(50):=null;
 contoEconCodeTbr varchar(50):=null;
 codiceUeCodeTbr varchar(50):=null;
 siopeCodeTbr varchar(50):=null;
 ricorrenteCodeTbr varchar(50):=null;
 aslCodeTbr  varchar(50):=null;
 isTransElemAttiva boolean :=false;

 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_TIPO_CODE_I  CONSTANT  varchar :='I';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_TIPO_IMPORTO_A CONSTANT  varchar :='A';


 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 CAP_ORIGINE_ATTR CONSTANT  varchar :='numeroCapitoloOrigine';
 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';


 ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';

 FUNZIONE_CODE_I CONSTANT  varchar :='I';
 FUNZIONE_CODE_S CONSTANT  varchar :='S';
 FUNZIONE_CODE_N CONSTANT  varchar :='N';
 FUNZIONE_CODE_A CONSTANT  varchar :='A';
 FUNZIONE_CODE_VB CONSTANT  varchar :='VB';

 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='REVMIF';


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

 FAM_TIT_ENT_TIPCATEG CONSTANT varchar:='Entrata - TitoliTipologieCategorie';
 CATEGORIA CONSTANT varchar:='CATEGORIA';
 TIPOLOGIA CONSTANT varchar:='TIPOLOGIA';


 datiDispEnteBenef boolean:=false; --22.01.2016 Sofia ABI3

 FLUSSO_MIF_ELAB_NUM_MAND_ASSOC CONSTANT integer:=65;

-- FLUSSO_MIF_ELAB_FLAG_COPERTURA CONSTANT integer:=122;
 FLUSSO_MIF_ELAB_NUM_RICEVUTA   CONSTANT integer:=45;
 FLUSSO_MIF_ELAB_IMP_RICEVUTA   CONSTANT integer:=46;
 FLUSSO_MIF_ELAB_CAP_ORIGINE    CONSTANT integer:=51; -- primo elemento di dati a disposizione ente
 FLUSSO_MIF_ELAB_NUM_QUOTA_MAND CONSTANT integer:=77;
 FLUSSO_MIF_ELAB_CODICE_CGE     CONSTANT integer:=21;

 NUMERO_DATI_DISP_ENTE          CONSTANT integer:=37;

 FLUSSO_MIF_ELAB_TBR            CONSTANT integer:=94;
 FLUSSO_MIF_ELAB_DISP_ABI36     CONSTANT integer:=95; -- 22.01.2016 Sofia ABI36 dati_a_disposizione_ente_versante


BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;
    -- 27.05.2016 Sofia - JIRA-3619
    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di entrata al MIF.';

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
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_entrata_id].';
    codResult:=null;
--    execute  'ANALYZE mif_t_ordinativo_entrata_id;';
/*    select 1 into codResult
    from mif_t_ordinativo_entrata_id where ente_proprietario_id=enteProprietarioId;*/

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
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));

		-- ordinativoSpesaTipoId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordinativoSpesaTipoId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));

        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));


        -- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));


		-- ordAllegatoCartAttrId
        strMessaggio:='Lettura attributo ordinativo  Code Id '||ALLEG_CART_ATTR||'.';
        select attr.attr_id into strict ordAllegatoCartAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ALLEG_CART_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal));

		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TIPO_IMPORTO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TIPO_IMPORTO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));



		-- ordinativoTsDetTipoId
        strMessaggio:='Lettura ordinativo_ts_det_tipo '||ORD_TS_DET_TIPO_A||'.';
		select ord_tipo.ord_ts_det_tipo_id into strict ordinativoTsDetTipoId
    	from siac_d_ordinativo_ts_det_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));

        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));

        -- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));

		-- noteOrdAttrId
        strMessaggio:='Lettura noteOrdAttrId per attributo='||NOTE_ORD_ATTR||'.';
		select attr.attr_id into strict noteOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ORD_ATTR
        and   attr.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 	 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal));

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
		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal));

   	    -- categoriaTipoId
        strMessaggio:='Lettura categoria_code_tipo_id  '||CATEGORIA||'.';
		select tipo.classif_tipo_id into strict categoriaTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=CATEGORIA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal));



		-- famTitEntTipoCategId
		-- FAM_TIT_ENT_TIPCATEG='Entrata - TitoliTipologieCategorie'
        strMessaggio:='Lettura fam_tit_ent_tipcategorie_code_tipo_id  '||FAM_TIT_ENT_TIPCATEG||'.';
		select fam.classif_fam_tree_id into strict famTitEntTipoCategId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_ENT_TIPCATEG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(fam.validita_fine,dataFineVal));

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile,flussoElabMifTipoDec -- 21.01.2016 Sofia ABI36
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;


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
 			and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataFineVal))
            order by indir.indirizzo_id;
        end if;


        -- 18.04.2016 Sofia - calcolo progressivo "distinta" per flusso REVMIF
	    -- calcolo su progressi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
--        select prog.prog_value into flussoElabMifDistOilId
        select prog.prog_value into flussoElabMifDistOilRetId -- 27.05.2016 Sofia - JIRA-3619
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
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
      from ordinativi o
	  where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

--     execute  'ANALYZE mif_t_ordinativo_entrata_id;';

      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
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
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
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
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );
--	  execute  'ANALYZE mif_t_ordinativo_entrata_id;';

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_entrata_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
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
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
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
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
	   );
--      execute  'ANALYZE mif_t_ordinativo_entrata_id;';

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
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
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id, ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
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
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );
--      execute  'ANALYZE mif_t_ordinativo_entrata_id;';

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati )
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_entrata_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_entrata_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil ,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_notetes_id,mif_ord_dist_id,mif_ord_desc,
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
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_subord_id,elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.notetes_id mif_ord_notetes_id,ord.dist_id mif_ord_dist_id,
               ord.ord_desc mif_ord_desc,
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
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
		select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
               o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
               o.mif_ord_soggetto_id, o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_notetes_id,o.mif_ord_dist_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
	     or (mifOrdRitrasmElabId is not null and exists
            (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );
--      execute  'ANALYZE mif_t_ordinativo_entrata_id;';

      -- aggiornamento mif_t_ordinativo_entrata_id per id

	  -- 11.01.2016 Sofia non serve sulle entrate
	  /*strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per fase_operativa_code.';
      update mif_t_ordinativo_entrata_id m
      set mif_ord_bil_fase_ope=(select fase.fase_operativa_code from siac_r_bil_fase_operativa rFase, siac_d_fase_operativa fase
      							where rFase.bil_id=m.mif_ord_bil_id
                                and   rFase.data_cancellazione is null
                                and   rFase.validita_fine is null
                                and   fase.fase_operativa_id=rFase.fase_operativa_id
                                and   fase.data_cancellazione is null
                                and   fase.validita_fine is null);*/

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per soggetto_id.';
      -- soggetto_id
      update mif_t_ordinativo_entrata_id m
      set mif_ord_soggetto_id = (select s.soggetto_id from siac_r_ordinativo_soggetto s
                                 where s.ord_id=m.mif_ord_ord_id
                                   and s.data_cancellazione is null
                                   and s.validita_fine is null);
--      execute  'ANALYZE mif_t_ordinativo_entrata_id;';
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

--     execute  'ANALYZE mif_t_ordinativo_entrata_id;';

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

--     execute  'ANALYZE mif_t_ordinativo_entrata_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_entrata_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);
--     execute  'ANALYZE mif_t_ordinativo_entrata_id;';

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_entrata_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);
--     execute  'ANALYZE mif_t_ordinativo_entrata_id;';

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_ordinativo_atto_amm s
                                where s.ord_id = m.mif_ord_ord_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);
--    execute  'ANALYZE mif_t_ordinativo_entrata_id;';

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_entrata_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
--                                    where s.movgest_ts_id = m.mif_ord_movgest_id 16.02.2016 Sofia
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);
--    execute  'ANALYZE mif_t_ordinativo_entrata_id;';

	-- mif_ord_note_attr_id
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per mif_ord_note_attr_id.';
	update mif_t_ordinativo_entrata_id m
    set mif_ord_note_attr_id = attr.ord_attr_id
    from siac_r_ordinativo_attr attr
    where attr.ord_id=m.mif_ord_ord_id
    and   attr.attr_id=noteOrdAttrId
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;

	-- mif_ord_tipologia_id
    -- mif_ord_tipologia_code
    -- mif_ord_tipologia_desc 11.01.2016 Sofia
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_entrata_id] per mif_ord_tipologia_id mif_ord_tipologia_code mif_ord_tipologia_desc.';
	update mif_t_ordinativo_entrata_id m
    set (mif_ord_tipologia_id, mif_ord_tipologia_code,mif_ord_tipologia_desc) = (cp.classif_id,cp.classif_code,cp.classif_desc)
    from  siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id= m.mif_ord_elem_id
	and   cf.classif_id=classElem.classif_id
	and   cf.data_cancellazione is null
	and   cf.validita_fine is null
	and   cf.classif_tipo_id= categoriaTipoid -- categoria
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitEntTipoCategId -- famiglia
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
	and   cp.data_cancellazione is null
	and   cp.validita_fine is null
	and   cp.classif_tipo_id=tipologiaTipoid; --tipologia

    strMessaggio:='Verifica esistenza ordinativi di entrata da trasmettere.';
    codResult:=null;
--    execute  'ANALYZE mif_t_ordinativo_entrata_id;';
    select 1 into codResult
    from mif_t_ordinativo_entrata_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di entrata da trasmettere.';
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
                    codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    codiceEconPatTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    transazioneUeTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    siopeTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    ricorrenteTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
  					aslTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));

                  /*  raise notice 'codiceFinVTbr=%', codiceFinVTbr;
                    raise notice 'codiceEconPatTbr=%', codiceEconPatTbr;
                    raise notice 'transazioneUeTbr=%', transazioneUeTbr;
                    raise notice 'siopeTbr=%', siopeTbr;
                    raise notice 'ricorrenteTbr=%', ricorrenteTbr;
                    raise notice 'aslTbr=%', aslTbr;*/

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
						and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal));
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
			  		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
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
					 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

                       -- raise notice 'codiceUECodeTipo=% codiceUECodeTipoId=%', codiceUECodeTipo,codiceUECodeTipoId;
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
 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
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
 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

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
 			 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
                    end if;

                	isTransElemAttiva:=true;
            end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
   end if;


   -- 22.01.2016 Sofia ABI36
   -- <dati_a_disposizione_ente_versante>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_DISP_ABI36];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.Dati a disposizione ente versante ABI36.';
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


   -- <Numero_quota_reversale>
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

  -- <mandato_associato>
  -- <numero_mandato>
  mifCountRec:=FLUSSO_MIF_ELAB_NUM_MAND_ASSOC;
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
    	isGestioneMandAssQuoteOK:=true;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
  end if;


--  execute  'ANALYZE mif_t_ordinativo_entrata;';
--  execute  'ANALYZE mif_t_ordinativo_entrata_ricevute;';
--  execute  'ANALYZE mif_t_ordinativo_entrata_disp_ente;';


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
		isIndirizzoBenef:=true; -- 26.01.2016 SofiaJira

		-- 15.02.2016 Sofia ABI36
	    codiceFinVCodeTbr =null;
		contoEconCodeTbr :=null;
		codiceUeCodeTbr :=null;
	    siopeCodeTbr :=null;
		ricorrenteCodeTbr :=null;
	    aslCodeTbr :=null;
        -- lettura importo ordinativo
		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di entrata per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        										flussoElabMifTipoDec); -- 21.01.2016 Sofia ABI36

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


		-- <codice_funzione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--        raise notice 'messaggio=%',strMessaggio;
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
			-- mifFlussoOrdinativoRec.mif_ord_codice_funzione:=mifOrdinativoIdRec.mif_ord_codice_funzione;
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
         	if flussoElabMifTipoDec=false then -- 21.01.2016 Sofia ABI36
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


		-- <tipo_contabilita>
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
             mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifElabRec.flussoElabMifDef;
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
              -- 15.03.2016 Sofia  ABI36
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
                   end if;**/

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
/**22.04.2016 Sofia SIAC-3470
                   	select r.ord_classif_id into codResult
                    from siac_r_ordinativo_class r
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   r.classif_id=valFruttiferoId
                    and   r.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if codResult is not null then
                    	 flussoElabMifValore:=valFruttiferoStr;
                    else flussoElabMifValore:=valFruttiferoStrAltro;
                    end if;**/

					-- 22.04.2016 Sofia SIAC-3470
                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;
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

-- 15.03.2016 Sofia  ABI36
--               mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata:=flussoElabMifElabRec.flussoElabMifDef;
                 mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <numero_documento>
        mifCountRec:=mifCountRec+1;

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

            mifFlussoOrdinativoRec.mif_ord_destinazione:=substring (flussoElabMifValore from 1 for 7 );

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ABI_BT>
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
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=enteProprietarioRec.codice_fiscale;
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
--            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=flussoElabMifElabRec.flussoElabMifDef; 09.02.2016 Sofia SIAC-2998
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_ente_BT>
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

        -- <identificativo_flusso>
        -- <data_ora_creazione_flusso>
        -- <anno_flusso>
        mifCountRec:=mifCountRec+3;

        -- <codice_struttura>
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
         		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta collegata all''ordinativo.';

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


		-- <ente_localita>
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
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--        raise notice 'messaggio=%',strMessaggio;

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
--                raise notice 'messaggio=%',strMessaggio;

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


		-- <codice_cge>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codiceCge:=null;
        descCge:=null;
        mifCountRec:=mifCountRec+1;
        --flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_CODICE_CGE];
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       --||' mifCountRec='||FLUSSO_MIF_ELAB_CODICE_CGE
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--        raise notice '%',strMessaggio;
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true or isTransElemAttiva=true then
         if flussoElabMifElabRec.flussoElabMifElab=true or isTransElemAttiva=true then
         		if flussoElabMifElabRec.flussoElabMifParam is not null or isTransElemAttiva=true then

                	if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
			            --siopeCodeTipo=flussoElabMifElabRec.flussoElabMifParam;
                        siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
			---	    raise notice 'siopeCodeTipo=%',siopeCodeTipo;
					if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
			            --siopeCodeTipo=flussoElabMifElabRec.flussoElabMifParam;
                        siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                	if siopeCodeTipoId is null then
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
	 		 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));
                    end if;
---  				    raise notice 'siopeCodeTipoId=%',siopeCodeTipoId;
                  if siopeCodeTipoId is not null then
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
                    and class.data_cancellazione is null
         			and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		 			and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));

                    -- 16.02.2016 Sofia
                    if flussoElabMifValore is null then
	                    select class.classif_code, class.classif_desc
    		                   into flussoElabMifValore,flussoElabMifValoreDesc
	                    from siac_r_movgest_class  r,  siac_t_class class
    	                where r.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
        	            and   r.data_cancellazione is null
            	        and   r.validita_fine is null
                	    and class.classif_id=r.classif_id
                    	and class.classif_tipo_id=siopeCodeTipoId
	                    and class.classif_code!=siopeDef
    	                and class.data_cancellazione is null
        	 			and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		 				and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));
                   end if;

                  end if;
                end if;

                if flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
                    codiceCge:=flussoElabMifValore;
	                descCge:=flussoElabMifValoreDesc;

                    if isTransElemAttiva=true then
	                    siopeCodeTbr:=codiceCge;
                    end if;

                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

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

         		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=
                    substring(mifOrdinativoIdRec.mif_ord_tipologia_code from 1 for 5) ;
            	mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
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
                -- 11.01.2016 Sofia
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

         	if flussoElabMifElabRec.flussoElabMifParam is not null and
			   coalesce(isDefAnnoRedisuo,NVL_STR)=NVL_STR then -- Sofia 17.02.2016 ABI36
--               isDefAnnoRedisuo is null then Sofia 17.02.2016 ABI36
               isDefAnnoRedisuo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

          /*
            if isDefAnnoRedisuo is not null and isDefAnnoRedisuo='S' THEN
            	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
            else
            	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_anno_bil;
            end if; */

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
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
                 --                      raise notice 'messaggio=%',strMessaggio;

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
--                raise notice 'messaggio=%',strMessaggio;

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
    	        	--RAISE EXCEPTION ' Errore in lettura indirizzo soggetto [siac_t_indirizzo_soggetto].';
                    isIndirizzoBenef:=false; -- 26.01.2016 SofiaJira
	            end if;

				if isIndirizzoBenef=true then -- 26.01.2016 SofiaJira
                 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
	                from siac_d_via_tipo tipo
    	            where tipo.via_tipo_id=indirizzoRec.via_tipo_id
        	        and   tipo.data_cancellazione is null
         		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

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
	   if isIndirizzoBenef=true then -- 26.01.2016 SofiaJira
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
	   if isIndirizzoBenef=true then -- 26.01.2016 SofiaJira
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
	  if isIndirizzoBenef=true then -- 26.01.2016 SofiaJira
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

     -- <partita_iva_versante>
     mifCountRec:=mifCountRec+1;
        if soggettoRec.partita_iva is not null or  -- 01.02.2016 Sofia- aggiunto controllo su codice_fiscale come su spesa
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
          		if soggettoRec.partita_iva is not null then --- 01.02.2016 Sofia - adeguato a parte spese
                	 mifFlussoOrdinativoRec.mif_ord_partiva_versante:=soggettoRec.partita_iva;
                else
                	mifFlussoOrdinativoRec.mif_ord_partiva_versante:=trim ( both ' ' from soggettoRec.codice_fiscale);
                end if;

	            -- mifFlussoOrdinativoRec.mif_ord_partiva_versante:=soggettoRec.partita_iva;
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
  --             length(soggettoRec.codice_fiscale) in (16,11) then -- 01.02.2016 Sofia -- allineato a spese
  			   length(soggettoRec.codice_fiscale)=16 then
             	-- flussoElabMifValore:=soggettoRec.codice_fiscale;
				flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale); -- 01.02.2016 Sofia -- allineato a spese
--            elsif  flussoElabMifElabRec.flussoElabMifDef is not null then
            elsif  flussoElabMifElabRec.flussoElabMifDef is not null and
                   (soggettoRec.codice_fiscale is null or
                    (soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale) not in (11,16))) then  -- 01.02.2016 Sofia -- allineato a spese
	            flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
            end if;

            if flussoElabMifValore is not null then
            	--- 15.02.2016 Sofia ABI36
            	if length(flussoElabMifValore)=16 then
		            mifFlussoOrdinativoRec.mif_ord_codfisc_versante:=flussoElabMifValore;
                elsif length(flussoElabMifValore)=11 then
                	mifFlussoOrdinativoRec.mif_ord_partiva_versante:=flussoElabMifValore;
                end if;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
       end if;

  	   -- <esenzione>
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
          	if flussoElabMifElabRec.flussoElabMifDef is not null then
                -- ABI36 default settato a ESENTE BOLLO
            	mifFlussoOrdinativoRec.mif_ord_bollo_esenzione:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
          else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
       end if;

       -- <tipo_riscossione>
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
            -- 15.03.2016 Sofia ABI36 tipo incasso
            if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR then
              if  tipoIncassoCode is null then
            	tipoIncassoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore classicatore '||tipoIncassoCode||' per ordinativo [siac_r_ordinativo_class].';

              	select c.classif_desc into flussoElabMifValore
                from siac_r_ordinativo_class r, siac_t_class c
                where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=r.classif_id
                and   c.classif_tipo_id=tipoIncassoCodeId
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                and   c.data_cancellazione is null
                and   c.validita_fine is NULL
                order  by r.ord_classif_id limit 1;
              end if;
            end if;

            if flussoElabMifValore is null and
               coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
               flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
            end if;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos:=flussoElabMifValore;
            end if;

/*          15.03.2016 Sofia ABI36 tipo incasso
          	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_vers_tipo_riscos:=flussoElabMifElabRec.flussoElabMifDef;
            end if;*/
          else
          	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
       end if;

       -- <codice_riscossione>
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

                -- 15.03.2016 Sofia ABI36 (Alessandria)
                if coalesce(flussoElabMifElabRec.flussoElabMifParam,NVL_STR)!=NVL_STR and
                   mifFlussoOrdinativoRec.mif_ord_destinazione is not null then
                   if coalesce(flussoElabMifElabRec.flussoElabMifDef,NVL_STR)!=NVL_STR then
                	if fnc_mif_ordinativo_esenzione_bollo(mifFlussoOrdinativoRec.mif_ord_destinazione,
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
                	mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos:=flussoElabMifValore;
              end if;

/*          15.03.2016 Sofia ABI36 (ALessandria )
          	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_vers_cod_riscos:=flussoElabMifElabRec.flussoElabMifDef;
            end if;*/
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
  --   		mifFlussoOrdinativoRec.mif_ord_vers_causale:=substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370);
            -- 09.02.2016 Sofia JIRA SIAC-2998
            mifFlussoOrdinativoRec.mif_ord_vers_causale:=
	            replace(replace(substring(mifOrdinativoIdRec.mif_ord_desc from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

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
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura presenza allegati cartacei.';

                	select 1 into codResult
				    from siac_r_ordinativo_attr rattr
					where rattr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   rattr.attr_id=ordAllegatoCartAttrId
				    and   rattr.boolean='S'
					and   rattr.data_cancellazione is null
				    and   rattr.validita_fine is null;

				if codResult is not null then
	                mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifElabRec.flussoElabMifDef;
		        end if;
             end if;
		else
    		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
    end if;

    -- <informazioni_tesoriere>
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
--        	if mifOrdinativoIdRec.mif_ord_notetes_id is not null then
        	if mifOrdinativoIdRec.mif_ord_note_attr_id is not null then

            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura note al tesoriere.';

/*		        select note.notetes_desc into flussoElabMifValoreDesc
			    from siac_d_note_tesoriere note
			    where note.notetes_id=mifOrdinativoIdRec.mif_ord_notetes_id
			    and   note.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',note.validita_inizio)
			  	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(note.validita_fine,dataFineVal));*/

			    select attr.testo into flussoElabMifValoreDesc
                from siac_r_ordinativo_attr attr
                where attr.ord_attr_id=mifOrdinativoIdRec.mif_ord_note_attr_id
                and   attr.data_cancellazione is null
                and   attr.validita_fine is null;


                if flussoElabMifValoreDesc is not null then
                	if length(flussoElabMifValoreDesc)>150 then
				    	flussoElabMifValoreDesc:=substring(flussoElabMifValoreDesc from 1 for 150);
				    end if;
                end if;
            end if;

            if flussoElabMifValoreDesc is not null then
            	mifFlussoOrdinativoRec.mif_ord_info_tesoriere:=flussoElabMifValoreDesc;
            end if;
        else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		end if;
    end if;

	-- <flag_copertura>
    flussoElabMifElabRec:=null;
    flussoElabMifValore:=null;
    mifCountRec:=mifCountRec+1;
    codResult:=null;
--    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_FLAG_COPERTURA];
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                     --  ||' mifCountRec='||FLUSSO_MIF_ELAB_FLAG_COPERTURA
	                   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--                raise notice 'messaggio=%',strMessaggio;

     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
        	if 	flussoElabMifElabRec.flussoElabMifDef is not null then
			   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                     --  ||' mifCountRec='||FLUSSO_MIF_ELAB_FLAG_COPERTURA
	                   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura esistenza provvisori di cassa.';

               select distinct 1 into codResult
			   from siac_r_ordinativo_prov_cassa prov
			   where prov.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
			   and   prov.data_cancellazione is null
			   and   prov.validita_fine is null;

               if codResult is not null then
	               mifFlussoOrdinativoRec.mif_ord_flag_copertura:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

            end if;
       else
         	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
    end if;

    -- <ricevute>
    mifCountRec:=mifCountRec+2;



    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    -- <sostituzione_reversale>
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--                raise notice 'messaggio=%',strMessaggio;

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
         -- <numero_reversale_collegato>
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

     	-- <progressivo_reversale_collegato>
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

        -- <esercizio_reversale_collegato>
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

  mifCountRec:=mifCountRec+NUMERO_DATI_DISP_ENTE;	-- dati_a_disposizione_ente


  -- <InfSerRev_Accertamento>
  mifCountRec:=mifCountRec+1;
  --<InfoServizio_Reversale> -- 12.02.2016 Sofia -- non dovrebbe essere conteggiato ma ha il campo flusso_elab_mif_ordine_elab valorizzato
  mifCountRec:=mifCountRec+1;

  -- <InfSerMan_CodiceOperatore>

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
--                raise notice 'messaggio=%',strMessaggio;

  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  end if;
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if mifOrdinativoIdRec.mif_ord_login_modifica is not null then
        	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_modifica;
        elsif mifOrdinativoIdRec.mif_ord_login_creazione is not null then
        	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
        end if;

        if flussoElabMifValore is not null then
	     	mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
        end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <codice_cge>
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
--                raise notice 'messaggio=%',strMessaggio;

   if flussoElabMifElabRec.flussoElabMifId is null then
   	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
--   raise notice 'strMessaggio=%',strMessaggio;

   if flussoElabMifElabRec.flussoElabMifAttivo=true then --1
      if flussoElabMifElabRec.flussoElabMifElab=true then --2
   		if flussoElabMifElabRec.flussoElabMifParam is not null then ---3
  --          raise notice 'codiceCge=%',codiceCge;
        	if codiceCge is null then -- 4
            	if siopeCodeTipo is null then
                        siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

 				if siopeDef is null then
                        siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;

	           	if siopeClassTipoId is null then --5
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                     		  ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                     		  ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                    		  ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
		                      ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
		                      ||' mifCountRec='||mifCountRec
	                          ||' tipo flusso '||MANDMIF_TIPO||'.Lettura id class tipo='||flussoElabMifElabRec.flussoElabMifParam||'.';
                    	select class.classif_tipo_id into siopeClassTipoId
                        from siac_d_class_tipo class
                        where class.classif_tipo_code=siopeCodeTipo
                        and   class.ente_proprietario_id=enteProprietarioId
                        and   class.data_cancellazione is null
 				    	and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
	 		 		    and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));
    	        end if; --5

                /*if siopeClassTipoId is null then
                    	RAISE EXCEPTION ' Dato non reperito.';
                end if;*/
            end if; --4

            if siopeClassTipoId is not null then -- 4
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
                 and class.classif_code!=siopeDef
                 and class.data_cancellazione is null
         		 and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		 		 and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
                 and class.classif_tipo_id=siopeClassTipoId;

                 -- 16.02.2016 Sofia
                 if flussoElabMifValore is null then
	                    select class.classif_code, class.classif_desc
    		                   into flussoElabMifValore,flussoElabMifValoreDesc
	                    from siac_r_movgest_class  r,  siac_t_class class
    	                where r.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
        	            and   r.data_cancellazione is null
            	        and   r.validita_fine is null
                	    and class.classif_id=r.classif_id
                    	and class.classif_tipo_id=siopeCodeTipoId
	                    and class.classif_code!=siopeDef
    	                and class.data_cancellazione is null
        	 			and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		 				and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));
                end if;


                if flussoElabMifValore is not null then
                    codiceCge:=flussoElabMifValore;
                    descCge:=flussoElabMifValoreDesc;
                end if;
		   end if; --4
    --       raise notice 'codiceCge=%',codiceCge;
           if codiceCge is not null then
	           mifFlussoOrdinativoRec.mif_ord_siope_codice_cge:=codiceCge;
           end if;
          end if; -- 3
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if; -- 2
  end if; -- 1
--raise notice 'codiceCge=%',codiceCge;
--raise notice 'descCge=%',descCge;
  -- <descr_cge>
  mifCountRec:=mifCountRec+1;
  if codiceCge is not null and descCge is not null then
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
---      	mifFlussoOrdinativoRec.mif_ord_siope_descri_cge:=descCge; 25.02.2016 Sofia
      	mifFlussoOrdinativoRec.mif_ord_siope_descri_cge:=substring(descCge from 1 for 60);
      else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
      end if;
   end if;
  end if;


  -- <InfSerRev_DescrizioneEstesaCapitolo>
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
	     	mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap:=substring(bilElemRec.elem_desc from 1 for 150);
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- gestisti direttamente in insert
  -- <identificativo_flusso>
  -- <data_ora_creazione_flusso>
  -- <anno_flusso>

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
         mif_ord_codice_flusso_oil, -- 18.04.2016 Sofia
		 mif_ord_data_creazione_flusso,
		 mif_ord_anno_flusso,
         mif_ord_id_flusso_oil,
		 mif_ord_codice_struttura,
		 mif_ord_ente_localita,
		 mif_ord_ente_indirizzo,
		 mif_ord_progr_vers,
		 mif_ord_class_codice_cge,
		 mif_ord_class_importo,
		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
		 mif_ord_articolo,
		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil, -- 11.01.2016 Sofia
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
		 mif_ord_code_operatore,
		 mif_ord_siope_codice_cge,
		 mif_ord_siope_descri_cge,
		 mif_ord_descri_estesa_cap,
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
  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
                    '0' else mifFlussoOrdinativoRec.mif_ord_importo end), -- mif_ord_importo
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,  -- mif_ord_bci_tipo_contabil
  	     mifFlussoOrdinativoRec.mif_ord_bci_tipo_entrata,   -- mif_ord_bci_tipo_entrata
 		 --mifFlussoOrdinativoRec.mif_ord_bci_numero_doc,   -- mif_ord_bci_numero_doc
 	 	 mifFlussoOrdinativoRec.mif_ord_destinazione,       -- mif_ord_destinazione
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,      -- mif_ord_codice_abi_bt
 		mifFlussoOrdinativoRec.mif_ord_codice_ente,         -- mif_ord_codice_ente
		mifFlussoOrdinativoRec.mif_ord_desc_ente,           -- mif_ord_desc_ente
  		mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,      -- mif_ord_codice_ente_bt
 		mifFlussoOrdinativoRec.mif_ord_anno_esercizio,      -- mif_ord_anno_esercizio
--  		annoBilancio||flussoElabMifDistOilId::varchar, -- flussoElabMifDistOilId -- 18.04.2016 Sofia
  		annoBilancio||flussoElabMifDistOilRetId::varchar,  -- 27.05.2016 Sofia - JIRA-3619
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
 		mifFlussoOrdinativoRec.mif_ord_progr_vers,        -- mif_ord_progr_vers
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,  -- mif_ord_class_codice_cge
        mifFlussoOrdinativoRec.mif_ord_class_importo,     -- mif_ord_class_importo
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio, -- mif_ord_codifica_bilancio
        mifFlussoOrdinativoRec.mif_ord_capitolo, -- mif_ord_capitolo
  		mifFlussoOrdinativoRec.mif_ord_articolo,          -- mif_ord_articolo
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,     -- mif_ord_desc_codifica
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil,     -- mif_ord_desc_codifica_bil 11.01.2016 Sofia
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
        mifFlussoOrdinativoRec.mif_ord_code_operatore,
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
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
 	 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal));
            end if;

            if  capOrigAttrId is null then
            	RAISE EXCEPTION ' Errore in lettura dato.';
            end if;

            if    capOrigAttrId is not null then
		     select rattr.testo into flussoElabMifValore
             from siac_r_movgest_ts_attr rattr
--             where rattr.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_id  16.02.2016 SOfia
             where rattr.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
             and   rattr.attr_id=capOrigAttrId
             and   rattr.data_cancellazione is null
             and   rattr.validita_fine is null;

		    end if;

           	if flussoElabMifValore is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Inserimento mif_t_ordinativo_entrata_disp_ente.';

            	insert into mif_t_ordinativo_entrata_disp_ente
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

     -- <Stanziamento_Cassa>
     flussoElabMifElabRec:=null;
	 codResult:=null;
 	 mifCountRec:=mifCountRec+1;
     if mifOrdinativoIdRec.mif_ord_cast_cassa is not null and
        mifOrdinativoIdRec.mif_ord_cast_cassa!=0 then
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
         	    insert into mif_t_ordinativo_entrata_disp_ente
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
        		  trunc((mifOrdinativoIdRec.mif_ord_cast_cassa*100))::varchar,
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

     -- <Reversali_Emesse>
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
         	    insert into mif_t_ordinativo_entrata_disp_ente
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
    			  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
        		  trunc((mifOrdinativoIdRec.mif_ord_cast_emessi+
          			    (mifFlussoOrdinativoRec.mif_ord_importo::numeric/100))*100)::varchar,
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

     -- <Disponibilita>
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
         	    insert into mif_t_ordinativo_entrata_disp_ente
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
    			 -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
                  flussoElabMifElabRec.flusso_elab_mif_ordine,
				  flussoElabMifElabRec.flusso_elab_mif_code,
        		  trunc( mifOrdinativoIdRec.mif_ord_cast_cassa-(mifOrdinativoIdRec.mif_ord_cast_emessi+
          			     (mifFlussoOrdinativoRec.mif_ord_importo::numeric/100))*100)::varchar,
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

     -- <Numero_Capitolo> ( Capitolo_Peg per CMTO)
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
         	    insert into mif_t_ordinativo_entrata_disp_ente
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


     -- <Numero_Capitolo_Articolo>
     mifCountRec:=mifCountRec+1;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
        		insert into mif_t_ordinativo_entrata_disp_ente
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
                 -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

     -- <Vincoli_di_destinazione>
     -- <Vincolato>
     mifCountRec:=mifCountRec+2;

     -- <Atto_di_riscossione>
     mifCountRec:=mifCountRec+1;
     if mifOrdinativoIdRec.mif_ord_atto_amm_id is not null then
     	flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        codResult:=null;
        annoAttoAmm:=null;
        numeroAttoAmm:=null;
        tipoAttoAmm:=null;
        sacAttoAmm:=null;
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
            if classifCdrTipoId is null then
            	if classifCdrTipoCode is null then
                	classifCdrTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
            end if;
            if classifCdrTipoId is null and classifCdrTipoCode is not null then
	            select tipo.classif_tipo_id into strict classifCdrTipoId
    		    from siac_d_class_tipo tipo
		        where tipo.ente_proprietario_id=enteProprietarioId
        		and   tipo.classif_tipo_code=classifCdrTipoCode
		        and   tipo.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 				and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
            end if;

            if classifCdcTipoId is null then
            	if classifCdcTipoCode is null then
                	classifCdcTipoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
            end if;
            if classifCdcTipoId is null and classifCdcTipoCode is not null then
	            select tipo.classif_tipo_id into strict classifCdcTipoId
    		    from siac_d_class_tipo tipo
		        where tipo.ente_proprietario_id=enteProprietarioId
        		and   tipo.classif_tipo_code=classifCdcTipoCode
		        and   tipo.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 				and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
            end if;


            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura atto amministrativo di incasso.';

        	select a.attoamm_anno, a.attoamm_numero::varchar, tipo.attoamm_tipo_code
           	       into annoAttoAmm,numeroAttoAmm,  tipoAttoAmm
		    from siac_t_atto_amm a, siac_d_atto_amm_tipo tipo
		    where a.attoamm_id=mifOrdinativoIdRec.mif_ord_atto_amm_id
		    and   tipo.attoamm_tipo_id=a.attoamm_tipo_id
		    and   a.data_cancellazione is null
		    and   a.validita_fine is null
		    and   tipo.data_cancellazione is null
		    and   tipo.validita_fine is null;

            if numeroAttoAmm is null then
            	RAISE EXCEPTION ' Dato non reperito.';
            end if;

            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura eventuale sac collegata all'' atto amministrativo di incasso.';
            select c.classif_code into sacAttoAmm
            from siac_r_atto_amm_class class, siac_t_class  c
            where class.attoamm_id=mifOrdinativoIdRec.mif_ord_atto_amm_id
            and   c.classif_id=class.classif_id
            and   c.classif_tipo_id=classifCdrTipoId
            and   class.data_cancellazione is null
            and   class.validita_fine is null
            and   c.data_cancellazione is null
            and   c.validita_fine is null;

            if sacAttoAmm is null then
            	select c.classif_code into sacAttoAmm
	            from siac_r_atto_amm_class class, siac_t_class  c
    	        where class.attoamm_id=mifOrdinativoIdRec.mif_ord_atto_amm_id
        	    and   c.classif_id=class.classif_id
            	and   c.classif_tipo_id=classifCdcTipoId
	            and   class.data_cancellazione is null
    	        and   class.validita_fine is null
        	    and   c.data_cancellazione is null
            	and   c.validita_fine is null;
            end if;

            if sacAttoAmm is not null then
	            flussoElabMifValore:=tipoAttoAmm||' '||sacAttoAmm||' N. '||numeroAttoAmm||' DEL '||annoAttoAmm;
            else
            	flussoElabMifValore:=tipoAttoAmm||' N. '||numeroAttoAmm||' DEL '||annoAttoAmm;
            end if;

            if  flussoElabMifValore is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
        		insert into mif_t_ordinativo_entrata_disp_ente
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
                 -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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


     -- <Numero_mandato_vincolato>
     mifCountRec:=mifCountRec+1;


     -- <Data_nascita_versante>
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


                if datiNascitaRec is not null then
                 if datiNascitaRec.nascita_data is not null then
	     			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';


                    flussoElabMifValore:=
                        extract('year' from datiNascitaRec.nascita_data)||'-'||
    			        lpad(extract('month' from datiNascitaRec.nascita_data)::varchar,2,'0')||'-'||
			            lpad(extract('day' from datiNascitaRec.nascita_data)::varchar,2,'0');
					--raise notice 'Data nascita beneficiario %', flussoElabMifValore;
                    insert into mif_t_ordinativo_entrata_disp_ente
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
    		         -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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


      -- <Luogo_nascita_versante>
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

                if flussoElabMifValore is not null then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
                	 insert into mif_t_ordinativo_entrata_disp_ente
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
    		         -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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
           		and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
            	order by provRel.data_creazione;


                if flussoElabMifValore is not null then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
                	 insert into mif_t_ordinativo_entrata_disp_ente
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
    		         -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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


          /*      if noteOrdAttrId is null then
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

--                if noteOrdAttrId is not null then
                if mifOrdinativoIdRec.mif_ord_notetes_id is not null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura note.';


                	/*select attr.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr attr
                    where attr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   attr.attr_id=noteOrdAttrId
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;*/

                    select note.notetes_desc into flussoElabMifValore
				    from siac_d_note_tesoriere note
   					where note.notetes_id=mifOrdinativoIdRec.mif_ord_notetes_id
				    and   note.data_cancellazione is null
                    and   note.validita_fine is null;

                end if;

                if flussoElabMifValore is not null and
                   flussoElabMifValore!='' then
                	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
                	 insert into mif_t_ordinativo_entrata_disp_ente
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
    		         -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

   -- <mandati_associati>
   -- <mandato_associato>
   if isGestioneMandAssQuoteOK=true then
	  ordinativoAssocRec:=null;
	  mifCountRec:=FLUSSO_MIF_ELAB_NUM_MAND_ASSOC;
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura quote ordinativo di spesa associati.';

	  for quoteOrdinativoRec in
      (select *
	   from fnc_mif_ordinativo_associato(mifOrdinativoIdRec.mif_ord_ord_id,
										null,ordinativoSpesaTipoId, ordinativoTsDetTipoId,
                                        enteProprietarioId,dataElaborazione,dataFineVal)
      )
      loop
      	-- <numero_mandato>
		mifCountRec:=FLUSSO_MIF_ELAB_NUM_MAND_ASSOC;
	    flussoElabMifElabRec:=null;
        codResult:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];

        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	insert into mif_t_ordinativo_entrata_disp_ente
 		( mif_ord_id,
		  mif_ord_dispe_ordine,
		  mif_ord_dispe_nome,
		  mif_ord_dispe_valore,
          mif_ord_id_a,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
	     )
		 values
		 (mifOrdSpesaId,
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
	      quoteOrdinativoRec.numeroOrdAssociato,
          quoteOrdinativoRec.ordAssociatoId,
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;


         -- <progressivo_mandato>
		 mifCountRec:=mifCountRec+1;
         flussoElabMifElabRec:=null;
         codResult:=null;
  	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         if flussoElabMifElabRec.flussoElabMifAttivo=true and
            flussoElabMifElabRec.flussoElabMifElab=true and
            flussoElabMifElabRec.flussoElabMifDef is not null then

            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                        ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                        ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                        ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                        ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                        ||' mifCountRec='||mifCountRec
                        ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	   insert into mif_t_ordinativo_entrata_disp_ente
 		   ( mif_ord_id,
		     mif_ord_dispe_ordine,
  		     mif_ord_dispe_nome,
		     mif_ord_dispe_valore,
             mif_ord_id_a,
		     validita_inizio,
		     ente_proprietario_id,
		     login_operazione
	        )
		    values
		    (mifOrdSpesaId,
	         -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
             flussoElabMifElabRec.flusso_elab_mif_ordine,
		     flussoElabMifElabRec.flusso_elab_mif_code,
	         flussoElabMifElabRec.flussoElabMifDef,
             quoteOrdinativoRec.ordAssociatoId,
    	     now(),
		     enteProprietarioId,
		     loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
  		end if;

         -- <esercizio_mandato>
		 mifCountRec:=mifCountRec+1;
         flussoElabMifElabRec:=null;
         codResult:=null;
  	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         if flussoElabMifElabRec.flussoElabMifAttivo=true and
            flussoElabMifElabRec.flussoElabMifElab=true then

            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                        ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                        ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                        ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                        ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                        ||' mifCountRec='||mifCountRec
                        ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	   insert into mif_t_ordinativo_entrata_disp_ente
 		   ( mif_ord_id,
		     mif_ord_dispe_ordine,
  		     mif_ord_dispe_nome,
		     mif_ord_dispe_valore,
             mif_ord_id_a,
		     validita_inizio,
		     ente_proprietario_id,
		     login_operazione
	        )
		    values
		    (mifOrdSpesaId,
	         --flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
             flussoElabMifElabRec.flusso_elab_mif_ordine,
		     flussoElabMifElabRec.flusso_elab_mif_code,
	         quoteOrdinativoRec.annoOrdAssociato,
             quoteOrdinativoRec.ordAssociatoId,
    	     now(),
		     enteProprietarioId,
		     loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
  		end if;

        -- <importo_mandato>
  	    mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        codResult:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        if flussoElabMifElabRec.flussoElabMifAttivo=true and
            flussoElabMifElabRec.flussoElabMifElab=true then

            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                        ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                        ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                        ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                        ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                        ||' mifCountRec='||mifCountRec
                        ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	   insert into mif_t_ordinativo_entrata_disp_ente
 		   ( mif_ord_id,
		     mif_ord_dispe_ordine,
  		     mif_ord_dispe_nome,
		     mif_ord_dispe_valore,
             mif_ord_id_a,
		     validita_inizio,
		     ente_proprietario_id,
		     login_operazione
	        )
		    values
		    (mifOrdSpesaId,
	         -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
             flussoElabMifElabRec.flusso_elab_mif_ordine,
		     flussoElabMifElabRec.flusso_elab_mif_code,
	         quoteOrdinativoRec.importoOrdAssociato,
             quoteOrdinativoRec.ordAssociatoId,
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

     mifCountRec:=FLUSSO_MIF_ELAB_NUM_MAND_ASSOC+3;
     -- <Mandati_Stanziamento_Rev>
     -- <Stanziamento_Rev>
     mifCountRec:=mifCountRec+2;

     -- <Codice_Soggetto>
	 mifCountRec:=mifCountRec+1;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
 			 insert into mif_t_ordinativo_entrata_disp_ente
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
	    	  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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
			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

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
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
                and   rclass.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio)
			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal))
                order by rclass.elem_classif_id desc limit 1;
            end if;

            if flussoElabMifValore is not null then
	        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
 				 insert into mif_t_ordinativo_entrata_disp_ente
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
	    		  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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
      codResult:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
 				 insert into mif_t_ordinativo_entrata_disp_ente
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
	    		  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

  -- <Anagrafica_Versante>
  mifCountRec:=mifCountRec+1;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
 			 insert into mif_t_ordinativo_entrata_disp_ente
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
	    	  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
              flussoElabMifElabRec.flusso_elab_mif_ordine,
			  flussoElabMifElabRec.flusso_elab_mif_code,
        	  substring(soggettoRec.soggetto_desc from 1 for 140),
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

  -- <Importo_Reversale_Lettere>
  mifCountRec:=mifCountRec+1;

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
		if false then  -- 18.02.2016 Sofia
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	       -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

	    -- <Descrizione_quota_reversale>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        codResult:=null;
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
                        ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
          flussoElabMifElabRec.flusso_elab_mif_ordine,
		  flussoElabMifElabRec.flusso_elab_mif_code,
--	      quoteOrdinativoRec.descriQuota, 09.02.2016 Sofia JIRA SIAC-2998
          replace(replace(quoteOrdinativoRec.descriQuota , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR),
    	  now(),
		  enteProprietarioId,
		  loginOperazione)
		 returning mif_ord_dispe_id into codResult;

         if codResult is null then
	     	RAISE EXCEPTION ' Inserimento non effettuato.';
		 end if;
  		end if;

        -- <Data_scadenza_quota_reversale>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        codResult:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

        -- <Importo_quota_reversale>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        codResult:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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


        -- <Accertamento_quota_reversale>
		mifCountRec:=mifCountRec+1;
        codResult:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

        -- <Descrizione_accertamento_quota_reversale>
		mifCountRec:=mifCountRec+1;
        codResult:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

        -- <Determina_accertamento_quota_reversale>
		mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=null;
        codResult:=null;
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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
		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

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
		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(conto.validita_fine,dataFineVal))
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
	    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(evento.validita_fine,dataFineVal));

        --- 15.02.2016 Sofia ABI36
		if 	flussoElabMifValore is not null then
	        if isTransElemAttiva=true then
            	contoEconCodeTbr:=flussoElabMifValore;
            end if;
        end if;

        -- 15.02.2016 Sofia ABI36
        if 	flussoElabMifValore is  null then

         if codiceFinVTbr is null then
         	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         end if;

		 -- 15.02.2016 Sofia ABI36
         if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
	        -- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code_tipo_id '||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
			and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal));
         end if;

         -- 15.02.2016 Sofia ABI36
       	 -- codiceFinVCodeTbr
  		 if codiceFinVTipoTbrId is not null then
      		 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class] .';
	  		 select class.classif_code into codiceFinVCodeTbr
   	  		 from siac_r_ordinativo_class r, siac_t_class class
     		 where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
     		 and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null
		     and   class.validita_fine is null;

			 if codiceFinVCodeTbr is null then
	             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             	select class.classif_code into codiceFinVCodeTbr
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
    	        and   rclass.data_cancellazione is null
        	    and   rclass.validita_fine is null
            	and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=codiceFinVTipoTbrId
    	        and   class.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
	            order by rclass.movgest_classif_id
    	        limit 1;
             end if;

              if codiceFinVCodeTbr is not null then
             	flussoElabMifValore:=codiceFinVCodeTbr;
             end if;
		 end if;
        end if;

	    if 	flussoElabMifValore is not null then

        	/*if isTransElemAttiva=true then spostato sopra
            	contoEconCodeTbr:=flussoElabMifValore;
            end if;*/
		    if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
 			 insert into mif_t_ordinativo_entrata_disp_ente
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
	    	  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
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
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
            order by rclass.ord_classif_id
            limit 1;

            -- 17.02.2016 Sofia
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
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
			 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
	            order by rclass.movgest_classif_id
	            limit 1;
            end if;
			--raise notice 'codiceUECodeTipo % codiceUECodeTipoId % flussoElabMifValore=%',
            --  codiceUECodeTipo, codiceUECodeTipoId, flussoElabMifValore;
        end if;
        if flussoElabMifValore is not null then
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
                       ||' tipo flusso '||MANDMIF_TIPO||'.Inserimento mif_t_ordinativo_entrata_disp_ente.';
 			 insert into mif_t_ordinativo_entrata_disp_ente
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
	    	  -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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

-- <Codice_Entrata>
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
   -- pdcFin-V
   -- codice_economico
   -- codice_ue
   -- siope
   -- ricorrente
   -- asl

   -- codiceFinVCodeTbr
   -- 15.02.2016 Sofia ABI36
   if codiceFinVTipoTbrId is not null and codiceFinVCodeTbr is null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| codiceFinVTbr||' [siac_r_ordinativo_class].';
	   select class.classif_code into codiceFinVCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=codiceFinVTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null
       and   class.validita_fine is null;

       if codiceFinVCodeTbr is null then
       			strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| codiceFinVTbr||' [siac_r_movgest_class].';

      		    select class.classif_code into codiceFinVCodeTbr
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
    	        and   rclass.data_cancellazione is null
        	    and   rclass.validita_fine is null
            	and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=codiceFinVTipoTbrId
    	        and   class.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
	            order by rclass.movgest_classif_id
    	        limit 1;
       end if;
   end if;

   -- contoEconCodeTbr
   -- codiceUeCodeTbr
   -- siopeCodeTbr


   -- ricorrenteCodeTbr
   if ricorrenteTipoTbrId is not null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| ricorrenteTbr||' [siac_r_ordinativo_class].';
	   select class.classif_code into ricorrenteCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=ricorrenteTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null
       and   class.validita_fine is null;
       -- 17.02.2016 Sofia
       if ricorrenteCodeTbr is null then
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| ricorrenteTbr||' [siac_r_movgest_class].';
		select class.classif_code into ricorrenteCodeTbr
	    from siac_r_movgest_class rclass, siac_t_class class
	    where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	    and   rclass.data_cancellazione is null
	    and   rclass.validita_fine is null
	    and   class.classif_id=rclass.classif_id
	    and   class.classif_tipo_id=ricorrenteTipoTbrId
	    and   class.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
        order by rclass.movgest_classif_id
	    limit 1;
       end if;
   end if;
   -- aslCodeTbr
   if aslTipoTbrId is not null then
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| aslTbr||' [siac_r_ordinativo_class].';
	   select class.classif_code into aslCodeTbr
   	   from siac_r_ordinativo_class r, siac_t_class class
       where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
       and   class.classif_id=r.classif_id
       and   class.classif_tipo_id=aslTipoTbrId
       and   r.data_cancellazione is null
       and   r.validita_fine is NULL
       and   class.data_cancellazione is null
       and   class.validita_fine is null;

       -- 17.02.2016 Sofia
       if aslCodeTbr is null then
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare valore '|| aslTbr||' [siac_r_movgest_class].';
       	select class.classif_code into aslCodeTbr
	    from siac_r_movgest_class rclass, siac_t_class class
	    where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
	    and   rclass.data_cancellazione is null
	    and   rclass.validita_fine is null
	    and   class.classif_id=rclass.classif_id
	    and   class.classif_tipo_id=aslTipoTbrId
	    and   class.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
        order by rclass.movgest_classif_id
	    limit 1;
       end if;
   end if;


   -- codiceFinVCodeTbr
   -- contoEconCodeTbr
   -- codiceUeCodeTbr
   -- siopeCodeTbr
   -- ricorrenteCodeTbr
   -- aslCodeTbr


  /*
   raise notice 'codiceFinVCodeTbr=%',codiceFinVCodeTbr;
   raise notice 'contoEconCodeTbr=%',contoEconCodeTbr;
   raise notice 'codiceUeCodeTbr=%',codiceUeCodeTbr;
   raise notice 'siopeCodeTbr=%',siopeCodeTbr;
   raise notice 'ricorrenteCodeTbr=%',ricorrenteCodeTbr;
   raise notice 'aslCodeTbr=%',aslCodeTbr;*/

   if codiceFinVCodeTbr is not null and  codiceFinVCodeTbr!='' then
	   	flussoElabMifValore:=codiceFinVCodeTbr;
   end if;

   if contoEconCodeTbr is not null and contoEconCodeTbr!='' then
/*	   if flussoElabMifValore is not null then
   		flussoElabMifValore:=flussoElabMifValore||'-'||contoEconCodeTbr;
       else
        flussoElabMifValore:=contoEconCodeTbr;
       end if;*/
       flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                                   then flussoElabMifValore||'-'||contoEconCodeTbr
                              	   else contoEconCodeTbr end);
   end if;

   if codiceUeCodeTbr is not null and codiceUeCodeTbr!='' then
   	/*if flussoElabMifValore is not null then
	   	flussoElabMifValore:=flussoElabMifValore||'-'||codiceUeCodeTbr;
    else
	    flussoElabMifValore:=codiceUeCodeTbr;
    end if;*/
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||codiceUeCodeTbr
                               else codiceUeCodeTbr end);
   end if;

   if siopeCodeTbr is not null and siopeCodeTbr!='' then
    /*if flussoElabMifValore is not null then
	   	flussoElabMifValore:=flussoElabMifValore||'-'||siopeCodeTbr;
    else
	    flussoElabMifValore:=flussoElabMifValore||siopeCodeTbr;
    end if;*/
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||siopeCodeTbr
                           	   else siopeCodeTbr end);

   end if;

   if ricorrenteCodeTbr is not null and ricorrenteCodeTbr!='' then
    /*if flussoElabMifValore is not null then
	   	flussoElabMifValore:=flussoElabMifValore||'-'||ricorrenteCodeTbr;
    else
	    flussoElabMifValore:=flussoElabMifValore||ricorrenteCodeTbr;
    end if;*/
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||ricorrenteCodeTbr
                           	   else ricorrenteCodeTbr end);

   end if;

   if aslCodeTbr is not null and aslCodeTbr!='' then
   	/*if flussoElabMifValore is not null then
	   	flussoElabMifValore:=flussoElabMifValore||'-'||aslCodeTbr;
    else
	    flussoElabMifValore:=flussoElabMifValore||aslCodeTbr;
    end if;*/
    flussoElabMifValore:=(case when flussoElabMifValore is not null and flussoElabMifValore!=''
                               then flussoElabMifValore||'-'||aslCodeTbr
                           	   else aslCodeTbr end);

   end if;

 --  raise notice 'TBR=%', flussoElabMifValore;
   if flussoElabMifValore is not null then
   	 	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Transazione elementare.Inserimento mif_t_ordinativo_entrata_disp_ente.';
    	 insert into mif_t_ordinativo_entrata_disp_ente
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
	      -- flussoElabMifElabRec.flusso_elab_mif_ordine_elab,
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


 -- 22.01.2016 Sofia ABI36
 -- <dati_a_disposizione_ente_versante>
 if datiDispEnteBenef=true then
	  mifFlussoOrdDispeBenefRec:=null;
	  mifCountRec:=FLUSSO_MIF_ELAB_DISP_ABI36;


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
      --  raise notice 'strMessaggio %',strMessaggio;
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
		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

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
		  and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(conto.validita_fine,dataFineVal))
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
	      and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(evento.validita_fine,dataFineVal));

         if flussoElabMifValore is not null then -- 15.02.2016 Sofia ABI36
	        mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico:=flussoElabMifValore;
	     end if;

         -- 15.02.2016 Sofia ABI36
         if flussoElabMifValore is null then
          --raise notice 'LEGGO PDC_V';
		  if codiceFinVTbr is null then
         	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
          end if;

         -- raise notice 'codiceFinVTbr %',codiceFinVTbr;


          if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
	        -- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code_tipo_id '||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
			and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(validita_fine,dataFineVal));
         end if;
          --raise notice 'codiceFinVTipoTbrId %',codiceFinVTipoTbrId;

         -- 15.02.2016 Sofia ABI36
       	 -- codiceFinVCodeTbr
  		 if codiceFinVTipoTbrId is not null then
      		 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_ordinativo_class].';
	  		 select class.classif_code into codiceFinVCodeTbr
   	  		 from siac_r_ordinativo_class r, siac_t_class class
     		 where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
     		 and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null
		     and   class.validita_fine is null;
         -- raise notice 'codiceFinVCodeTbr %',codiceFinVCodeTbr;

			 if codiceFinVCodeTbr is null then
	           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountTmpRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura piano_conti_fin_V_code '||codiceFinVTbr||' [siac_r_movgest_class].';

             	select class.classif_code into codiceFinVCodeTbr
	    	    from siac_r_movgest_class rclass, siac_t_class class
	            where rclass.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_ts_id
    	        and   rclass.data_cancellazione is null
        	    and   rclass.validita_fine is null
            	and   class.classif_id=rclass.classif_id
	            and   class.classif_tipo_id=codiceFinVTipoTbrId
    	        and   class.data_cancellazione is null
			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
	            order by rclass.movgest_classif_id
    	        limit 1;
             end if;

             if codiceFinVCodeTbr is not null then
--             	mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico:=codiceFinVCodeTbr;
-- 17.02.2016
               	mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico:=
	  	              replace(substring(codiceFinVCodeTbr from 2 for length(codiceFinVCodeTbr)-1),'.','');
             end if;
		 end if;
        end if;

       end if;	 -- param
      else
   	 	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
      end if; -- elab
   end if; -- attivo

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
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
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
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
            order by rclass.ord_classif_id
            limit 1;

            -- 17.02.2016 Sofia
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
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	 and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
             order by rclass.movgest_classif_id
             limit 1;
	        end if;

        end if;

        if flussoElabMifValore is not null then
			mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_ue:=flussoElabMifValore;
        end if;
      end if;
     else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   	end if;
   end if;


   -- <codice_entrata>
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
     	if codiceEntrataCodeTipo is null then
			codiceEntrataCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
        end if;

--		raise notice 'codiceEntrataCodeTipo=%',codiceEntrataCodeTipo;
        if codiceEntrataCodeTipo is not null and codiceEntrataCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	select tipo.classif_tipo_id into codiceEntrataCodeTipoId
            from  siac_d_class_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.classif_tipo_code=codiceEntrataCodeTipo
            and   tipo.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
---            		raise notice 'codiceEntrataCodeTipoId=%',codiceEntrataCodeTipoId;
        end if;

        if codiceEntrataCodeTipoId is not null then
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
            and   class.classif_tipo_id=codiceEntrataCodeTipoId
            and   class.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
            order by rclass.ord_classif_id
            limit 1;
            -- 17.02.2016 Sofia
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
             and   class.classif_tipo_id=codiceEntrataCodeTipoId
             and   class.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	 and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
             order by rclass.movgest_classif_id
             limit 1;
	        end if;


--					raise notice 'codiceEntrataCode=%',flussoElabMifValore;
        end if;
        if flussoElabMifValore is not null then
			mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_entrata:=flussoElabMifValore;
        end if;
      end if;
     else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
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
                       ||' in mif_t_ordinativo_entrata_disp_ente_vers.';

   insert into mif_t_ordinativo_entrata_disp_ente_vers
   (mif_ord_id,mif_ord_ord_id,
    mif_ord_dispe_codice_economico,mif_ord_dispe_codice_economico_imp,
    mif_ord_dispe_codice_ue,
    mif_ord_dispe_codice_entrata,
    validita_inizio, ente_proprietario_id,login_operazione )
   values
   (mifOrdSpesaId,mifOrdinativoIdRec.mif_ord_ord_id,
    mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico,mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_economico_imp,
    mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_ue,
    mifFlussoOrdDispeBenefRec.mif_ord_dispe_codice_entrata,
    now(), enteProprietarioId,loginOperazione
    )
    returning mif_ord_dispe_vers_id into codResult;

    if codResult is null then
   	 raise exception ' Inserimento non effettuato.';
    end if;

  end if;



 -- <ricevute>
 -- <ricevuta>
 -- <numero_ricevuta>
 -- <importo_ricevuta>
 if  isRicevutaAttivo=true then
    ricevutaRec:=null;
--    execute  'ANALYZE mif_t_ordinativo_entrata_ricevute;';
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  ricevute'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
								      flussoElabMifTipoDec, -- 21.01.2016 Sofia ABI 36
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


   numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;

   end loop;

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
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId   -- 27.05.2016 Sofia - JIRA-3619
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   -- 18.04.2016 Sofia - aggiunto flusso_elab_mif_codice_flusso_oil
   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';
   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
--   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_entrata')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di entrata.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;
    -- 27.05.2016 Sofia - JIRA-3619
    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ||' '||mifCountRec||'.';
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
        raise notice '% % ERRORE : % %',coalesce(strMessaggioFinale,''),coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
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
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
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
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        messaggioRisultato:=coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||' '||mifCountRec||'.' ;
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