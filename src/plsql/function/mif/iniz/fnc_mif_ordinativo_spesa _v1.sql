/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out flussoElabMifId integer,
  out numeroOrdinativiTrasm integer,
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
 mifFlussoElabTypeRec record;
 mifFlussoOrdinativoRec  mif_t_ordinativo_spesa%rowtype;
-- ordinativoRec record;
 flussoElabMifElabRec record;
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
 isRicevutaAttivo boolean:=false;
 programmaCodeTipo varchar(50):=null;
 programmaCodeTipoId integer :=null;
 famMissProgrCode VARCHAR(50):=null;
 famMissProgrCodeId integer:=null;
 programmaId integer :=null;
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


 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;

 flussoElabMifOilId integer :=null;
 mifOrdSpesaId integer:=null;

 NVL_STR               CONSTANT VARCHAR:='';
 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;

 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TIPO_IMPORTO_A CONSTANT  varchar :='A';

 ORD_RELAZ_SEDE_SEC CONSTANT  varchar :='SEDE_SECONDARIA';
 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 CAP_ORIGINE_ATTR CONSTANT  varchar :='numeroCapitoloOrigine';
 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';

 FUNZIONE_CODE_I CONSTANT  varchar :='I';
 FUNZIONE_CODE_S CONSTANT  varchar :='S';
 FUNZIONE_CODE_N CONSTANT  varchar :='N';
 FUNZIONE_CODE_A CONSTANT  varchar :='A';
 FUNZIONE_CODE_VB CONSTANT  varchar :='VB';

 NUM_SETTE CONSTANT integer:=7;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF';


 SEPARATORE     CONSTANT  varchar :='|';
BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;

	strMessaggioFinale:='Invio ordinativi di spesa al MIF.';

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato.';

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
    execute  'ANALYZE mif_t_flusso_elaborato;';
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
    execute  'ANALYZE mif_t_ordinativo_spesa_id;';
    select 1 into codResult
    from mif_t_ordinativo_spesa_id where ente_proprietario_id=enteProprietarioId;

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



		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TIPO_IMPORTO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TIPO_IMPORTO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));


        -- ordSedeSecRelazTipoId
        strMessaggio:='Lettura relazione sede secondaria  Code Id '||ORD_RELAZ_SEDE_SEC||'.';
        select ord_tipo.relaz_tipo_id into strict ordSedeSecRelazTipoId
        from siac_d_relaz_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.relaz_tipo_code=ORD_RELAZ_SEDE_SEC
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
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;
        -- mifFlussoElabTypeRec
        strMessaggio:='Lettura flusso MIF type per tipo '||MANDMIF_TIPO||'.';
		select * into strict  mifFlussoElabTypeRec
   		from mif_d_flusso_elaborato_type t
   	    where t.ente_proprietario_id=enteProprietarioId
   		  and t.flusso_elab_mif_tipo=flussoElabMifTipoId;

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
    ( select ord.ord_id, FUNZIONE_CODE_I, bil.bil_id,per.periodo_id,per.anno::integer,
             ord.ord_anno,ord.ord_numero,
             extract('year' from ord.ord_emissione_data)||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0'),0,
             0,0,0,elem.elem_id,0,0,0,0,ord.contotes_id,ord.dist_id,ord.codbollo_id,ord.comm_tipo_id,
             ord.notetes_id, ord.ord_desc,
             ord.ord_cast_cassa,ord.ord_cast_competenza,ord.ord_cast_emessi,
             ord.login_creazione,ord.login_modifica,
             enteProprietarioId,loginOperazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.data_cancellazione is null
	   	 and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
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
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId));

     execute  'ANALYZE mif_t_ordinativo_spesa_id;';

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
	  (select ord.ord_id, FUNZIONE_CODE_S, bil.bil_id,per.periodo_id,per.anno::integer,
              ord.ord_anno,ord.ord_numero,
             extract('year' from ord.ord_emissione_data)||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0'),0,
              0,0,0,elem.elem_id,
              0,0,0,0,ord.contotes_id,ord.dist_id,ord.codbollo_id,ord.comm_tipo_id,
              ord.notetes_id,ord.ord_desc,
              ord.ord_cast_cassa,ord.ord_cast_competenza,ord.ord_cast_emessi,
              ord.login_creazione, ord.login_modifica,
              enteProprietarioId,loginOperazione
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
 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
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
      );
	  execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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
	  (select ord.ord_id, FUNZIONE_CODE_N, bil.bil_id,per.periodo_id,per.anno::integer,
      		  ord.ord_anno,ord.ord_numero,
             extract('year' from ord.ord_emissione_data)||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0'),0,
              0,0,0,elem.elem_id,0,0,0,0,ord.contotes_id,ord.dist_id,ord.codbollo_id,ord.comm_tipo_id,
              ord.notetes_id,ord.ord_desc,
              ord.ord_cast_cassa,ord.ord_cast_competenza,ord.ord_cast_emessi,
              ord.login_creazione,ord.login_modifica,
              enteProprietarioId,loginOperazione
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
 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
	   );
      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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
      (select ord.ord_id, FUNZIONE_CODE_A, bil.bil_id,per.periodo_id,per.anno::integer,
              ord.ord_anno,ord.ord_numero,
             extract('year' from ord.ord_emissione_data)||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0'),0,
              0,0,0,elem.elem_id,0,0,0,0,ord.contotes_id,ord.dist_id,ord.codbollo_id,ord.comm_tipo_id,
              ord.notetes_id,ord.ord_desc,
              ord.ord_cast_cassa,ord.ord_cast_competenza,ord.ord_cast_emessi,
              ord.login_creazione,ord.login_modifica,
              enteProprietarioId,loginOperazione
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
 		 and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal))
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       );
      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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
      (select ord.ord_id, FUNZIONE_CODE_VB, bil.bil_id,per.periodo_id,per.anno::integer,
              ord.ord_anno,ord.ord_numero,
             extract('year' from ord.ord_emissione_data)||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0'),0,
              0,0,0,elem.elem_id,0,0,0,0,ord.contotes_id,ord.dist_id,ord.codbollo_id,ord.comm_tipo_id,
              ord.notetes_id,ord.ord_desc,
              ord.ord_cast_cassa,ord.ord_cast_competenza,ord.ord_cast_emessi,
              ord.login_creazione,ord.login_modifica,
              enteProprietarioId,loginOperazione
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
                            and  ord_stato.data_cancellazione is null
        					and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
 		 					and  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_stato.validita_fine,dataFineVal)))
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       );
      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      -- aggiornamento mif_t_ordinativo_spesa_id per id

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per soggetto_id.';
      -- soggetto_id
      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id = (select s.soggetto_id from siac_r_ordinativo_soggetto s
                                 where s.ord_id=m.mif_ord_ord_id
                                   and s.data_cancellazione is null
                                   and s.validita_fine is null);
      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id.';

      -- modpag_id
      update mif_t_ordinativo_spesa_id m
      set mif_ord_modpag_id = (select  s.modpag_id from siac_r_ordinativo_modpag s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null);
      execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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

     execute  'ANALYZE mif_t_ordinativo_spesa_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per liq_id.';

	 -- liq_id
	 update mif_t_ordinativo_spesa_id m
	 set mif_ord_liq_id = (select s.liq_id from siac_r_liquidazione_ord s
                            where s.sord_id = m.mif_ord_subord_id
                              and s.data_cancellazione is null
                              and s.validita_fine is null);
     execute  'ANALYZE mif_t_ordinativo_spesa_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_ts_id = (select s.movgest_ts_id from siac_r_liquidazione_movgest s
                                   where s.liq_id = m.mif_ord_liq_id
                                     and s.data_cancellazione is null
                                     and s.validita_fine is null);
     execute  'ANALYZE mif_t_ordinativo_spesa_id;';
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);
     execute  'ANALYZE mif_t_ordinativo_spesa_id;';

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_spesa_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);
     execute  'ANALYZE mif_t_ordinativo_spesa_id;';

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_liquidazione_atto_amm s
                                where s.liq_id = m.mif_ord_liq_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);
    execute  'ANALYZE mif_t_ordinativo_spesa_id;';

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);
    execute  'ANALYZE mif_t_ordinativo_spesa_id;';

    strMessaggio:='Verifica esistenza ordinativi di spesa da trasmettere.';
    codResult:=null;
    execute  'ANALYZE mif_t_ordinativo_spesa_id;';
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
    strMessaggio:='Lettura dati configurazione per campo '||mifFlussoElabTypeRec.tipo_ritenuta
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
    select * into flussoElabMifElabRec
    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.tipo_ritenuta ,enteProprietarioId);
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
	                tipoRitenuta:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));

                    if tipoRelazRitOrd is null or tipoRelazSprOrd is null or tipoRelazSubOrd is null or
                       tipoRitenuta is null or tipoOnereInps is null or tipoOnereIrpef is null then
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
     strMessaggio:='Lettura dati configurazione per campo '||mifFlussoElabTypeRec.importo_ritenuta
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
   	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo_ritenuta ,enteProprietarioId);
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
	    strMessaggio:='Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_reversale
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     select * into flussoElabMifElabRec
   		 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_reversale ,enteProprietarioId);
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
	    strMessaggio:='Lettura dati configurazione per campo '||mifFlussoElabTypeRec.progressivo_reversale
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     select * into flussoElabMifElabRec
   		 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.progressivo_reversale ,enteProprietarioId);
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
 		   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

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
 		   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

           if tipoOnereInpsId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;
     end if;
   end if;


   -- <ricevute>
   -- <ricevuta>
   -- <numero_ricevuta>
   -- <importo_ricevuta>
   flussoElabMifElabRec:=null;
   strMessaggio:='Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_ricevuta
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
   select * into flussoElabMifElabRec
   from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_ricevuta ,enteProprietarioId);
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
   	strMessaggio:='Lettura dati configurazione per campo '||mifFlussoElabTypeRec.importo_ricevuta
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
  	select * into flussoElabMifElabRec
   	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo_ricevuta ,enteProprietarioId);
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

   execute  'ANALYZE mif_t_ordinativo_spesa;';
   execute  'ANALYZE mif_t_ordinativo_spesa_ritenute;';
   execute  'ANALYZE mif_t_ordinativo_spesa_ricevute;';

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


        -- lettura importo ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId);

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
 		  and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
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


        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_funzione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		-- <codice_funzione>
        flussoElabMifElabRec:=null;
        select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_funzione ,enteProprietarioId);

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_codice_funzione:=mifOrdinativoIdRec.mif_ord_codice_funzione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_mandato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        -- <numero_mandato>
        flussoElabMifElabRec:=null;
        select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_mandato ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.data_mandato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        -- <data_mandato>
        flussoElabMifElabRec:=null;
        select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.data_mandato ,enteProprietarioId);
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


        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.importo_mandato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

		-- <importo_mandato>
        flussoElabMifElabRec:=null;
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo_mandato ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:=0;
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


		-- <tipo_contabilita_ente_pagante>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.tipo_contabilita_ente_pagante
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.tipo_contabilita_ente_pagante ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.destinazione_ente_pagante
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.destinazione_ente_pagante ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifDef is not null then
             mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_tesoreria>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.conto_tesoreria
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        flussoElabMifValore:=null;
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.conto_tesoreria ,enteProprietarioId);
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
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.conto_tesoreria
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';


            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

            mifFlussoOrdinativoRec.mif_ord_bci_conto_tes:=flussoElabMifValore;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <estremi_provvedimento_autorizzativo>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.estremi_provvedimento_autorizzativo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        flussoElabMifValore:=null;
        attoAmmRec:=null;
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.estremi_provvedimento_autorizzativo ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_ufficio_responsabile
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_ufficio_responsabile ,enteProprietarioId);
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


        -- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_ABI_BT
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_ABI_BT ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_ente
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_ente ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.descrizione_ente
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.descrizione_ente ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_ente_BT
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_ente_BT ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.esercizio
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.esercizio ,enteProprietarioId);
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


        -- <codice_struttura>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_struttura
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_struttura ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.ente_localita
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.ente_localita ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.ente_indirizzo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.ente_indirizzo ,enteProprietarioId);
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

		-- <siope_codice_cge>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codiceCge:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.siope_codice_cge
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.siope_codice_cge ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	select class.classif_code, class.classif_desc
                           into flussoElabMifValore,flussoElabMifValoreDesc
                    from siac_r_ordinativo_class cord, siac_t_class class, siac_d_class_tipo tipo
                    where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and cord.data_cancellazione is null
                    and cord.validita_fine is null
                    and class.classif_id=cord.classif_id
                    and class.data_cancellazione is null
         			and date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		 			and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
                    and tipo.classif_tipo_id=class.classif_tipo_id
                    and tipo.classif_tipo_code=flussoElabMifElabRec.flussoElabMifParam
--                    and tipo.ente_proprietario_id=enteProprietarioId
                    and tipo.data_cancellazione is null
 				    and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		    and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
                end if;

                if flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_siope_codice_cge:=flussoElabMifValore;
                    codiceCge:=flussoElabMifValore;
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
		-- <siope_descr_cge>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.siope_descr_cge
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.siope_descr_cge ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifValoreDesc is not null then
                	mifFlussoOrdinativoRec.mif_ord_siope_descri_cge:=flussoElabMifValoreDesc;
                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_raggruppamento>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_raggruppamento
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_raggruppamento ,enteProprietarioId);
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
                if   flussoElabMifValore is not null then
                	mifFlussoOrdinativoRec.mif_ord_codice_raggrup:=flussoElabMifValore;
                end if;
               end if;
          	end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <progressivo_beneficiario>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.progressivo_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.progressivo_beneficiario ,enteProprietarioId);
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

		-- <numero_conto_banca_italia_ente_ricevente>
        flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        codResult:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_conto_banca_italia_ente_ricevente
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_conto_banca_italia_ente_ricevente ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifElabRec.flussoElabMifParam is not null then
                    if tipoMDPCbi is null then
                    	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCbi is not null then
                    	/*select 1 into codResult
                        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
                        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
                        and   tipo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal))
                        and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
                        and   gruppo.accredito_gruppo_code=tipoMDPCbi
                        and   gruppo.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',gruppo.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(gruppo.validita_fine,dataFineVal));*/

                    	if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
                        	 mifFlussoOrdinativoRec.mif_ord_bci_conto:=MDPRec.contocorrente;
                        end if;
                    end if;

                end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        if codiceCge is not null then
		 -- <class_codice_cge>
         flussoElabMifElabRec:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.class_codice_cge
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.class_codice_cge ,enteProprietarioId);
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.importo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo ,enteProprietarioId);
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
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codifica_bilancio
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codifica_bilancio ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <numero_articolo>
       flussoElabMifElabRec:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_articolo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_articolo ,enteProprietarioId);
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
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.descrizione_codifica
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.descrizione_codifica ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

       -- <gestione>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.gestione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.gestione ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
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
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.anno_residuo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.anno_residuo ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


       -- <importo_bilancio>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.importo_bilancio
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo_bilancio ,enteProprietarioId);
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

        -- <previsione>
       flussoElabMifElabRec:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.previsione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.previsione ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_prev:=trunc((mifOrdinativoIdRec.mif_ord_cast_cassa*100))::varchar;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	   -- <mandati_previsione>
       flussoElabMifElabRec:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.mandati_previsione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.mandati_previsione ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_mandati_prev:=
            trunc((mifOrdinativoIdRec.mif_ord_cast_emessi+
             (mifFlussoOrdinativoRec.mif_ord_importo::numeric/100))*100)::varchar;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

		-- <disponibilita_cassa>
       flussoElabMifElabRec:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.disponibilita_cassa
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.disponibilita_cassa ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_disp_cassa:=
            trunc((mifFlussoOrdinativoRec.mif_ord_prev::numeric/100-mifFlussoOrdinativoRec.mif_ord_mandati_prev::numeric/100)*100)::varchar;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <anagrafica_beneficiario>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.anagrafica_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.anagrafica_beneficiario ,enteProprietarioId);
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

           	mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	   -- <indirizzo_beneficiario>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       avvisoBenef:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.indirizzo_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.indirizzo_beneficiario ,enteProprietarioId);
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
            	RAISE EXCEPTION ' Errore in lettura indirizzo soggetto [siac_t_indirizzo_soggetto].';
            end if;

			-- serve per calcolo invio_avviso
			avvisoBenef:=COALESCE(indirizzoRec.avviso,'N');

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

            flussoElabMifValore:=trim(both from flussoElabMifValore||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

   	   -- <cap_beneficiario>
       if indirizzoRec.zip_code is not null then
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.cap_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.cap_beneficiario ,enteProprietarioId);
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


        -- <localita_beneficiario>
        if indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.localita_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.localita_beneficiario ,enteProprietarioId);
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


		-- <provincia_beneficiario>
        if indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.provincia_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.provincia_beneficiario ,enteProprietarioId);
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

        -- <partita_iva_beneficiario>
        if soggettoRec.partita_iva is not null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.partita_iva_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.partita_iva_beneficiario ,enteProprietarioId);
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_partiva_benef:=soggettoRec.partita_iva;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
        end if;
       end if;

       -- <codice_fiscale_beneficiario>
       if soggettoRec.partita_iva is null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_fiscale_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_fiscale_beneficiario ,enteProprietarioId);
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	if soggettoRec.codice_fiscale is not null and
               length(soggettoRec.codice_fiscale) in (16,11) then
             	flussoElabMifValore:=soggettoRec.codice_fiscale;
            elsif  flussoElabMifElabRec.flussoElabMifDef is not null then
	            flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
            end if;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;
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
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.beneficiario_quietanzante
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.beneficiario_quietanzante ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           if  ordCsiRelazTipoId is null then
            if ordCsiRelazTipo is null then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
	                ordCsiRelazTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
            end if;

            if ordCsiRelazTipo is  not null then
            	select tipo.relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
         		  and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 	      and date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
            end if;
           end if;

           if ordCsiRelazTipoId is not null then
            	select (sogg.soggetto_id,  sogg.soggetto_desc,
                        sogg.codice_fiscale,  sogg.partita_iva)
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
--         		and   date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
-- 		 		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(sogg.validita_fine,dataFineVal))
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                and   relmdp.validita_fine is null
--			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',relmdp.validita_inizio)
--			    and	date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(relmdp.validita_fine,dataFineVal))
    			and   relmdp.soggetto_relaz_id=relsogg.soggetto_relaz_id
                and   relsogg.soggetto_id_a=MDPRec.soggetto_id
                and   relsogg.soggetto_id_da=soggettoRifId
                and   relsogg.relaz_tipo_id=ordCsiRelazTipoId
                and   relsogg.data_cancellazione is null
                and   relsogg.validita_fine is null;
--			    and   date_trunc('day',dataElaborazione)>=date_trunc('day',relsogg.validita_inizio)
--			    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(relsogg.validita_fine,dataFineVal));

               if soggettoQuietRec is not null then
               	 soggettoQuietId:=soggettoQuietRec.soggetto_id;

               	 select (sogg.soggetto_id, sogg.soggetto_desc,
                         sogg.codice_fiscale, sogg.partita_iva)
                        into soggettoQuietRifRec
		         from  siac_t_soggetto sogg, siac_r_soggetto_relaz rel
		         where rel.soggetto_id_a=soggettQuietRec.soggetto_id
		         and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
		         and   rel.ente_proprietario_id=enteProprietarioId
		         and   rel.data_cancellazione is null
                 and   rel.validita_fine is null
--		         and   date_trunc('day',dataElaborazione)>=date_trunc('day',rel.validita_inizio)
-- 				 and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rel.validita_fine,dataFineVal))
                 and   sogg.soggetto_id=rel.soggetto_id_da
		         and   sogg.data_cancellazione is null
                 and   sogg.validita_fine is null;
--		         and   date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
-- 				 and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(sogg.validita_fine,dataFineVal));


                 if soggettoQuietRifRec is not null then
                 	soggettoQuietRifId:=soggettoQuietRifRec.soggetto_id;
                 end if;
               end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

  		-- <anagrafica_ben_quiet>
        if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.anagrafica_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.anagrafica_ben_quiet ,enteProprietarioId);
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

	   -- <indirizzo_ben_quiet>
	   if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         indirizzoRec:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.indirizzo_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.indirizzo_ben_quiet ,enteProprietarioId);
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
            		RAISE EXCEPTION ' Errore in lettura indirizzo soggettoQuiet [siac_t_indirizzo_soggetto].';
            	end if;

                -- serve per calcolo invio_avviso
				avvisoBenQuiet:=COALESCE(indirizzoRec.avviso,'N');

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

	            flussoElabMifValore:=trim(both from flussoElabMifValore||coalesce(indirizzoRec.toponimo,'')
    	                             ||' '||coalesce(indirizzoRec.numero_civico,''));

        	    if flussoElabMifValore is not null then
	        	    mifFlussoOrdinativoRec.mif_ord_indir_quiet:=substring(flussoElabMifValore from 1 for 30);
	            end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	   end if;

       -- <cap_ben_quiet>
       if soggettoQuietId is not null and indirizzoRec is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.cap_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.cap_ben_quiet ,enteProprietarioId);
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


       -- <localita_ben_quiet>
       if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.localita_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.localita_ben_quiet ,enteProprietarioId);
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

	   -- <provincia_ben_quiet>
       if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;

         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.provincia_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.provincia_ben_quiet ,enteProprietarioId);
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

	   -- <partita_iva_ben_quiet>
	   if soggettoQuietId is not null THEN
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.partita_iva_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.partita_iva_ben_quiet ,enteProprietarioId);
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
                if  soggettoQuietRifId is not null then
	            	if soggettoQuietRifRec.partita_iva is not null then
    	             flussoElabMifValore:=soggettoQuietRifRec.partita_iva;
                    end if;
                elsif soggettoQuietRec.partita_iva is not null then
                	flussoElabMifValore:=soggettoQuietRec.partita_iva;
                end if;
			    if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_partiva_quiet:=flussoElabMifValore;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
       end if;

       -- <codice_fiscale_ben_quiet>
       if soggettoQuietId  then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_fiscale_ben_quiet
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	 select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_fiscale_ben_quiet ,enteProprietarioId);
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if soggettoQuietRifId is not null then
                 if soggettoQuietRifRec.partita_iva is null then
                  if soggettoQuietRifRec.codice_fiscale is not null and
                     length(soggettoQuietRifRec.codice_fiscale) in (16,11) then
	                 flussoElabMifValore:=soggettoQuietRifRec.codice_fiscale;
                  else
                     flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                  end if;
                 end if;
                elsif soggettoQuietRec.partita_iva is null then
                 if soggettoQuietRec.codice_fiscale is not null and
                    length(soggettoQuietRec.codice_fiscale) in (16,11) then
	                 flussoElabMifValore:=soggettoQuietRec.codice_fiscale;
                 else
                 	 flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                 end if;
                end if;

                mifFlussoOrdinativoRec.mif_ord_codfisc_quiet:=flussoElabMifValore;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
       end if;


       -- <delegato>
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       isMDPCo:=false;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.delegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.delegato ,enteProprietarioId);
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

        if isMDPCo=true then
        	-- <anagrafica_delegato>
        	flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.anagrafica_delegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		 	select * into flussoElabMifElabRec
    	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.anagrafica_delegato ,enteProprietarioId);
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

            -- <codice_fiscale_delegato>
            flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_fiscale_delegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
		 	select * into flussoElabMifElabRec
    	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_fiscale_delegato ,enteProprietarioId);
        	if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	    end if;
            if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                	if MDPRec.quietanziante_codice_fiscale is not null and
                       length(MDPRec.quietanziante_codice_fiscale) in (11,16) then
                    	flussoElabMifValore:=MDPRec.quietanziante_codice_fiscale;
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

		-- calcolo già qui il flag_copertura perchè serve anche per invio_avviso
    	-- <flag_copertura>
        flussoElabMifElabRec:=null;
        isOrdACopertura:=false;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.flag_copertura
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.flag_copertura ,enteProprietarioId);
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
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.avviso
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	 	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.avviso ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef   is not null then
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
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
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
                    if isInvioAvviso=true and avvisoTipoClassCodeId is not null then
                    	select distinct 1 into codResult
                        from siac_r_ordinativo_class classOrd, siac_t_class class
                        where classOrd.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                        and   classOrd.classif_id=class.classif_id
                        and   classOrd.data_cancellazione is null
                        and   classOrd.valita_fine is null
--         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',classOrd.validita_inizio)
-- 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(classOrd.validita_fine,dataFineVal))
                        and   class.classif_tipo_id=avvisoTipoClassCodeId
                        and   class.data_cancellazione is null
         	        	and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
 		 		   		and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal));

                        if codResult is null then
                        	isInvioAvviso:=false;
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

       if isInvioAvviso=true then
        -- <invio_avviso>
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.invio_avviso
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
        from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.invio_avviso ,enteProprietarioId);
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



	  -- <piazzatura>
      flussoElabMifElabRec:=null;
      isOrdPiazzatura:=false;
      accreditoGruppoCode:=null;
      isPaeseSepa:=null;
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.piazzatura
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  select * into flussoElabMifElabRec
      from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.piazzatura ,enteProprietarioId);
      if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
      	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            /*select * into isOrdPiazzatura
            from fnc_mif_ordinativo_piazzatura(MDPRec.accredito_tipo_id,
                                               mifOrdinativoIdRec.mif_ord_codice_funzione,
											   flussoElabMifElabRec.flussoElabMifParam,
                                               dataElaborazione,dataFineVal,enteProprietarioId);*/

            isOrdPiazzatura:=fnc_mif_ordinativo_piazzatura(MDPRec.accredito_tipo_id,
                                                           mifOrdinativoIdRec.mif_ord_codice_funzione,
													       flussoElabMifElabRec.flussoElabMifParam,
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
                       ||'. Lettura tipo accredito MDP per popolamento  campi relativi a'||mifFlussoElabTypeRec.piazzatura
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        --raise notice 'Ordinativo con piazzatura % codice funzione=%',mifOrdinativoIdRec.mif_ord_ord_id,mifOrdinativoIdRec.mif_ord_codice_funzione;

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
 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(sepa.validita_fine,dataFineVal));
        end if;

      	-- <abi_beneficiario>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.abi_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.abi_beneficiario ,enteProprietarioId);
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
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then
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
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.cab_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.cab_beneficiario ,enteProprietarioId);
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
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then
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
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_conto_corrente_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_conto_corrente_beneficiario ,enteProprietarioId);
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
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then
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
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.caratteri_controllo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.caratteri_controllo ,enteProprietarioId);
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
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then
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
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_cin
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_cin ,enteProprietarioId);
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
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then
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
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_paese
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_paese ,enteProprietarioId);
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
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 1 for 2);
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cod_paese_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
       end if;

	    -- extra sepa
        if isPaeseSepa is null then
	     -- <conto_corrente_estero>
         flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
      	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.conto_corrente_estero
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	 select * into flussoElabMifElabRec
     	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.conto_corrente_estero ,enteProprietarioId);
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

         -- <denominazione_banca_destinataria>
		 flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
      	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.denominazione_banca_destinataria
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	 select * into flussoElabMifElabRec
     	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.denominazione_banca_destinataria ,enteProprietarioId);
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

        -- estero sepa e extrasepa
        -- <codice_swift>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_swift
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_swift ,enteProprietarioId);
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
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

        -- <coordinate_iban>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.coordinate_iban
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.coordinate_iban ,enteProprietarioId);
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
                        mifFlussoOrdinativoRec.mif_ord_iban_benef:=MDPRec.iban;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

        -- <conto_corrente_postale>
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.conto_corrente_postale
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  	select * into flussoElabMifElabRec
     	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.conto_corrente_postale ,enteProprietarioId);
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
                        mifFlussoOrdinativoRec.mif_ord_cc_postale_benef:=MDPRec.contocorrente;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;

      end if;

      -- <esenzione>
      ordCodiceBollo:=null;
      ordCodiceBolloDesc:=null;
      isOrdBolloEsente:=false;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.esenzione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
 	   select * into flussoElabMifElabRec
       from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.esenzione ,enteProprietarioId);
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
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.esenzione
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

               select bollo.codbollo_code, bollo.codbollo_desc into ordCodiceBollo,ordCodiceBolloDesc
               from siac_d_codicebollo bollo
               where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id;
               --and   bollo.data_cancellazione is null
        	   --and   date_trunc('day',dataElaborazione)>=date_trunc('day',bollo.validita_inizio)
	    	   --and	 date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(bollo.validita_fine,dataFineVal));

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

      -- <carico_bollo>
      if isOrdBolloEsente=false then
       flussoElabMifElabRec:=null;
       flussoElabMifValore:=null;
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.carico_bollo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
 	   select * into flussoElabMifElabRec
       from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.carico_bollo ,enteProprietarioId);
	   if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

       if flussoElabMifElabRec.flussoElabMifAttivo=true then
       	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
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
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.causale_esenzione_bollo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
 	   select * into flussoElabMifElabRec
       from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.causale_esenzione_bollo ,enteProprietarioId);
	   if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

       if flussoElabMifElabRec.flussoElabMifAttivo=true then
       	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if ordCodiceBolloDesc is not null then
	       		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=ordCodiceBolloDesc;
            end if;
     	 else
        	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
        end if;
      end if;
     end if;

     -- <carico_commissioni>
     if mifOrdinativoIdRec.mif_ord_comm_tipo_id is not null then
     	 flussoElabMifElabRec:=null;
      	 flussoElabMifValore:=null;
         flussoElabMifValoreDesc:=null;
       	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.carico_commissioni
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
 	     select * into flussoElabMifElabRec
         from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.carico_commissioni ,enteProprietarioId);
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
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.carico_commissioni
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura commissioni.';

                	select tipo.comm_tipo_code  into flussoElabMifValore
                    from siac_d_commissione_tipo tipo
                    where tipo.comm_tipo_id=mifOrdinativoIdRec.mif_ord_comm_tipo_id;
                    --and   tipo.data_cancellazione is null
        	   		--and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    	   		--and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

                    if flussoElabMifValore is null then
                   		RAISE EXCEPTION ' Errore in lettura dato.';
                    end if;

                	flussoElabMifValoreDesc:=fnc_mif_ordinativo_carico_bollo( flussoElabMifValore,
					                                                          flussoElabMifElabRec.flussoElabMifParam);
        			if flussoElabMifValoreDesc is not null then
			       		mifFlussoOrdinativoRec.mif_ord_commissioni_carico:=flussoElabMifValoreDesc;
            		end if;
               end if; -- param
     		else
        		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if; -- elab
        end if; -- attivo


     end if; -- comm_tipo_if

	 -- <tipo_pagamento>
     flussoElabMifElabRec:=null;
     tipoPagamRec:=null;

     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.tipo_pagamento
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
     from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.tipo_pagamento ,enteProprietarioId);
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
                                             dataElaborazione,dataFineVal,
                                             enteProprietarioId);

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
     if tipoPagamRec is not null then
     	if tipoPagamRec.codeTipoPagamento is not null then
       	 flussoElabMifElabRec:=null;
	     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.codice_pagamento
                	       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	 select * into flussoElabMifElabRec
	     from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.codice_pagamento ,enteProprietarioId);
    	 if flussoElabMifElabRec.flussoElabMifId is null then
     		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	     end if;

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
     flussoElabMifElabRec:=null;
   	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.importo_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
     from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.importo_beneficiario ,enteProprietarioId);
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
   	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.causale
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
     from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.causale ,enteProprietarioId);
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_pagam_causale:=mifOrdinativoIdRec.mif_ord_desc;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

	 -- <data_esecuzione_pagamento>
     flussoElabMifElabRec:=null;
     ordDataScadenza:=null;
   	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.data_esecuzione_pagamento
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
     from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.data_esecuzione_pagamento ,enteProprietarioId);
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.data_esecuzione_pagamento
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza.';
        	select sub.ord_ts_data_scadenza into ordDataScadenza
            from siac_t_ordinativo_ts sub
            where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;

     		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec:=ordDataScadenza;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

	-- <lingua>
    flussoElabMifElabRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.lingua
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
     from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.lingua ,enteProprietarioId);
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
    if tipoPagamRec is not null then
     if tipoPagamRec.defRifDocEsterno=true then
    	flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.riferimento_documento_esterno
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    select * into flussoElabMifElabRec
    	from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.riferimento_documento_esterno ,enteProprietarioId);
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
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.informazioni_tesoriere
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	select * into flussoElabMifElabRec
    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.informazioni_tesoriere ,enteProprietarioId);
	if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
		if flussoElabMifElabRec.flussoElabMifElab=true then
        	flussoElabMifValore:=fnc_mif_ordinativo_informazioni_tes(mifOrdinativoIdRec.mif_ord_ord_id,
            												    mifOrdinativoIdRec.mif_ord_notetes_id,
            													enteProprietarioId,
                                                                dataInizioVal,dataFineVal);
            if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_info_tesoriere:=flussoElabMifValore;
            end if;
        else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		end if;
    end if;

    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    -- <sostituzione_mandato>
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.sostituzione_mandato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    select * into flussoElabMifElabRec
    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.sostituzione_mandato ,enteProprietarioId);
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


   if ordSostRec is not null then
         -- <numero_mandato_collegato>
      	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.numero_mandato_collegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   	 	 select * into flussoElabMifElabRec
      	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.numero_mandato_collegato ,enteProprietarioId);
      	 if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;

      	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	   if flussoElabMifElabRec.flussoElabMifElab=true then
        		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=ordSostRec.ordNumeroSostituto;
	    	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     	end if;
         end if;

     	-- <progressivo_mandato_collegato>
     	flussoElabMifElabRec:=null;
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.progressivo_mandato_collegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	select * into flussoElabMifElabRec
	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.progressivo_mandato_collegato ,enteProprietarioId);
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
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.esercizio_mandato_collegato
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	select * into flussoElabMifElabRec
	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.esercizio_mandato_collegato ,enteProprietarioId);
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

	 -- <Capitolo_origine>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Capitolo_origine
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Capitolo_origine ,enteProprietarioId);
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then

        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Capitolo_origine
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
             where rattr.movgest_ts_id=mifOrdinativoIdRec.mif_ord_movgest_id
             and   rattr.attr_id=capOrigAttrId
             and   rattr.data_cancellazione is null
             and   rattr.validita_fine is null;
    	   	 --and   date_trunc('day',dataElaborazione)>=date_trunc('day',rattr.validita_inizio)
	    	 --and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rattr.validita_fine,dataFineVal));

		    end if;

           	if flussoElabMifValore is not null then
               	mifFlussoOrdinativoRec.mif_ord_dispe_cap_orig:=flussoElabMifValore;
            end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	 end if;

     -- <Numero_articolo_capitolo>
     if bilElemRec.elem_code2::INTEGER!=0 then
      flussoElabMifElabRec:=null;
 	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Numero_articolo_capitolo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      select * into flussoElabMifElabRec
	  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Numero_articolo_capitolo ,enteProprietarioId);
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
      	if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_dispe_articolo:=bilElemRec.elem_code2;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	  end if;
     end if;

     -- <Descrizione_articolo_capitolo>
     if bilElemRec.elem_desc2 is not null then
      flussoElabMifElabRec:=null;
 	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Descrizione_articolo_capitolo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      select * into flussoElabMifElabRec
	  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Descrizione_articolo_capitolo ,enteProprietarioId);
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
      	if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_dispe_descri_articolo:=substring(bilElemRec.elem_desc2 from 1 for 150);
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	  end if;
     end if;

     -- <Codice_tributo>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     oneriCauRec:=null;
 	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_tributo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Codice_tributo ,enteProprietarioId);
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
                	select tipo.onere_tipo_id into codiceTribId
                    from siac_d_onere_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.onere_tipo_code=codiceTrib
                    and   tipo.data_cancellazione is null
	    	   	 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	    	 		and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

                end if;

                if codiceTribId is not null then
					select * into oneriCauRec
                    from fnc_mif_ordinativo_onere( mifOrdinativoIdRec.mif_ord_ord_id,
			 								       codiceTribId,
                                                   true,
				                                   enteProprietarioId,dataElaborazione, dataFineVal);
                    if oneriCauRec is not null then
                    	if oneriCauRec.listaOneri is not null then
	                        mifFlussoOrdinativoRec.mif_ord_dispe_cod_trib:=oneriRec.listaOneri;
                        end if;
                    end if;
                end if;

            end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
	 end if;

     -- <Causale_770> -- da fare
	 if oneriCauRec is not null then
     	if oneriCauRec.listaCausali is not null then
	     flussoElabMifElabRec:=null;

 		 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Causale_770
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     select * into flussoElabMifElabRec
		 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Causale_770 ,enteProprietarioId);
	     if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
		 end if;
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_dispe_causale_770:=oneriRec.listaCausali;
        	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    	end if;
		 end if;
     end if;

     -- <Data_nascita_beneficiario>
     flussoElabMifElabRec:=null;
     datiNascitaRec:=null;
 	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Data_nascita_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Data_nascita_beneficiario ,enteProprietarioId);
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      	if flussoElabMifElabRec.flussoElabMifElab=true then

        		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Data_nascita_beneficiario
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
                 	mifFlussoOrdinativoRec.mif_ord_dispe_dtns_benef:=datiNascitaRec.nascita_data;
                 end if;
                end if;
     	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  	end if;
      end if;


      -- <Luogo_nascita_beneficiario>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if datiNascitaRec is not null then
       if datiNascitaRec.comune_id_nascita is not null then
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Luogo_nascita_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        select * into flussoElabMifElabRec
	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Luogo_nascita_beneficiario ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
  	 	 RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
       	 if flussoElabMifElabRec.flussoElabMifElab=true then

        		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Luogo_nascita_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura luogo di nascita soggetto.';

                select com.comune_desc into flussoElabMifValore
                from siac_t_comune com
                where com.comune_id=  datiNascitaRec.comune_id_nascita
                and   com.data_cancellazione is null
                and   com.validita_fine is null;
    	   	--	and   date_trunc('day',dataElaborazione)>=date_trunc('day',com.validita_inizio)
	    	--	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(com.validita_fine,dataFineVal));

                if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_dispe_cmns_benef:=flussoElabMifValore;
                end if;
     	 else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  	 end if;
        end if;

        -- <Prov_nascita_beneficiario>
        flussoElabMifValore:=null;
        flussoElabMifElabRec:=null;
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Prov_nascita_beneficiario
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        select * into flussoElabMifElabRec
	    from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Prov_nascita_beneficiario ,enteProprietarioId);
        if flussoElabMifElabRec.flussoElabMifId is null then
  	 	 RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
       	 if flussoElabMifElabRec.flussoElabMifElab=true then

        		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Luogo_nascita_beneficiario
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
                 	mifFlussoOrdinativoRec.mif_ordinativo_dispe_prns_benef:=flussoElabMifValore;
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
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Note
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     select * into flussoElabMifElabRec
	 from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Note ,enteProprietarioId);
     if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
        		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Note
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura attr_id per '||NOTE_ORD_ATTR||' .';

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
                end if;

                if noteOrdAttrId is not null then
                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Note
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura note per attributo ordinativo '||NOTE_ORD_ATTR||' .';

                	select attr.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr attr
                    where attr.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   attr.attr_id=noteOrdAttrId
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
--         			and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
-- 		 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(attr.validita_fine,dataFineVal));
                end if;

                if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_dispe_note:=flussoElabMifValore;
                end if;
   	 else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Descrizione_tipo_pagamento>
   flussoElabMifValore:=null;
   flussoElabMifElabRec:=null;
   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Descrizione_tipo_pagamento
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   select * into flussoElabMifElabRec
   from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Descrizione_tipo_pagamento ,enteProprietarioId);
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
                	/*select accre.accredito_tipo_desc into flussoElabMifValore
                    from siac_d_accredito_tipo accre
                    where accre.accredito_tipo_id=MDPRec.accredito_tipo_id
                    and   accre.data_cancellazione is null
         			and   date_trunc('day',dataElaborazione)>=date_trunc('day',accre.validita_inizio)
 		 			and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(accre.validita_fine,dataFineVal));*/

                if flussoElabMifValore is not null then
                 	/*mifFlussoOrdinativoRec.mif_ord_dispe_descri_pag:=flussoElabMifValore;*/
                    mifFlussoOrdinativoRec.mif_ord_dispe_descri_pag:=codAccreRec.accredito_tipo_desc;
                end if;
   	 else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Descrizione_atto_autorizzativo>
   if attoAmmRec is not null then
   	if attoAmmRec.attoAmmOggetto is not null then
    	flussoElabMifElabRec:=null;
   		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Descrizione_atto_autorizzativo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		select * into flussoElabMifElabRec
 		from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Descrizione_atto_autorizzativo ,enteProprietarioId);
	   	if flussoElabMifElabRec.flussoElabMifId is null then
	  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;
	    if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
                 	mifFlussoOrdinativoRec.mif_ord_dispe_descri_attoamm:=attoAmmRec.attoAmmOggetto;
   	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	    end if;
       end if;
  end if;
 end if;

  -- <Data_scadenza_interna>
  flussoElabMifElabRec:=null;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Data_scadenza_interna
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Data_scadenza_interna ,enteProprietarioId);
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
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Data_scadenza_interna
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza interna.';
	        		select sub.ord_ts_data_scadenza into ordDataScadenza
	    	        from siac_t_ordinativo_ts sub
    	    	    where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;
                end if;

                if ordDataScadenza is not null then
	               	mifFlussoOrdinativoRec.mif_ord_dispe_data_scad_interna:=ordDataScadenza;
                end if;
   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Allegato_Atto>
   flussoElabMifElabRec:=null;
   flussoElabMifValore:=null;
   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Allegato_Atto
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   select * into flussoElabMifElabRec
   from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Allegato_Atto ,enteProprietarioId);
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
	   	mifFlussoOrdinativoRec.mif_ord_dispe_atto_all:=flussoElabMifValore;
      end if;


   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;


   -- <Codice_Programma>
   flussoElabMifElabRec:=null;
   flussoElabMifValore:=null;
   programmaId:=null;
   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_Programma
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   select * into flussoElabMifElabRec
   from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Codice_Programma ,enteProprietarioId);
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
 	 if flussoElabMifElabRec.flussoElabMifElab=true then
      if flussoElabMifElabRec.flussoElabMifParam is not null then
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
      end if;

      if flussoElabMifValore is not null then
	   	mifFlussoOrdinativoRec.mif_ord_programma:=flussoElabMifValore;
      end if;


   	 else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	 end if;
   end if;

   -- <Codice_Missione>
   if programmaId is not null then
	   flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_Missione
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   	   select * into flussoElabMifElabRec
	   from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Codice_Missione ,enteProprietarioId);
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
                	select fam.classif_fam_tree_id into famMissProgrCodeId
                    from siac_t_class_fam_tree fam
                    where fam.ente_proprietario_id=enteProprietarioId
                    and   fam.class_fam_code=famMissProgrCode
                    and   fam.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(fam.validita_fine,dataFineVal));

                end if;

                if famMissProgrCodeId is not null then

                	select cp.classif_code into flussoElabMifValore
					from siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
					where cf.classif_id=programmaId
                    and   cf.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',cf.validita_inizio)
		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cf.validita_fine,dataFineVal))
					and   r.classif_id=cf.classif_id
					and   r.classif_id_padre is not null
					and   r.classif_fam_tree_id=famMissProgrCodeId
                    and   r.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(r.validita_fine,dataFineVal))
					and   cp.classif_id=r.classif_id_padre
                    and   cp.data_cancellazione is null
		    		and   date_trunc('day',dataElaborazione)>=date_trunc('day',cp.validita_inizio)
		 		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cp.validita_fine,dataFineVal))
                    order by cp.classif_id
                    limit 1;

                end if;

                if flussoElabMifValore is not null then
	  			 	mifFlussoOrdinativoRec.mif_ord_missione:=flussoElabMifValore;
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
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_Economico
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Codice_Economico ,enteProprietarioId);
  if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  end if;
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
 	 if flussoElabMifElabRec.flussoElabMifElab=true then
      if flussoElabMifElabRec.flussoElabMifParam is not null then

      	if eventoTipoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_Economico
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo evento '||flussoElabMifElabRec.flussoElabMifParam||'.';

        	select tipo.evento_tipo_id into eventoTipoCodeId
            from siac_d_evento_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.evento_tipo_code=flussoElabMifElabRec.flussoElabMifParam
            and   tipo.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));

            if eventoTipoCodeId is null then
            	 RAISE EXCEPTION ' Dato non reperito.';
            end if;

        end if;

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
--  	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',regMovFin.validita_inizio)
--        and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(regMovFin.validita_fine,dataFineVal))
        and   rEvento.data_cancellazione is null
        and   rEvento.validita_fine is null
--		and   date_trunc('day',dataElaborazione)>=date_trunc('day',rEvento.validita_inizio)
--		and	date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rEvento.validita_fine,dataFineVal))
        and   evento.data_cancellazione is null
 	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',evento.validita_inizio)
	    and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(evento.validita_fine,dataFineVal));

	    if 	flussoElabMifValore is not null then
        	mifFlussoOrdinativoRec.mif_ord_conto_econ:=flussoElabMifValore;
        end if;


      end if;
     else
   	 	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
  end if;

  -- <Importo_Codice_Economico> da fare non si sa ancora come

  -- <Codice_Ue>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_Ue
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Codice_Ue ,enteProprietarioId);
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
        	select tipo.classif_tipo_id into codiceUECodeTipoId
            from  siac_d_class_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.classif_tipo_code=codiceUECodeTipo
            and   tipo.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
        end if;

        if codiceUECodeTipoId is not null then
        	select class.classif_code into flussoElabMifValore
            from siac_r_bil_elem_class rclass, siac_t_class class
            where rclass.elem_id=mifOrdinativoIdRec.mif_ord_elem_id
            and   rclass.data_cancellazione is null
            and   rclass.validita_fine is null
		--    and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio)
	--	 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal))
            and   class.classif_id=rclass.classif_id
            and   class.classif_tipo_id=codiceUECodeTipoId
            and   class.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
            order by rclass.elem_classif_id
            limit 1;

        end if;
        if flussoElabMifValore is not null then
	     	mifFlussoOrdinativoRec.mif_ord_cod_ue:=flussoElabMifValore;
        end if;
     end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <Codice_Cofog>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.Codice_Cofog
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.Codice_Cofog ,enteProprietarioId);
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
        	select tipo.classif_tipo_id into codiceCofogCodeTipoId
            from  siac_d_class_tipo tipo
            where tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.classif_tipo_code=codiceCofogCodeTipo
            and   tipo.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal));
        end if;

        if codiceCofogCodeTipoId is not null then
        	select class.classif_code into flussoElabMifValore
            from siac_r_bil_elem_class rclass, siac_t_class class
            where rclass.elem_id=mifOrdinativoIdRec.mif_ord_elem_id
            and   rclass.data_cancellazione is null
            and   rclass.validita_fine is null
		   -- and   date_trunc('day',dataElaborazione)>=date_trunc('day',rclass.validita_inizio)
		 	--and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(rclass.validita_fine,dataFineVal))
            and   class.classif_id=rclass.classif_id
            and   class.classif_tipo_id=codiceCofogCodeTipoId
            and   class.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
		 	and	  date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(class.validita_fine,dataFineVal))
            order by rclass.elem_classif_id
            limit 1;

        end if;
        if flussoElabMifValore is not null then
	     	mifFlussoOrdinativoRec.mif_ord_cofog_codice:=flussoElabMifValore;
        end if;
     end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;
  -- <Importo_Cofog> da fare ma non si sa ancora come

  -- <InfSerMan_NumeroImpegno> da fare
  -- <InfSerMan_SubImpegno> da fare

  -- <InfSerMan_CodiceOperatore>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.InfSerMan_CodiceOperatore
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.InfSerMan_CodiceOperatore ,enteProprietarioId);
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
	     	mifFlussoOrdinativoRec.mif_ord_code_operatore:=flussoElabMifValore;
        end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <InfSerMan_Fattura_Descr>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.InfSerMan_Fattura_Descr
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.InfSerMan_Fattura_Descr ,enteProprietarioId);
  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  end if;
  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
        	flussoElabMifValore:=fnc_mif_ordinativo_documenti( mifOrdinativoIdRec.mif_ord_ord_id,
 													           flussoElabMifElabRec.flussoElabMifParam::integer,
		                                                  	   enteProprietarioId,
	                                                           dataElaborazione,dataFineVal);
        end if;

        if flussoElabMifValore is not null then
	     	mifFlussoOrdinativoRec.mif_ord_fatture:=flussoElabMifValore;
        end if;
    else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	end if;
  end if;

  -- <InfSerMan_DescrizioniEstesaCapitolo>
  flussoElabMifElabRec:=null;
  flussoElabMifValore:=null;
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||mifFlussoElabTypeRec.InfSerMan_DescrizioniEstesaCapitolo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
  select * into flussoElabMifElabRec
  from  fnc_mif_d_flusso_elaborato (flussoElabMifTipoId,mifFlussoElabTypeRec.InfSerMan_DescrizioniEstesaCapitolo ,enteProprietarioId);
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

  -- <siope_codice_cge> da fare
  -- <siope_descr_cge>  da fare

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
 	    -- <tipo_contabilita_ente_ricevente>
		-- <Codice_cup>
        -- <Codice_cpv>
        -- <gestione_provvisoria>
        -- <frazionabile>
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
         --mif_ord_progr_dest,
  		 mif_ord_bci_conto,
  		 --mif_ord_bci_tipo_contabil,
  		 mif_ord_class_codice_cge,
  		 mif_ord_class_importo,
  		 --mif_ord_class_codice_cup,
 		 --mif_ord_class_codice_cpv,
  		 --mif_ord_class_codice_gest_prov,
  		 --mif_ord_class_codice_gest_fraz,
  		 mif_ord_codifica_bilancio,
  		 mif_ord_articolo,
  		 --mif_ord_voce_eco,
  		 mif_ord_desc_codifica,
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
  		 mif_ord_partiva_benef,
  		 mif_ord_codfisc_benef,
  		 mif_ord_anag_quiet,
  		 mif_ord_indir_quiet,
  		 mif_ord_cap_quiet,
  		 mif_ord_localita_quiet,
  		 mif_ord_prov_quiet,
  		 mif_ord_partiva_quiet,
  		 mif_ord_codfisc_quiet,
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
  		 --mif_ord_cod_ente_benef,
  		 --mif_ord_fl_pagam_cond_benef,
  		 mif_ord_bollo_esenzione,
  		 mif_ord_bollo_carico,
  		 mif_ordin_bollo_caus_esenzione,
  		-- mif_ord_bollo_importo,
  		 --mif_ord_bollo_carico_spe,
  		-- mif_ord_bollo_importo_spe,
  		 mif_ord_commissioni_carico,
  		-- mif_ord_commissioni_importo,
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
  		 mif_ord_dispe_cap_orig,
  		 mif_ord_dispe_articolo,
  		 mif_ord_dispe_descri_articolo,
  		 --mif_ord_dispe_somme_non_sogg,
  		 mif_ord_dispe_cod_trib,
  		 mif_ord_dispe_causale_770,
  		 mif_ord_dispe_dtns_benef,
  		 mif_ord_dispe_cmns_benef,
  		 mif_ordinativo_dispe_prns_benef,
  		 mif_ord_dispe_note,
  		 mif_ord_dispe_descri_pag,
  		 mif_ord_dispe_descri_attoamm,
  		 --mif_ord_dispe_capitolo_peg,
  		 --mif_ord_dispe_vincoli_dest,
  		 --mif_ord_dispe_vincolato,
  		 --mif_ord_dispe_voce_eco,
  		 --mif_ord_dispe_distinta,
  		 mif_ord_dispe_data_scad_interna,
  		 --mif_ord_dispe_rev_vinc,
  		 mif_ord_dispe_atto_all,
  		 --mif_ord_dispe_liquidaz,
  		 mif_ord_missione,
  		 mif_ord_programma,
  		 mif_ord_conto_econ,
  		 --mif_ord_importo_econ,
  		 mif_ord_cod_ue,
  		 mif_ord_cofog_codice,
  		-- mif_ord_cofog_importo,
  		 --mif_ord_numero_imp,
  		 --mif_ord_numero_subimp,
  		 mif_ord_code_operatore,
  		 --mif_ord_nome_operatore,
  		 mif_ord_fatture,
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
  	     mifFlussoOrdinativoRec.mif_ord_importo,
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
  		flussoElabMifOilId, --idflussoOil
  		now(),
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
 		-- :mif_ord_progr_dest,
 		mifFlussoOrdinativoRec.mif_ord_bci_conto,
  		--:mif_ord_bci_tipo_contabil,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_class_importo,
 		-- :mif_ord_class_codice_cup,
 		-- :mif_ord_class_codice_cpv,
 		-- :mif_ord_class_codice_gest_prov,
 		-- :mif_ord_class_codice_gest_fraz,
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio,
  		mifFlussoOrdinativoRec.mif_ord_articolo,
 		-- :mif_ord_voce_eco,
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,
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
 		mifFlussoOrdinativoRec.mif_ord_partiva_benef,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_benef,
  		mifFlussoOrdinativoRec.mif_ord_anag_quiet,
        mifFlussoOrdinativoRec.mif_ord_indir_quiet,
  		mifFlussoOrdinativoRec.mif_ord_cap_quiet,
 		mifFlussoOrdinativoRec.mif_ord_localita_quiet,
  		mifFlussoOrdinativoRec.mif_ord_prov_quiet,
 		mifFlussoOrdinativoRec.mif_ord_partiva_quiet,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_quiet,
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
  		--:mif_ord_cod_ente_benef,
 		-- :mif_ord_fl_pagam_cond_benef,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
  		mifFlussoOrdinativoRec.mif_ord_bollo_carico,
  		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione,
 		-- 0,
 		-- :mif_ord_bollo_carico_spe,
 		-- :mif_ord_bollo_importo_spe,
 		mifFlussoOrdinativoRec.mif_ord_commissioni_carico,
		--0,
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
        mifFlussoOrdinativoRec.mif_ord_dispe_cap_orig,
        mifFlussoOrdinativoRec.mif_ord_dispe_articolo,
        mifFlussoOrdinativoRec.mif_ord_dispe_descri_articolo,
--  :mif_ord_dispe_somme_non_sogg,
		mifFlussoOrdinativoRec.mif_ord_dispe_cod_trib,
		mifFlussoOrdinativoRec.mif_ord_dispe_causale_770,
		mifFlussoOrdinativoRec.mif_ord_dispe_dtns_benef,
		mifFlussoOrdinativoRec.mif_ord_dispe_cmns_benef,
		mifFlussoOrdinativoRec.mif_ordinativo_dispe_prns_benef,
        mifFlussoOrdinativoRec.mif_ord_dispe_note,
        mifFlussoOrdinativoRec.mif_ord_dispe_descri_pag,
        mifFlussoOrdinativoRec.mif_ord_dispe_descri_attoamm,
 -- :mif_ord_dispe_capitolo_peg,
 -- :mif_ord_dispe_vincoli_dest,
 -- :mif_ord_dispe_vincolato,
 -- :mif_ord_dispe_voce_eco,
--  :mif_ord_dispe_distinta,
        mifFlussoOrdinativoRec.mif_ord_dispe_data_scad_interna,
  --:mif_ord_dispe_rev_vinc,
        mifFlussoOrdinativoRec.mif_ord_dispe_atto_all,
--  :mif_ord_dispe_liquidaz,
        mifFlussoOrdinativoRec.mif_ord_missione,
        mifFlussoOrdinativoRec.mif_ord_programma,
        mifFlussoOrdinativoRec.mif_ord_conto_econ,
 -- :mif_ord_importo_econ,
		mifFlussoOrdinativoRec.mif_ord_cod_ue,
		mifFlussoOrdinativoRec.mif_ord_cofog_codice,
 -- :mif_ord_cofog_importo,
 -- :mif_ord_numero_imp,
 -- :mif_ord_numero_subimp,
        mifFlussoOrdinativoRec.mif_ord_code_operatore,
		--:mif_ord_nome_operatore,
        mifFlussoOrdinativoRec.mif_ord_fatture,
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

   -- <ritenute>
   -- <ritenuta>
   -- <tipo_ritenuta>
   -- <importo_ritenuta>
   -- <numero_reversale>
   -- <progressivo_reversale>
   -- <progressivo_ritenuta> non gestito

   if  isRitenutaAttivo=true then
    ritenutaRec:=null;
    execute  'ANALYZE mif_t_ordinativo_spesa_ritenute;';
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  '||mifFlussoElabTypeRec.tipo_ritenuta
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ritenutaRec in
    (select *
     from fnc_mif_ordinativo_ritenute(mifOrdinativoIdRec.mif_ord_ord_id,
         	 					      tipoRelazRitOrd,tipoRelazSubOrd,tipoRelazSprOrd,
                                      tipoOnereIrpefId,tipoOnereInpsId,
									  ordStatoCodeAId,ordDetTsTipoId,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   '||mifFlussoElabTypeRec.tipo_ritenuta
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
    execute  'ANALYZE mif_t_ordinativo_spesa_ricevute;';
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  '||mifFlussoElabTypeRec.numero_ricevuta
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   '||mifFlussoElabTypeRec.numero_ricevuta
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

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';
   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,numeroOrdinativiTrasm,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_spesa')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di spesa.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
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
        raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
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
        raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
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
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
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