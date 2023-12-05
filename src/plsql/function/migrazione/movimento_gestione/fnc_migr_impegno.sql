/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_impegno(
  enteproprietarioid integer,
  annobilancio varchar,
  tipocapitologestusc varchar,
  tipomovgestusc varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  idmin integer,
  idmax integer,
  out numeroimpegniinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_impegno --> function che effettua il caricamento degli impegni/subimpegni migrati
    -- leggendo in tab migr_impegno
      -- tipoMovGestUsc=I per caricamento impegni
      -- tipoMovGestUsc=S per caricamento subimpegni
    -- effettua inserimento di
     -- siac_t_movgest    -- per tipoMovGestUsc=I caricamento di impegno
        -- siac_r_movgest_bil_elem - relazione rispetto al capitolo-ueb
     -- siac_t_movgest_ts -- per tipoMovGestUsc=I caricamento tipo=T
                          -- per tipoMovGestUsc=S caricamento tipo=S per caricamento del subimpegno
                             -- relazionato attraverso movgest_ts_id_padre al tipo=T di impegno padre
                          -- siac_r_movgest_ts_stato
    					  -- siac_t_movgest_ts_dett per importo iniale e importo attuale
                          -- siac_r_movgest_ts_attr per impegno attributi
                             -- <annoCapitoloOrigine,numeroCapitoloOrigine,numeroArticoloOrigine,numeroUEBOrigine,
                             --  annoOriginePlur,numeroOriginePlur,
                             --  annoRiaccertamento,numeroRiaccertamento,flagDaRiaccertamento, note>
                          -- siac_r_movgest_ts_attr per impegno e subimpegno attributi
                             -- < cup, cig >
                          -- siac_r_movgest_ts_programma per impegno collegamento con progetto-opera
                          -- siac_r_movgest_ts_sogg collegamento con soggetto
                           -- se migr_impegno.soggetto_determinato='S' ( impegno e subimpegno )
                          -- siac_r_movgest_ts_soggclasse collegamento classe soggetto (dovrebbe essere solo per impegno)
                           	 -- se migr_impegno.soggetto_determinato='G'
                             	-- cerca classe in migr_classe
                             -- se migr_impegno.soggetto_determinato='N'
                                -- ricava la classe dal campo migr_impegno.classe_soggetto
                          -- siac_r_movgest_class -- relazione classificatori
                           -- tipo_impegno (impegno)
                          -- siac_r_migr_movgest_ts
                             -- inserimento della relazione tra migr_impegno_id e mogest_ts_id
     -- richiama
	 -- fnc_migr_aggiorna_classif (impegno)
        -- per aggiornamento delle descrizioni dei classificatori caricati
        -- in migr_classif_impacc
     -- fnc_migr_classif_movgest (impegno) per
        --  il caricamento dei classificatori generici <CLASSIFICATORE_11...._15>
        --  collegamento con impegno
     -- fnc_migr_attoamm_movgest per
        --  il caricamento di atto amministrativo <classificatore tipo CDR > ( impegno, subimpegno)
    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroImpegniInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_impegno
        -- -1 errore
        -- N=numero impegni-subimpegni inseriti

    -- Punti di attenzione
     -- cod_interv_class AIPO presente in migr_impegno ma non ancora gestito in siac
     -- TRB e PdcFIN : indicati in tracciato ma potrebbero non arrivare da sistema di origine
       -- al momento gestito solo PdcFin, Cofog e perimetro_sanitario
     -- Atto Amministrativo
       -- si controlla esistenza di atto proveniente dal sistema di origine
       -- se esiste lo si utilizza per collegarlo a impegno,subimpegno
       -- se non esiste lo si inserisce
       -- SPR (movimento interno ) -- movimento gestione senza provvedimento
         -- il numero se non passato dal sistema di origine sara impostato a 9999999


	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	bilancioid integer:=0;

	code varchar(500) := '';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

	movgestTipoImpId integer := 0;
	movgestTipoTsImpId integer := 0;
	movgestTipoTsSubImpId integer := 0;
	idStatoValido integer := 0;
	idTipoCapitoloGestUsc integer := 0;
	idImportoIniziale integer := 0;
	idImportoAttuale integer := 0;
	idAttr_annoCapOrig integer := 0; -- id siac_t_attr per code ANNOCAP_ORIG_IMP_ATTR
	idAttr_numCapOrigine integer := 0; -- id siac_t_attr per code NROCAP_ORIG_IMP_ATTR
	idAttr_numArtOrigine integer := 0; -- id siac_t_attr per code NROART_ORIG_IMP_ATTR
	idAttr_numUebOrigine integer := 0; -- id siac_t_attr per code UEB_ORIG_IMP_ATTR
	idAttr_noteMovgest  integer := 0; -- id siac_t_attr per code NOTE_IMP_ATTR
	idAttr_annoOrigPlur integer := 0; -- id siac_t_attr per code ANNOIMP_PLUR_IMP_ATTR
	idAttr_numOrigPlur integer := 0; -- id siac_t_attr per code NIMP_PLUR_IMP_ATTR
	idAttr_annoRiaccertato integer := 0; -- id siac_t_attr per code ANNOIMP_RIACC_IMP_ATTR
	idAttr_numRiaccertato  integer := 0; -- id siac_t_attr per code NIMP_RIACC_IMP_ATTR
	idAttr_flagDaRiaccertamento integer := 0; -- id siac_t_attr per code FLAG_RIACC_IMP_ATTR
	boolean_value char(1);
	idTipoImpegnoClass integer := 0;
	idStatovalidoProgramma integer := 0;
	idAttr_cup integer := 0; -- id siac_t_attr per code CUP_IMP_ATTR
	idAttr_cig integer:= 0;
	idClass_pdc integer:= 0;
	idClass_cofog integer:= 0;
	idClass_tipoSanita integer:= 0;
	idClass_siope integer:= 0;          -- 20.11.2015 Davide gestione siope
    idClass_tipoSpesaRicorrente            integer:= 0; -- 03.03.2016 Davide aggiunta lettura altri attributi impegni
    idClass_tipoTransazioneUeSpesa         integer:= 0; -- 03.03.2016 Davide aggiunta lettura altri attributi impegni
	idClass_tipoPoliticheRegionaliUnitarie integer:= 0; -- 03.03.2016 Davide aggiunta lettura altri attributi impegni

	migrImpegno  record;
	migrAttoAmmMovGest record;
	migrClassifMovGest record;
	migrAggClassifImp record;
	aggProgressivi record;

	countMigrImpegno integer:=0;


	movgestId integer:=0;
	movgestTsId integer:=0;
	movgestTsPadreId integer:=0;

	capitoloId   integer:=0;
	soggettoId   integer:=0;
	soggettoClasseId INTEGER:=0;

	ambitoId   integer:=0;
	soggettoClasseTipoId integer:=0;

	numeroElementiInseriti   integer:=0;

	strToElab varchar(1000):='';
	classeSoggettoCode varchar(1000):='';
	classeSoggettoDesc varchar(1000):='';

	classifCode  varchar(1000):='';
	classifDesc  varchar(1000):='';
    classif_siope_code varchar(50) :=''; -- 20.11.2015 Davide gestione siope

	--    costanti
	NVL_STR             CONSTANT VARCHAR:='';
	SEPARATORE			CONSTANT  varchar :='||';
	AMBITO_SOGG         CONSTANT  varchar :='AMBITO_FIN';
	SOGG_CLASSE_TIPO_ND CONSTANT  varchar :='ND';

	NOTE_IMP_LENGTH    CONSTANT integer:=500;

	STATO_VALIDO CONSTANT  varchar :='VA';
	MOVGEST_IMPEGNI_LIV CONSTANT integer:=1;
	MOVGEST_SUBIMP_LIV CONSTANT integer:=1;

	MOVGEST_IMPEGNI       CONSTANT varchar:='I';
	MOVGEST_TS_IMPEGNI    CONSTANT varchar:='T';
	MOVGEST_TS_SUBIMP     CONSTANT varchar:='S';

	IMPORTO_INIZIALE CONSTANT varchar :='I';
	IMPORTO_ATTUALE CONSTANT varchar :='A';

	ANNOCAP_ORIG_IMP_ATTR CONSTANT  varchar:='annoCapitoloOrigine';
	NROCAP_ORIG_IMP_ATTR  CONSTANT  varchar:='numeroCapitoloOrigine';
	NROART_ORIG_IMP_ATTR  CONSTANT  varchar:='numeroArticoloOrigine';
	UEB_ORIG_IMP_ATTR     CONSTANT  varchar:='numeroUEBOrigine';

	NOTE_IMP_ATTR         CONSTANT  varchar:='NOTE_MOVGEST';
	CUP_IMP_ATTR          CONSTANT  varchar:='cup';
	CIG_IMP_ATTR          CONSTANT  varchar:='cig';

	ANNOIMP_PLUR_IMP_ATTR CONSTANT  varchar:='annoOriginePlur';
	NIMP_PLUR_IMP_ATTR    CONSTANT  varchar:='numeroOriginePlur';

	ANNOIMP_RIACC_IMP_ATTR CONSTANT varchar:='annoRiaccertato';
	NIMP_RIACC_IMP_ATTR    CONSTANT varchar:='numeroRiaccertato';
	FLAG_RIACC_IMP_ATTR    CONSTANT varchar:='flagDaRiaccertamento';

	STATO_VALIDO_SOGG      CONSTANT varchar:='VALIDO';

	SPR                    CONSTANT varchar:='SPR||';
	TIPO_IMPEGNO_CLASS    CONSTANT varchar:='TIPO_IMPEGNO';
	PDC_FIN_V_LIV         CONSTANT varchar:='PDC_V';

	PERIMETRO_SANITARIO_SPESA CONSTANT varchar:='PERIMETRO_SANITARIO_SPESA';
--	DIVISIONE_COFOG           CONSTANT varchar:= 'DIVISIONE_COFOG';
	GRUPPO_COFOG           CONSTANT varchar:= 'GRUPPO_COFOG';
	CL_SIOPE              CONSTANT varchar:='SIOPE_SPESA_I'; -- 20.11.2015 Davide gestione siope
    SIOPECOD_DEF          CONSTANT varchar :='XXXX';         -- 27.11.2015 Davide gestione siope

	SPESA_RICORRENTE             CONSTANT varchar:= 'RICORRENTE_SPESA';             -- 03.03.2016 Davide aggiunta lettura altri attributi impegni
	TRANSAZIONE_UE_SPESA         CONSTANT varchar:= 'TRANSAZIONE_UE_SPESA';         -- 03.03.2016 Davide aggiunta lettura altri attributi impegni
	POLITICHE_REGIONALI_UNITARIE CONSTANT varchar:= 'POLITICHE_REGIONALI_UNITARIE'; -- 03.03.2016 Davide aggiunta lettura altri attributi impegni

	--- classificatori liberi per impegni
	CLASSIFICATORE_11 CONSTANT varchar:='CLASSIFICATORE_11';
	CLASSIFICATORE_12 CONSTANT varchar:='CLASSIFICATORE_12';
	CLASSIFICATORE_13 CONSTANT varchar:='CLASSIFICATORE_13';
	CLASSIFICATORE_14 CONSTANT varchar:='CLASSIFICATORE_14';
	CLASSIFICATORE_15 CONSTANT varchar:='CLASSIFICATORE_15';

	ENTE_REGP_GIUNTA CONSTANT  integer:=2;
	ENTE_REGP_AIPO   CONSTANT  integer:=4;
	ENTE_COTO        CONSTANT  integer:=1;

	v_count integer := 0;

BEGIN
    numeroImpegniInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione impegni.da id ['||idmin||'] a id ['||idmax||']';
    strMessaggio:='Lettura impegni da migrare.';
	/*
	select COALESCE(count(*),0) into countMigrImpegno
    from migr_impegno ms
    where ms.ente_proprietario_id=enteProprietarioId and
          ms.tipo_movimento = tipoMovGestUsc and
          ms.fl_elab='N'
          and ms.migr_impegno_id >= idMin and ms.migr_impegno_id <=idMax;

	if COALESCE(countMigrImpegno,0)=0 then
         messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
         numeroImpegniInseriti:=-12;
         return;
    end if;*/

	begin
		select distinct 1 into strict countMigrImpegno from migr_impegno ms
		where ms.ente_proprietario_id=enteProprietarioId and
		    ms.tipo_movimento = tipoMovGestUsc and
		    ms.fl_elab='N'
		    and ms.migr_impegno_id >= idMin and ms.migr_impegno_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroImpegniInseriti:=-12;
		 return;
	end;

    -- lettura id bilancio
	select getBilancio.idbilancio, getBilancio.messaggiorisultato into bilancioid,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,annoBilancio) getBilancio;
	if (bilancioid=-1) then
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		numeroImpegniInseriti:=-13;
		return;
	end if;

	strMessaggio:='Lettura AMBITO_FIN.';

    /*select ambito.ambito_id into ambitoId
    from siac_d_ambito ambito
    where ambito.ambito_code=AMBITO_SOGG and
          ambito.ente_proprietario_id=enteProprietarioId;

	if COALESCE(ambitoId,0)=0 then
	    RAISE EXCEPTION 'Ambito FIN inesistente per ente % ',enteProprietarioId ;
	end if;*/
	begin
		select
			ambito.ambito_id into strict ambitoId
		from
			siac_d_ambito ambito
		where
			ambito.ambito_code=AMBITO_SOGG and
			ambito.ente_proprietario_id=enteProprietarioId;
	exception
		when no_data_found then
			RAISE EXCEPTION 'Ambito FIN inesistente per ente % ',enteProprietarioId ;
		when others  THEN
			RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;

	strMessaggio:='Lettura soggetto_classe_tipo_id per AMBITO='||ambito_sogg||' TIPO '||SOGG_CLASSE_TIPO_ND;

	begin
		/*select soggetto_classe_tipo_id into soggettoClasseTipoId
		from siac_d_soggetto_classe_tipo soggClasseTipo
		where 	soggClasseTipo.ambito_id=ambitoId and
			soggClasseTipo.ente_proprietario_id=enteProprietarioId and
			soggClasseTipo.soggetto_classe_tipo_code=SOGG_CLASSE_TIPO_ND;

		if COALESCE(soggettoClasseTipoId,0)=0 then
			RAISE EXCEPTION 'SoggettoClasseTipo inesistente per ente % ',enteProprietarioId ;
		end if;*/
		select soggetto_classe_tipo_id into strict soggettoClasseTipoId
			from siac_d_soggetto_classe_tipo soggClasseTipo
			where 	soggClasseTipo.ambito_id=ambitoId and
				soggClasseTipo.ente_proprietario_id=enteProprietarioId and
				soggClasseTipo.soggetto_classe_tipo_code=SOGG_CLASSE_TIPO_ND;

	exception
		when no_data_found then
			RAISE EXCEPTION 'SoggettoClasseTipo inesistente per ente % ',enteProprietarioId ;
		when others  THEN
			RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;

    if tipoMovGestUsc=MOVGEST_IMPEGNI then
		strMessaggio:='Aggiornamento Classificatori descri.';
		select * into migrAggClassifImp
	    from fnc_migr_aggiorna_classif (MOVGEST_IMPEGNI,
    						           enteProprietarioId,loginOperazione,dataElaborazione);

	   if migrAggClassifImp.codiceRisultato=-1 then
       	RAISE EXCEPTION ' % ', migrAggClassifImp.messaggioRisultato;
	   end if;
    end if;

    -- dani 19/01/2015: lettura codifiche 'fisse' all'interno del ciclo
	begin
code := 'MOVGEST_IMPEGNI ['||MOVGEST_IMPEGNI||']';
		select tipoMovGest.movgest_tipo_id into strict movgestTipoImpId
		from siac_d_movgest_tipo tipoMovGest
		       where tipoMovGest.movgest_tipo_code=MOVGEST_IMPEGNI and
			     tipoMovGest.data_cancellazione is null and
			     date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
					or tipoMovGest.validita_fine is null) and
			     tipoMovGest.ente_proprietario_id=enteProprietarioId;
code := 'MOVGEST_TS_IMPEGNI ['||MOVGEST_TS_IMPEGNI||']';
		select tipoMovGest.movgest_ts_tipo_id into strict movgestTipoTsImpId
		from siac_d_movgest_ts_tipo tipoMovGest
		     where tipoMovGest.ente_proprietario_id=enteProprietarioId and
			   tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_IMPEGNI and
			   tipoMovGest.data_cancellazione is null and
			   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
				      or tipoMovGest.validita_fine is null);

code := 'MOVGEST_TS_SUBIMP ['||MOVGEST_TS_SUBIMP||']';
		select tipoMovGest.movgest_ts_tipo_id into strict movgestTipoTsSubImpId
		from siac_d_movgest_ts_tipo tipoMovGest
		where tipoMovGest.ente_proprietario_id=enteProprietarioId and
			tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_SUBIMP and
			tipoMovGest.data_cancellazione is null and
			date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			(date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)or tipoMovGest.validita_fine is null);
code := 'STATO_VALIDO ['||STATO_VALIDO||']';
      select elem_stato_id into strict idStatoValido
      from siac_d_bil_elem_stato
          where ente_proprietario_id = enteProprietarioId
          and elem_stato_code=STATO_VALIDO
          and data_cancellazione is null
          and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
               or validita_fine is null);
code := 'tipoCapitoloGestUsc ['||tipoCapitoloGestUsc||']';
    	select tipoCapitolo.elem_tipo_id into strict idTipoCapitoloGestUsc
        from  siac_d_bil_elem_tipo tipoCapitolo
        where tipoCapitolo.ente_proprietario_id=enteProprietarioId and
        tipoCapitolo.elem_tipo_code=tipoCapitoloGestUsc;
code := 'IMPORTO_INIZIALE ['||IMPORTO_INIZIALE||']';
	  select movgest_ts_det_tipo_id into strict idImportoIniziale
      from siac_d_movgest_ts_det_tipo tipoImporto
      where tipoImporto.ente_proprietario_id=enteProprietarioId and
            tipoImporto.movgest_ts_det_tipo_code=IMPORTO_INIZIALE and
            tipoImporto.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoImporto.validita_fine)
	 	              or tipoImporto.validita_fine is null);
code := 'IMPORTO_ATTUALE ['||IMPORTO_ATTUALE||']';
	  select movgest_ts_det_tipo_id into strict idImportoAttuale
      from siac_d_movgest_ts_det_tipo tipoImporto
      where tipoImporto.ente_proprietario_id=enteProprietarioId and
            tipoImporto.movgest_ts_det_tipo_code=IMPORTO_ATTUALE and
            tipoImporto.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoImporto.validita_fine)
	 	              or tipoImporto.validita_fine is null);

	-- attributi
         --anno_capitolo_orig, numero_capitolo_orig, numero_articolo_orig, numero_ueb_orig
code := 'ANNOCAP_ORIG_IMP_ATTR ['||ANNOCAP_ORIG_IMP_ATTR||']';
      select  attrMovGest.attr_id into strict idAttr_annoCapOrig
      from siac_t_attr attrMovGest
      where attrMovGest.ente_proprietario_id=enteProprietarioId and
            attrMovGest.attr_code= ANNOCAP_ORIG_IMP_ATTR and
            attrMovGest.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
           (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
                      or attrMovGest.validita_fine is null);
code := 'NROCAP_ORIG_IMP_ATTR ['||NROCAP_ORIG_IMP_ATTR||']';
      select  attrMovGest.attr_id into strict idAttr_numCapOrigine
      from siac_t_attr attrMovGest
      where attrMovGest.ente_proprietario_id=enteProprietarioId and
            attrMovGest.attr_code= NROCAP_ORIG_IMP_ATTR and
            attrMovGest.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
                      or attrMovGest.validita_fine is null);
code := 'NROART_ORIG_IMP_ATTR ['||NROART_ORIG_IMP_ATTR||']';
		select  attrMovGest.attr_id into strict idAttr_numArtOrigine
           from siac_t_attr attrMovGest
           where attrMovGest.ente_proprietario_id=enteProprietarioId and
                 attrMovGest.attr_code= NROART_ORIG_IMP_ATTR and
                 attrMovGest.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
				 (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);
code := 'UEB_ORIG_IMP_ATTR ['||UEB_ORIG_IMP_ATTR||']';
		select  attrMovGest.attr_id into strict idAttr_numUebOrigine
            from siac_t_attr attrMovGest
            where attrMovGest.ente_proprietario_id=enteProprietarioId and
                  attrMovGest.attr_code= UEB_ORIG_IMP_ATTR and
                  attrMovGest.data_cancellazione is null and
	              date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);
code := 'NOTE_IMP_ATTR ['||NOTE_IMP_ATTR||']';
        select  attrMovGest.attr_id into strict idAttr_noteMovgest
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NOTE_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);

code := 'ANNOIMP_PLUR_IMP_ATTR ['||ANNOIMP_PLUR_IMP_ATTR||']';
		select  attrMovGest.attr_id into strict idAttr_annoOrigPlur
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOIMP_PLUR_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);
code := 'NIMP_PLUR_IMP_ATTR ['||NIMP_PLUR_IMP_ATTR||']';
		select  attrMovGest.attr_id into strict idAttr_numOrigPlur
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NIMP_PLUR_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);

code := 'ANNOIMP_RIACC_IMP_ATTR ['||ANNOIMP_RIACC_IMP_ATTR||']';
         select  attrMovGest.attr_id into strict idAttr_annoRiaccertato
         from siac_t_attr attrMovGest
         where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOIMP_RIACC_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);
code := 'NIMP_RIACC_IMP_ATTR ['||NIMP_RIACC_IMP_ATTR||']';
  		 select attrMovGest.attr_id into strict idAttr_numRiaccertato
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NIMP_RIACC_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);
code := 'FLAG_RIACC_IMP_ATTR ['||FLAG_RIACC_IMP_ATTR||']';
		 select attrMovGest.attr_id into strict idAttr_flagDaRiaccertamento
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= FLAG_RIACC_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null);
code := 'TIPO_IMPEGNO_CLASS ['||TIPO_IMPEGNO_CLASS||']';
		select tipoImpegno.classif_tipo_id into strict idTipoImpegnoClass
        from siac_d_class_tipo tipoImpegno
		where tipoImpegno.ente_proprietario_id=enteProprietarioId
        and tipoImpegno.classif_tipo_code=TIPO_IMPEGNO_CLASS
        and tipoImpegno.data_cancellazione is null
        and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImpegno.validita_inizio) and
	 	(date_trunc('day',dataElaborazione)<=date_trunc('day',tipoImpegno.validita_fine)
			            or tipoImpegno.validita_fine is null);
code := 'STATO_VALIDO ['||STATO_VALIDO||']';
        select progrStato.programma_stato_id into strict idStatovalidoProgramma
        from siac_d_programma_stato progrStato
        where progrStato.programma_stato_code=STATO_VALIDO and
		progrStato.ente_proprietario_id=enteProprietarioId
        and progrStato.data_cancellazione is null
        and date_trunc('day',dataElaborazione)>=date_trunc('day',progrStato.validita_inizio) and
	 	(date_trunc('day',dataElaborazione)<=date_trunc('day',progrStato.validita_fine)
			            or progrStato.validita_fine is null);
code := 'CUP_IMP_ATTR ['||CUP_IMP_ATTR||']';
        select attrMovGest.attr_id into strict idAttr_cup
		from siac_t_attr attrMovGest
        where attrMovGest.ente_proprietario_id=enteProprietarioId and
              attrMovGest.attr_code= CUP_IMP_ATTR and
              attrMovGest.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
                 or attrMovGest.validita_fine is null);
code := 'CIG_IMP_ATTR ['||CIG_IMP_ATTR||']';
     	select  attrMovGest.attr_id into strict idAttr_cig
        from siac_t_attr attrMovGest
      	where attrMovGest.ente_proprietario_id=enteProprietarioId and
            attrMovGest.attr_code= CIG_IMP_ATTR and
            attrMovGest.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		(date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			          or attrMovGest.validita_fine is null);
code := 'PDC_FIN_V_LIV ['||PDC_FIN_V_LIV||']';
		select tipoPdcFin.classif_tipo_id into strict idClass_pdc
        from siac_d_class_tipo tipoPdcFin
    	      where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=PDC_FIN_V_LIV
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);
--code := 'DIVISIONE_COFOG ['||DIVISIONE_COFOG||']';
code := 'GRUPPO_COFOG ['||GRUPPO_COFOG||']';
		select tipoCofog.classif_tipo_id into strict idClass_cofog
        from siac_d_class_tipo tipoCofog
    	      where tipoCofog.ente_proprietario_id=enteProprietarioId and
	                tipoCofog.classif_tipo_code=GRUPPO_COFOG--DIVISIONE_COFOG
                    and tipoCofog.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCofog.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoCofog.validita_fine)
                       or tipoCofog.validita_fine is null);
code := 'PERIMETRO_SANITARIO_SPESA ['||PERIMETRO_SANITARIO_SPESA||']';
        select tipoSanita.classif_tipo_id into strict idClass_tipoSanita
		from siac_d_class_tipo tipoSanita
    	      where tipoSanita.ente_proprietario_id=enteProprietarioId and
	                tipoSanita.classif_tipo_code=PERIMETRO_SANITARIO_SPESA
                    and tipoSanita.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSanita.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSanita.validita_fine)
                       or tipoSanita.validita_fine is null);

		-- 20.11.2015 Davide gestione siope
code := 'CL_SIOPE ['||CL_SIOPE||']';
        select tipoSiope.classif_tipo_id into strict idClass_siope
        from siac_d_class_tipo tipoSiope
              where tipoSiope.ente_proprietario_id=enteProprietarioId and
                    tipoSiope.classif_tipo_code=CL_SIOPE
                    and tipoSiope.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSiope.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSiope.validita_fine)
                       or tipoSiope.validita_fine is null);

		-- 03.03.2016 Davide aggiunta lettura altri attributi impegni
code := 'SPESA_RICORRENTE ['||SPESA_RICORRENTE||']';
        select tipoSpesaRicorrente.classif_tipo_id into strict idClass_tipoSpesaRicorrente
        from siac_d_class_tipo tipoSpesaRicorrente
              where tipoSpesaRicorrente.ente_proprietario_id=enteProprietarioId and
                    tipoSpesaRicorrente.classif_tipo_code=SPESA_RICORRENTE
                    and tipoSpesaRicorrente.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSpesaRicorrente.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSpesaRicorrente.validita_fine)
                       or tipoSpesaRicorrente.validita_fine is null);
code := 'TRANSAZIONE_UE_SPESA ['||TRANSAZIONE_UE_SPESA||']';
        select tipoTransazioneUeSpesa.classif_tipo_id into strict idClass_tipoTransazioneUeSpesa
        from siac_d_class_tipo tipoTransazioneUeSpesa
              where tipoTransazioneUeSpesa.ente_proprietario_id=enteProprietarioId and
                    tipoTransazioneUeSpesa.classif_tipo_code=TRANSAZIONE_UE_SPESA
                    and tipoTransazioneUeSpesa.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoTransazioneUeSpesa.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoTransazioneUeSpesa.validita_fine)
                       or tipoTransazioneUeSpesa.validita_fine is null);
code := 'POLITICHE_REGIONALI_UNITARIE ['||POLITICHE_REGIONALI_UNITARIE||']';
        select tipoPoliticheRegionaliUnitarie.classif_tipo_id into strict idClass_tipoPoliticheRegionaliUnitarie
        from siac_d_class_tipo tipoPoliticheRegionaliUnitarie
              where tipoPoliticheRegionaliUnitarie.ente_proprietario_id=enteProprietarioId and
                    tipoPoliticheRegionaliUnitarie.classif_tipo_code=POLITICHE_REGIONALI_UNITARIE
                    and tipoPoliticheRegionaliUnitarie.data_cancellazione is null and
                    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPoliticheRegionaliUnitarie.validita_inizio) and
                    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPoliticheRegionaliUnitarie.validita_fine)
                       or tipoPoliticheRegionaliUnitarie.validita_fine is null);

	exception
		when no_data_found then
			RAISE EXCEPTION 'Code cercato % non presente in archivio',code;
		when others  THEN
			RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;
    -- fine dani


    for migrImpegno IN
    (select ms.*
     from migr_impegno ms
	 where ms.ente_proprietario_id=enteProprietarioId and
     	   ms.tipo_movimento = tipoMovGestUsc and
           ms.fl_elab='N'
           and ms.migr_impegno_id >= idMin and ms.migr_impegno_id <=idMax
     order by ms.migr_impegno_id
     )
    loop
        -- Id dati ricavati per inserimento relazioni
        capitoloId:=0;
        soggettoId:=0;
        soggettoClasseId:=0;
	movgestTsPadreId:=0;
        movgestId :=0;
        movgestTsId:=0;

        -- Davide - 31.05.2016 - richiesta Annalina Vitelli
		--                       sono arrivati movimenti pluriennali con importi diversi
		if migrImpegno.importo_iniziale != migrImpegno.importo_attuale then
		    migrImpegno.importo_iniziale := migrImpegno.importo_attuale;
        end if;

      --Sofia 20.11.014 Non forziamo articolo=0 prendiamo quello migrato, forzatura fatta lato Oracle
      -- if enteProprietarioid in (ENTE_REGP_GIUNTA,ENTE_REGP_AIPO) then
	  --     migrImpegno.numero_articolo=0; -- articolo 0 fisso poiche per giunta e aipo non sono stati portati gli articoli
      --  end if;

      -- 19.11.014 Sofia -- tolto questo controllo il numero ueb deve essere valorizzato sulla migr
      -- if enteProprietarioid!=ENTE_COTO then
	  --     migrImpegno.numero_ueb='1';
      --  end if;

		if tipoMovGestUsc=MOVGEST_IMPEGNI then
		   	strMessaggio:='Inserimento siac_t_movgest migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
    	    -- siac_t_movgest
			/*INSERT INTO siac_t_movgest
			( movgest_anno, movgest_numero, movgest_desc, movgest_tipo_id, bil_id,
			  validita_inizio, ente_proprietario_id, data_creazione, login_operazione
			)
			(select migrImpegno.anno_impegno::numeric, migrImpegno.numero_impegno,migrImpegno.descrizione,
        			tipoMovGest.movgest_tipo_id,bilancioId,
	        	    date_trunc('day', migrImpegno.data_emissione::timestamp ),enteProprietarioid,CURRENT_TIMESTAMP,loginOperazione
	         from siac_d_movgest_tipo tipoMovGest
    	     where tipoMovGest.movgest_tipo_code=MOVGEST_IMPEGNI and
	    	       tipoMovGest.data_cancellazione is null and
            	   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
				   (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
				              or tipoMovGest.validita_fine is null) and
                   tipoMovGest.ente_proprietario_id=enteProprietarioId
        	)*/
            INSERT INTO siac_t_movgest
			(movgest_anno, movgest_numero, movgest_desc, movgest_tipo_id, bil_id,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, parere_finanziario)
            values
            (cast(migrImpegno.anno_impegno as INTEGER)
            -- migrImpegno.anno_impegno::numeric [commentatoo per errore di compilazione]
            ,migrImpegno.numero_impegno,migrImpegno.descrizione,
        	 movgestTipoImpId,bilancioId
             ,date_trunc('day', migrImpegno.data_emissione::timestamp )
             ,enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione
             ,migrImpegno.parere_finanziario::boolean)
	        returning movgest_id into movgestId;
       ELSE
       	begin
            strMessaggio:='Lettura siac_t_movgest migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
        	--select coalesce( movGest.movgest_id,0 ) into strict movgestId
            /*select movGest.movgest_id into strict movgestId
            from siac_t_movgest movGest, siac_d_movgest_tipo movGestTipo
            where movGest.ente_proprietario_id=enteProprietarioId and
                  movGest.bil_id=bilancioId and
                  movGestTipo.movgest_tipo_id=movGest.movgest_tipo_id and
                  movGestTipo.movgest_tipo_code=MOVGEST_IMPEGNI and
                  movGestTipo.ente_proprietario_id=enteProprietarioId and
                  movGestTipo.data_cancellazione is null and
            	   date_trunc('day',dataElaborazione)>=date_trunc('day',movGestTipo.validita_inizio) and
				   (date_trunc('day',dataElaborazione)<=date_trunc('day',movGestTipo.validita_fine)
				              or movGestTipo.validita_fine is null) and
                  movGest.movgest_anno= migrImpegno.anno_impegno::numeric and
                  movGest.movgest_numero=migrImpegno.numero_impegno;*/

		select movGest.movgest_id into strict movgestId
            from siac_t_movgest movGest
            where movGest.ente_proprietario_id=enteProprietarioId and
                  movGest.bil_id=bilancioId and
                  movGest.movgest_tipo_id=movgestTipoImpId and
                  movGest.movgest_anno= migrImpegno.anno_impegno::numeric and
                  movGest.movgest_numero=migrImpegno.numero_impegno;

             exception
	         	when no_data_found then
				  RAISE EXCEPTION 'Impegno non presente in archivio';
            	when others  THEN
	              RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;
       end if;

       -- siac_t_movgest_ts
  	   if tipoMovGestUsc=MOVGEST_IMPEGNI then
        strMessaggio:='Inserimento siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
       	/*INSERT INTO siac_t_movgest_ts
	    (  movgest_ts_code,  movgest_id, movgest_ts_tipo_id,
		   livello,  validita_inizio, ente_proprietario_id, data_creazione, login_operazione,
           login_creazione, movgest_ts_scadenza_data
	   	)
	    (select ltrim(rtrim(to_char(migrImpegno.numero_impegno,'999999'))),movgestId,tipoMovGest.movgest_ts_tipo_id,
	           MOVGEST_IMPEGNI_LIV,CURRENT_TIMESTAMP,enteProprietarioid,CURRENT_TIMESTAMP,loginOperazione,
               loginOperazione,date_trunc('day', migrImpegno.data_scadenza::timestamp )
         from siac_d_movgest_ts_tipo tipoMovGest
         where tipoMovGest.ente_proprietario_id=enteProprietarioId and
         	   tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_IMPEGNI and
	           tipoMovGest.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
			              or tipoMovGest.validita_fine is null)
         )*/

		INSERT INTO siac_t_movgest_ts
	    (  movgest_ts_code,  movgest_id, movgest_ts_tipo_id,movgest_ts_desc,
		   livello,  validita_inizio, ente_proprietario_id, data_creazione, login_operazione,
           login_creazione, movgest_ts_scadenza_data
	   	)
        values
        (migrImpegno.numero_impegno::varchar
        ,movgestId, movgestTipoTsImpId
        ,migrImpegno.descrizione -- 27.01.2016 Sofia
        ,MOVGEST_IMPEGNI_LIV
        ,dataInizioVal, enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione,loginOperazione
		,date_trunc('day', migrImpegno.data_scadenza::timestamp )
        )
         returning movgest_ts_id into movgestTsId;
       else
           strMessaggio:='Lettura siac_t_movgest_ts id_padre migr_impegno_id= '||migrImpegno.migr_impegno_id||', movGestTsPadre.movgest_id='||movgestId||'.';
           /*select movGestTsPadre.movgest_ts_id into movgestTsPadreId
           from siac_t_movgest_ts movGestTsPadre,siac_d_movgest_ts_tipo tipoMovGest
           where movGestTsPadre.ente_proprietario_id=enteProprietarioId and
           		 movGestTsPadre.movgest_id=movgestId and
                 tipoMovGest.ente_proprietario_id=enteProprietarioId and
         	     tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_IMPEGNI and
	             tipoMovGest.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
			              or tipoMovGest.validita_fine is null);*/
	   --begin
		   select movGestTsPadre.movgest_ts_id into strict movgestTsPadreId
		     from siac_t_movgest_ts movGestTsPadre
		     where movGestTsPadre.movgest_id=movgestId
		     and movgest_ts_id_padre is null;
	 /*exception
	 when too_many_rows then
		select count(*) into v_count
		from siac_t_movgest_ts movGestTsPadre where movGestTsPadre.movgest_id=movgestId;
		RAISE EXCEPTION 'Davvero troppi record su siac_t_movgest_ts per movgest_id = %, count(*) = %',movgestId,v_count;
	 end;*/

           strMessaggio:='Inserimento siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';

	       /*INSERT INTO siac_t_movgest_ts
		   (  movgest_ts_code,  movgest_id, movgest_ts_id_padre, movgest_ts_tipo_id,
			  livello,movgest_ts_desc, validita_inizio, ente_proprietario_id, data_creazione, login_operazione,
              login_creazione, movgest_ts_scadenza_data
	   	   )
	       (select rtrim(ltrim(to_char(migrImpegno.numero_subimpegno,'999999'))),
	       movgestId,
	       movgestTsPadreId,tipoMovGest.movgest_ts_tipo_id,
		           MOVGEST_SUBIMP_LIV,migrImpegno.descrizione,date_trunc('day', migrImpegno.data_emissione::timestamp ),enteProprietarioid,CURRENT_TIMESTAMP,loginOperazione,
    	           loginOperazione,date_trunc('day', migrImpegno.data_scadenza::timestamp )
            from siac_d_movgest_ts_tipo tipoMovGest
            where tipoMovGest.ente_proprietario_id=enteProprietarioId and
            	  tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_SUBIMP and
	              tipoMovGest.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			      (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
			              or tipoMovGest.validita_fine is null)
            )*/

			INSERT INTO siac_t_movgest_ts
             (  movgest_ts_code,  movgest_id, movgest_ts_id_padre, movgest_ts_tipo_id,
                livello,movgest_ts_desc, validita_inizio, ente_proprietario_id, data_creazione, login_operazione,
                login_creazione, movgest_ts_scadenza_data
             )
            values
            (migrImpegno.numero_subimpegno::varchar,movgestId,movgestTsPadreId,movgestTipoTsSubImpId,
            MOVGEST_SUBIMP_LIV,migrImpegno.descrizione,date_trunc('day', migrImpegno.data_emissione::timestamp ),enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione,
    	    loginOperazione,date_trunc('day', migrImpegno.data_scadenza::timestamp ))
            returning movgest_ts_id into movgestTsId;

       end if;

	if tipoMovGestUsc=MOVGEST_IMPEGNI then
         -- capitolo-ueb
         strMessaggio:='Lettura elemento di bilancio per  siac_t_movgest migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
         begin
         	/*select coalesce(bilCapitolo.elem_id,0)
               into strict capitoloId
            from siac_t_bil_elem bilCapitolo, siac_r_bil_elem_stato statoCapitoloRel,
            	 siac_d_bil_elem_stato statoCapitolo, siac_d_bil_elem_tipo tipoCapitolo
            where bilCapitolo.bil_id=bilancioId and
                  bilCapitolo.elem_code=ltrim(rtrim(to_char(migrImpegno.numero_capitolo,'999999'))) and
                  bilCapitolo.elem_code2= ltrim(rtrim(to_char(migrImpegno.numero_articolo,'999999'))) and
                  bilCapitolo.elem_code3= migrImpegno.numero_ueb and
                  bilCapitolo.ente_proprietario_id=enteProprietarioId and
                  bilCapitolo.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',bilCapitolo.validita_inizio) and
			      (date_trunc('day',dataElaborazione)<date_trunc('day',bilCapitolo.validita_fine)
			              or bilCapitolo.validita_fine is null) and
                  statoCapitoloRel.elem_id=bilCapitolo.elem_id and
                  statoCapitoloRel.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',statoCapitoloRel.validita_inizio) and
			      (date_trunc('day',dataElaborazione)<date_trunc('day',statoCapitoloRel.validita_fine)
			              or statoCapitoloRel.validita_fine is null) and
                  statoCapitolo.elem_stato_id=statoCapitoloRel.elem_stato_id and
                  statoCapitolo.ente_proprietario_id=enteProprietarioId and
                  statoCapitolo.elem_stato_code=STATO_VALIDO and
                  tipoCapitolo.elem_tipo_id=bilCapitolo.elem_tipo_id and
                  tipoCapitolo.ente_proprietario_id=enteProprietarioId and
                  tipoCapitolo.elem_tipo_code=tipoCapitoloGestUsc;*/
			select bilCapitolo.elem_id
               into strict capitoloId
            from siac_t_bil_elem bilCapitolo, siac_r_bil_elem_stato statoCapitoloRel
            where bilCapitolo.bil_id=bilancioId and
                  --bilCapitolo.elem_code=ltrim(rtrim(to_char(migrImpegno.numero_capitolo,'999999'))) and
                  --bilCapitolo.elem_code2= ltrim(rtrim(to_char(migrImpegno.numero_articolo,'999999'))) and
                  bilCapitolo.elem_code= migrImpegno.numero_capitolo::varchar and
                  bilCapitolo.elem_code2= migrImpegno.numero_articolo::varchar and
                  bilCapitolo.elem_code3= migrImpegno.numero_ueb and
                  bilCapitolo.ente_proprietario_id=enteProprietarioId and
                  bilCapitolo.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',bilCapitolo.validita_inizio) and
			      (date_trunc('day',dataElaborazione)<date_trunc('day',bilCapitolo.validita_fine)
			              or bilCapitolo.validita_fine is null) and
                  statoCapitoloRel.elem_id=bilCapitolo.elem_id and
                  statoCapitoloRel.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',statoCapitoloRel.validita_inizio) and
			      (date_trunc('day',dataElaborazione)<date_trunc('day',statoCapitoloRel.validita_fine)
			              or statoCapitoloRel.validita_fine is null) and
                  statoCapitoloRel.elem_stato_id=idStatoValido and
                  bilCapitolo.elem_tipo_id=idTipoCapitoloGestUsc;
          exception
         	when no_data_found then
			  RAISE EXCEPTION 'Elemento bilancio uscita %/% UEB % non presente in archivio',
              				   migrImpegno.numero_capitolo,migrImpegno.numero_articolo,migrImpegno.numero_ueb;
            when others  THEN
              RAISE EXCEPTION 'Errore per elem biancio uscita %/% UEB % : %-%.',
              			migrImpegno.numero_capitolo,migrImpegno.numero_articolo,migrImpegno.numero_ueb,
              			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
         end;

         if capitoloId !=0 then
            strMessaggio:='Inserimento relazione con elemento di bilancio per siac_t_movgest migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
         	INSERT INTO siac_r_movgest_bil_elem
			( movgest_id,elem_id, validita_inizio,
			  ente_proprietario_id,data_creazione,login_operazione)
            values
            (movgestId,capitoloId,dataInizioVal,enteProprietarioid,CLOCK_TIMESTAMP(),loginOperazione);
         end if;
	end if;

    -- stato
	strMessaggio:='Inserimento stato per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
    /*insert into siac_r_movgest_ts_stato
    ( movgest_ts_id, movgest_stato_id, validita_inizio,
	  ente_proprietario_id, data_creazione,login_operazione)
    (select movgestTsId, statoMovGest.movgest_stato_id,CURRENT_TIMESTAMP,
            enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
     from siac_d_movgest_stato statoMovGest
     where statoMovGest.ente_proprietario_id=enteProprietarioId and
       	   statoMovGest.movgest_stato_code=migrImpegno.stato_operativo and
           statoMovGest.data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',statoMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<date_trunc('day',statoMovGest.validita_fine)
			              or statoMovGest.validita_fine is null)
     );*/
	insert into siac_r_movgest_ts_stato
    ( movgest_ts_id, movgest_stato_id, validita_inizio,
	  ente_proprietario_id, data_creazione,login_operazione)
    (select movgestTsId, statoMovGest.movgest_stato_id,dataInizioVal,
            enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione
     from siac_d_movgest_stato statoMovGest
     where statoMovGest.ente_proprietario_id=enteProprietarioId and
       	   statoMovGest.movgest_stato_code=migrImpegno.stato_operativo and
           statoMovGest.data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',statoMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',statoMovGest.validita_fine)
			              or statoMovGest.validita_fine is null)
     );


     -- importi
     strMessaggio:='Inserimento importo inziale per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
     /*INSERT INTO siac_t_movgest_ts_det
	 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,
	   validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
     (select movgestTsId,tipoImporto.movgest_ts_det_tipo_id , migrImpegno.importo_iniziale,
             CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
      from siac_d_movgest_ts_det_tipo tipoImporto
      where tipoImporto.ente_proprietario_id=enteProprietarioId and
            tipoImporto.movgest_ts_det_tipo_code=IMPORTO_INIZIALE and
            tipoImporto.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<date_trunc('day',tipoImporto.validita_fine)
	 	              or tipoImporto.validita_fine is null)
      );*/
	 INSERT INTO siac_t_movgest_ts_det
	 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,
	   validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
     values
     	(movgestTsId, idImportoIniziale, migrImpegno.importo_iniziale,
             dataInizioVal,enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

      strMessaggio:='Inserimento importo attuale per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
      /*INSERT INTO siac_t_movgest_ts_det
		 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,
		   validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
         (select movgestTsId,tipoImporto.movgest_ts_det_tipo_id , migrImpegno.importo_attuale,
           	     CURRENT_TIMESTAMP,enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_d_movgest_ts_det_tipo tipoImporto
          where tipoImporto.ente_proprietario_id=enteProprietarioId and
                tipoImporto.movgest_ts_det_tipo_code=IMPORTO_ATTUALE and
                tipoImporto.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
			    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoImporto.validita_fine)
			              or tipoImporto.validita_fine is null)
         );*/
		INSERT INTO siac_t_movgest_ts_det
		 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,
		   validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
           VALUES
           (movgestTsId,idImportoAttuale,migrImpegno.importo_attuale,
           	     dataInizioVal,enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

	if tipoMovGestUsc=MOVGEST_IMPEGNI then
         -- attributi
         --anno_capitolo_orig, numero_capitolo_orig, numero_articolo_orig, numero_ueb_orig
       	 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                         ||' '||ANNOCAP_ORIG_IMP_ATTR||'.';

         /*INSERT INTO siac_r_movgest_ts_attr
	  	 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,migrImpegno.anno_capitolo_orig,
            	  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOCAP_ORIG_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

          INSERT INTO siac_r_movgest_ts_attr
	  	   ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
           values
           (movgestTsId, idAttr_annoCapOrig, migrImpegno.anno_capitolo_orig,
            	  dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

       	 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                         ||' '||NROCAP_ORIG_IMP_ATTR||'.';

/*         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,ltrim(rtrim(to_char(migrImpegno.numero_capitolo_orig,'999999'))),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NROCAP_ORIG_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
				(date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );
*/
          INSERT INTO siac_r_movgest_ts_attr
              ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
		  values
              (movgestTsId,idAttr_numCapOrigine,migrImpegno.numero_capitolo_orig::varchar,
                  dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

          strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                         ||' '||NROART_ORIG_IMP_ATTR||'.';

		  /*INSERT INTO siac_r_movgest_ts_attr
		  ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		    data_creazione, login_operazione )
          (select  movgestTsId,attrMovGest.attr_id,rtrim(ltrim(to_char(migrImpegno.numero_articolo_orig,'999999'))),
            	   CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
           from siac_t_attr attrMovGest
           where attrMovGest.ente_proprietario_id=enteProprietarioId and
                 attrMovGest.attr_code= NROART_ORIG_IMP_ATTR and
                 attrMovGest.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
				 (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
           );*/
          INSERT INTO siac_r_movgest_ts_attr
		  	( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
          values
            ( movgestTsId,idAttr_numArtOrigine,migrImpegno.numero_articolo_orig::varchar, dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

           strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||UEB_ORIG_IMP_ATTR||'.';
           /*INSERT INTO siac_r_movgest_ts_attr
		   ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		     data_creazione, login_operazione )
           (select  movgestTsId,attrMovGest.attr_id,migrImpegno.numero_ueb_orig,--ltrim(rtrim(to_char(migrImpegno.numero_ueb_orig,'999999'))),
           		    CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
            from siac_t_attr attrMovGest
            where attrMovGest.ente_proprietario_id=enteProprietarioId and
                  attrMovGest.attr_code= UEB_ORIG_IMP_ATTR and
                  attrMovGest.data_cancellazione is null and
	              date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
            );*/
          INSERT INTO siac_r_movgest_ts_attr
		   ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id, data_creazione, login_operazione )
           values
           (movgestTsId,idAttr_numUebOrigine, migrImpegno.numero_ueb_orig, dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

         --nota
		 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||NOTE_IMP_ATTR||'.';
         /*INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,substring(migrImpegno.nota from 1 for NOTE_IMP_LENGTH),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NOTE_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
		INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
         values
         (movgestTsId,idAttr_noteMovgest,substring(migrImpegno.nota from 1 for NOTE_IMP_LENGTH),dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

       	 --anno_impegno_plur, numero_impegno_plur
         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||ANNOIMP_PLUR_IMP_ATTR||'.';
		 /*
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,migrImpegno.anno_impegno_plur,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOIMP_PLUR_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
          INSERT INTO siac_r_movgest_ts_attr
		   ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
          VALUES
  	       ( movgestTsId,idAttr_annoOrigPlur,migrImpegno.anno_impegno_plur,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||NIMP_PLUR_IMP_ATTR||'.';

         /*INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,ltrim(rtrim(to_char(migrImpegno.numero_impegno_plur,'999999'))),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NIMP_PLUR_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

		 INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
         values
         (movgestTsId,idAttr_numOrigPlur,migrImpegno.numero_impegno_plur::varchar,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

         --anno_impegno_riacc, numero_impegno_riacc
         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||ANNOIMP_RIACC_IMP_ATTR||'.';
         /*INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,migrImpegno.anno_impegno_riacc,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOIMP_RIACC_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
        INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
         values
         (movgestTsId,idAttr_annoRiaccertato,migrImpegno.anno_impegno_riacc,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||NIMP_RIACC_IMP_ATTR||'.';

         /*INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,ltrim(rtrim(to_char(migrImpegno.numero_impegno_riacc,'999999'))),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NIMP_RIACC_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
        INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id, data_creazione, login_operazione )
         VALUES
         (movgestTsId,idAttr_numRiaccertato,migrImpegno.numero_impegno_riacc::varchar,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||FLAG_RIACC_IMP_ATTR||'.';
/*
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, boolean, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
         (select  movgestTsId,attrMovGest.attr_id,
                   CASE WHEN COALESCE(migrImpegno.numero_impegno_riacc,0)!=0
                   		THEN 'S' ELSE 'N' END,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= FLAG_RIACC_IMP_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

        if migrImpegno.numero_impegno_riacc is null or migrImpegno.numero_impegno_riacc = 0 then
        	boolean_value:= 'N';
        else
        	boolean_value:= 'S';
        end if;
		INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, boolean, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
		values
         (movgestTsId,idAttr_flagDaRiaccertamento,boolean_value,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

		 -- tipo impegno
         strMessaggio:='Inserimento relazione con classif tipo_impegno  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
		 /*INSERT INTO siac_r_movgest_class
		 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
		 )
         (select movgestTsId,tipoImpegnoClass.classif_id, CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_d_class_tipo tipoImpegno,  siac_t_class tipoImpegnoClass
          where tipoImpegnoClass.classif_code=migrImpegno.tipo_impegno and
          	    tipoImpegnoClass.ente_proprietario_id=enteProprietarioId and
                tipoImpegnoClass.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImpegnoClass.validita_inizio) and
	 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoImpegnoClass.validita_fine)
			            or tipoImpegnoClass.validita_fine is null) and
                tipoImpegno.classif_tipo_id=tipoImpegnoClass.classif_tipo_id and
				tipoImpegno.ente_proprietario_id=enteProprietarioId and
                tipoImpegno.classif_tipo_code=TIPO_IMPEGNO_CLASS);*/

		INSERT INTO siac_r_movgest_class
		 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
		 )
         (select movgestTsId,tipoImpegnoClass.classif_id, dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione
          from siac_t_class tipoImpegnoClass
          where tipoImpegnoClass.classif_code=migrImpegno.tipo_impegno and
          	    tipoImpegnoClass.ente_proprietario_id=enteProprietarioId and
                tipoImpegnoClass.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImpegnoClass.validita_inizio) and
	 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoImpegnoClass.validita_fine)
			            or tipoImpegnoClass.validita_fine is null) and
                tipoImpegnoClass.classif_tipo_id = idTipoImpegnoClass);

		 -- Opera
         if coalesce(migrImpegno.opera ,NVL_STR)=NVL_STR then
            strMessaggio:='Inserimento relazione con opera  per siac_t_movgest_ts migr_impegno_id= '
                           ||migrImpegno.migr_impegno_id||'.';
	         /*INSERT INTO siac_r_movgest_ts_programma
			 ( movgest_ts_id,  programma_id, validita_inizio, ente_proprietario_id,
			   data_creazione,login_operazione
			 )
    	     (select movgestTsId,programma.programma_id,CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
        	  from siac_t_programma programma , siac_r_programma_stato progrStatoRel,
          		   siac_d_programma_stato progrStato
	          where programma.ente_proprietario_id=enteProprietarioId and
    	            programma.programma_code=migrImpegno.opera and
        	        programma.data_cancellazione is not null and
            	    date_trunc('day',dataElaborazione)>=date_trunc('day',programma.validita_inizio) and
	 		    	(date_trunc('day',dataElaborazione)<date_trunc('day',programma.validita_fine)
			        	    or programma.validita_fine is null) and
	                progrStatoRel.programma_id=programma.programma_id and
    	            progrStato.programma_stato_id=progrStatoRel.programma_stato_id and
        	        progrStatoRel.data_cancellazione is not null and
            	    date_trunc('day',dataElaborazione)>=date_trunc('day',progrStatoRel.validita_inizio) and
	 		    	(date_trunc('day',dataElaborazione)<date_trunc('day',progrStatoRel.validita_fine)
				            or progrStatoRel.validita_fine is null) and
    	            progrStato.programma_stato_code=STATO_VALIDO and
        	        progrStato.ente_proprietario_id=enteProprietarioId);*/

	         INSERT INTO siac_r_movgest_ts_programma
			 ( movgest_ts_id,  programma_id, validita_inizio, ente_proprietario_id,data_creazione,login_operazione
			 )
    	     (select movgestTsId,programma.programma_id,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione
        	  from siac_t_programma programma , siac_r_programma_stato progrStatoRel
	          where programma.ente_proprietario_id=enteProprietarioId and
    	            programma.programma_code=migrImpegno.opera and
        	        programma.data_cancellazione is not null and
            	    date_trunc('day',dataElaborazione)>=date_trunc('day',programma.validita_inizio) and
	 		    	(date_trunc('day',dataElaborazione)<=date_trunc('day',programma.validita_fine)
			        	    or programma.validita_fine is null) and
	                progrStatoRel.programma_id=programma.programma_id and
    	            progrStatoRel.programma_stato_id = idStatovalidoProgramma and
        	        progrStatoRel.data_cancellazione is not null and
            	    date_trunc('day',dataElaborazione)>=date_trunc('day',progrStatoRel.validita_inizio) and
	 		    	(date_trunc('day',dataElaborazione)<date_trunc('day',progrStatoRel.validita_fine)
				            or progrStatoRel.validita_fine is null));
         end if;
    end if;

    --cup
	strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                          ||' '||CUP_IMP_ATTR||'.';
    /*INSERT INTO siac_r_movgest_ts_attr
	( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
	  data_creazione, login_operazione )
    (select  movgestTsId,attrMovGest.attr_id,migrImpegno.cup,
             CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
     from siac_t_attr attrMovGest
     where attrMovGest.ente_proprietario_id=enteProprietarioId and
           attrMovGest.attr_code= CUP_IMP_ATTR and
           attrMovGest.data_cancellazione is null and
	       date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
     );*/
    INSERT INTO siac_r_movgest_ts_attr
	( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
    values
    (movgestTsId,idAttr_cup,migrImpegno.cup,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

     --cig
     strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_impegno_id= '||migrImpegno.migr_impegno_id
                         ||' '||CIG_IMP_ATTR||'.';
/*     INSERT INTO siac_r_movgest_ts_attr
	 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
	   data_creazione, login_operazione )
     (select  movgestTsId,attrMovGest.attr_id,migrImpegno.cig,
              CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_attr attrMovGest
      where attrMovGest.ente_proprietario_id=enteProprietarioId and
            attrMovGest.attr_code= CIG_IMP_ATTR and
            attrMovGest.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		(date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			          or attrMovGest.validita_fine is null)
      );*/
	 INSERT INTO siac_r_movgest_ts_attr
	 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione)
     VALUES
     (movgestTsId,idAttr_cig,migrImpegno.cig,dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);

      -- soggetto
      if migrImpegno.soggetto_determinato='S' then
        	begin
				strMessaggio:='Lettura soggetto  migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';

--				soggettoId := 1;

            	select   coalesce(soggetto.soggetto_id,0) into strict soggettoId
                from siac_t_soggetto soggetto, migr_soggetto migrSoggetto,
                     siac_r_migr_soggetto_soggetto migrRelSoggetto
                where
	                migrSoggetto.fl_genera_codice = 'N' and
                	migrSoggetto.codice_soggetto=migrImpegno.codice_soggetto and
				      migrSoggetto.ente_proprietario_id=enteProprietarioId and
		       		  migrRelSoggetto.migr_soggetto_id=migrSoggetto.migr_soggetto_id AND
        			  migrRelSoggetto.soggetto_id = soggetto.soggetto_id and
                	  soggetto.ente_proprietario_id=enteProprietarioId and
                      soggetto.data_cancellazione is null and
		              date_trunc('day',dataElaborazione)>=date_trunc('day',soggetto.validita_inizio) and
	   	 		      (date_trunc('day',dataElaborazione)<=date_trunc('day',soggetto.validita_fine)
			              or soggetto.validita_fine is null);
         		exception
         		when no_data_found then
			 		 RAISE EXCEPTION 'Soggetto  codice=% non presente in archivio',
              				   migrImpegno.codice_soggetto;
           		 when others  THEN
             		 RAISE EXCEPTION 'Errore lettura soggetto codice=% : %-%.',
              			migrImpegno.codice_soggetto,
              			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

          end;

          if soggettoId!=0 then
	            strMessaggio:='Inserimento relazione con soggetto per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
            	INSERT INTO siac_r_movgest_ts_sog
				(movgest_ts_id,soggetto_id, validita_inizio,ente_proprietario_id, data_creazione,login_operazione)
				VALUES
                (movgestTsId,soggettoId, dataInizioVal, enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);
            end if;
      else  -- classe soggetto

      	    if tipoMovGestUsc!=MOVGEST_IMPEGNI  then
            	RAISE EXCEPTION 'Soggetto non determinato per subImpegno migr_impegno_id=%',
              				   migrImpegno.migr_impegno_id;
            end if;

            if   migrImpegno.soggetto_determinato='G' then
            	begin
		    strMessaggio:='Lettura classe soggetto in migr_classe  migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';

                	--select coalesce(migrClasseRel.soggetto_classe_id,0) into strict soggettoClasseId
                	select migrClasseRel.soggetto_classe_id into strict soggettoClasseId
                    from migr_classe migrClasse, siac_r_migr_classe_soggclasse migrClasseRel ,
                         siac_d_soggetto_classe soggClasse
                    where migrClasse.ente_proprietario_id=enteProprietarioId and
                          migrClasse.codice_soggetto=migrImpegno.codice_soggetto and
                          migrClasseRel.migr_classe_id=migrClasse.migr_classe_id and
                          soggClasse.soggetto_classe_id=migrClasseRel.soggetto_classe_id and
                          soggClasse.ente_proprietario_id=enteProprietarioId and
                          soggClasse.data_cancellazione is null and
			              date_trunc('day',dataElaborazione)>=date_trunc('day',soggClasse.validita_inizio) and
	   		 		      (date_trunc('day',dataElaborazione)<=date_trunc('day',soggClasse.validita_fine)
				              or soggClasse.validita_fine is null);

                exception
			when no_data_found then
				RAISE EXCEPTION 'Classe soggetto [Soggetto codice=% ] non presente in migr_classe',
              				   migrImpegno.codice_soggetto;
			when others  THEN
             			 RAISE EXCEPTION 'Errore lettura Classe [soggetto codice=%] in migr_classe: %-%.',
              				migrImpegno.codice_soggetto,
	              			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
                end;
            else
            	if COALESCE(migrImpegno.classe_soggetto,NVL_STR)!=NVL_STR then
	                strToElab:=migrImpegno.classe_soggetto;
			classeSoggettoCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        	        classeSoggettoDesc:=substring(strToElab from
						position(SEPARATORE in strToElab)+2
						for char_length(strToElab)-position(SEPARATORE in strToElab));
			begin
				strMessaggio:='Lettura classe soggetto  migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';

				--select coalesce(soggClasse.soggetto_classe_id,0) into strict soggettoClasseId
				select soggClasse.soggetto_classe_id into strict soggettoClasseId
				from siac_d_soggetto_classe soggClasse
				where soggClasse.soggetto_classe_code=classeSoggettoCode and
					  soggClasse.ente_proprietario_id=enteProprietarioId and
				      soggClasse.data_cancellazione is null and
					      date_trunc('day',dataElaborazione)>=date_trunc('day',soggClasse.validita_inizio) and
						      (date_trunc('day',dataElaborazione)<=date_trunc('day',soggClasse.validita_fine)
						      or soggClasse.validita_fine is null);

			exception
				when no_data_found then
					strMessaggio:='Inserimento classe soggetto  migr_impegno_id= '||migrImpegno.migr_impegno_id||'.';
					insert into siac_d_soggetto_classe
						( soggetto_classe_tipo_id,soggetto_classe_code,soggetto_classe_desc,validita_inizio,ambito_id,ente_proprietario_id,data_creazione,login_operazione)
					values
						( soggettoClasseTipoId,classeSoggettoCode,classeSoggettoDesc,dataInizioVal,ambitoId,enteProprietarioId,clock_timestamp(),loginOperazione)
					returning soggetto_classe_id into soggettoClasseId;

				 when others  THEN
					 RAISE EXCEPTION 'Errore lettura classe soggetto % : %-%.',classeSoggettoCode,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
			end;
                end if; -- classe_soggetto
            end if; -- G

           if soggettoClasseId!=0 then
	         strMessaggio:='Inserimento relazione con classe soggetto per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
             INSERT INTO siac_r_movgest_ts_sogclasse
			 ( movgest_ts_id,soggetto_classe_id, validita_inizio,
			   ente_proprietario_id, data_creazione,login_operazione)
				VALUES
                (
                 movgestTsId,soggettoClasseId, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
            end if;

     end if;   -- S

	 -- PdcFin - se indicato e di V livello
     if coalesce(migrImpegno.pdc_finanziario,NVL_STR)!=NVL_STR then
			 strMessaggio:='Inserimento relazione con PDC_FIN_V_LIV  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
			 /*INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoPdcFinClass.classif_id, CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
	          from siac_d_class_tipo tipoPdcFin,  siac_t_class tipoPdcFinClass
    	      where tipoPdcFinClass.classif_code=migrImpegno.pdc_finanziario and
        	  	    tipoPdcFinClass.ente_proprietario_id=enteProprietarioId and
            	    tipoPdcFinClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFinClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoPdcFinClass.validita_fine)
			            or tipoPdcFinClass.validita_fine is null) and
    	            tipoPdcFin.classif_tipo_id=tipoPdcFinClass.classif_tipo_id and
					tipoPdcFin.ente_proprietario_id=enteProprietarioId and
	                tipoPdcFin.classif_tipo_code=PDC_FIN_V_LIV);*/

			INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoPdcFinClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoPdcFinClass
    	      where tipoPdcFinClass.classif_code=migrImpegno.pdc_finanziario and
        	  	    tipoPdcFinClass.ente_proprietario_id=enteProprietarioId and
            	    tipoPdcFinClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFinClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFinClass.validita_fine)
			            or tipoPdcFinClass.validita_fine is null) and
    	            tipoPdcFinClass.classif_tipo_id = idClass_pdc);
      end if;

     -- TRB - al momento solo gestiti cofog e perimetro_sanitario_spesa
     -- missione,programma - da non inserire
     -- transazione_ue_spesa
     -- siope_spesa
     -- spesa_ricorrente
     -- politiche_regionali_unitarie
     -- pdc_economico_patr

	 -- cofog
     if coalesce(migrImpegno.cofog,NVL_STR)!=NVL_STR then
		 strMessaggio:='Inserimento relazione con COFOG  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
			 /*INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoCofogClass.classif_id, CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
	          from siac_d_class_tipo tipoCofog,  siac_t_class tipoCofogClass
    	      where tipoCofogClass.classif_code=migrImpegno.cofog and
        	  	    tipoCofogClass.ente_proprietario_id=enteProprietarioId and
            	    tipoCofogClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCofogClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoCofogClass.validita_fine)
			            or tipoCofogClass.validita_fine is null) and
    	            tipoCofog.classif_tipo_id=tipoCofogClass.classif_tipo_id and
					tipoCofog.ente_proprietario_id=enteProprietarioId and
	                tipoCofog.classif_tipo_code=DIVISIONE_COFOG);*/
			INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoCofogClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoCofogClass
    	      where tipoCofogClass.classif_code=migrImpegno.cofog and
        	  	    tipoCofogClass.ente_proprietario_id=enteProprietarioId and
            	    tipoCofogClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCofogClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoCofogClass.validita_fine)
			            or tipoCofogClass.validita_fine is null) and
    	            tipoCofogClass.classif_tipo_id=idClass_cofog);
     end if;

     -- perimetro_sanitario_spesa
     if coalesce(migrImpegno.perimetro_sanitario_spesa,NVL_STR)!=NVL_STR then
			 strMessaggio:='Inserimento relazione con PERIMETRO_SANITARIO_SPESA  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';

             /*INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoSanitaClass.classif_id, CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
	          from siac_d_class_tipo tipoSanita,  siac_t_class tipoSanitaClass
    	      where tipoSanitaClass.classif_code=migrImpegno.perimetro_sanitario_spesa and
        	  	    tipoSanitaClass.ente_proprietario_id=enteProprietarioId and
            	    tipoSanitaClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSanitaClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoSanitaClass.validita_fine)
			            or tipoSanitaClass.validita_fine is null) and
    	            tipoSanita.classif_tipo_id=tipoSanitaClass.classif_tipo_id and
					tipoSanita.ente_proprietario_id=enteProprietarioId and
	                tipoSanita.classif_tipo_code=PERIMETRO_SANITARIO_SPESA);*/
			INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoSanitaClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoSanitaClass
    	      where tipoSanitaClass.classif_code=migrImpegno.perimetro_sanitario_spesa and
        	  	    tipoSanitaClass.ente_proprietario_id=enteProprietarioId and
            	    tipoSanitaClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSanitaClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSanitaClass.validita_fine)
			            or tipoSanitaClass.validita_fine is null) and
    	            tipoSanitaClass.classif_tipo_id = idClass_tipoSanita);
     end if;

	 -- 27.11.2015 Davide gestione siope
     begin
	 -- Cerca se l'Ente ha il SIOPE di default e prendi quello se esiste
		 select classif.classif_code into strict classif_siope_code
		   from siac_t_class classif, siac_d_class_tipo classTipo
   		  where classif.ente_proprietario_id=enteproprietarioid
		    and classif.classif_code=SIOPECOD_DEF
            and classif.data_cancellazione is null
	        and date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio)
	        and (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now())))
            and classTipo.classif_tipo_id=classif.classif_tipo_id
            and classTipo.classif_tipo_code=CL_SIOPE
            and classTipo.data_cancellazione is null
	        and date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio)
	        and (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));
	 exception
       	 when NO_DATA_FOUND  THEN
	         -- se non si trova, vai a prendere quello migrato, se esiste....
	         if coalesce(migrImpegno.siope_spesa,NVL_STR)!=NVL_STR then
	             classif_siope_code := migrImpegno.siope_spesa;
	         else
	             begin
			         --... altrimenti lo leggi dal movimento a cui è collegato
                     if tipoMovGestUsc=MOVGEST_IMPEGNI then
                         strMessaggio:='Lettura del SIOPE dal capitolo di uscita collegato.';
   	                     select tipi_class.classif_code into strict classif_siope_code
		                   from siac_t_class tipi_class, siac_r_bil_elem_class relaz_capclass
                          where relaz_capclass.ente_proprietario_id=enteproprietarioid
                            and tipi_class.ente_proprietario_id=relaz_capclass.ente_proprietario_id
                            and relaz_capclass.elem_id=capitoloId
			                and tipi_class.classif_tipo_id=idClass_siope
			                and tipi_class.classif_id=relaz_capclass.classif_id;
	                 else
                         strMessaggio:='Lettura del SIOPE dall'' impegno collegato.';
  	                     select tipi_class.classif_code into strict classif_siope_code
			               from siac_t_class tipi_class, siac_r_movgest_class relaz_impclass
                          where relaz_impclass.ente_proprietario_id=enteproprietarioid
                            and tipi_class.ente_proprietario_id=relaz_impclass.ente_proprietario_id
							-- Dani 25.01.2016 Il siope e legato al subimpegno testata dell'impegno non all'impegno stesso
                            --and relaz_impclass.movgest_ts_id=movgestId
                            and relaz_impclass.movgest_ts_id=movgestTsPadreId
			                and tipi_class.classif_tipo_id=idClass_siope
			                and tipi_class.classif_id=relaz_impclass.classif_id;
 	                 end if;

		         exception
           	         when others  THEN
		                 classif_siope_code := '';
		         end;
             end if;
	 end;

	if coalesce(classif_siope_code,NVL_STR)!=NVL_STR then
         strMessaggio:='Inserimento relazione con SIOPE su siac_r_movgest_class.';

         INSERT INTO siac_r_movgest_class
		 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
		 )
		 (select movgestTsId,classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	        from siac_t_class
    	   where classif_code=classif_siope_code and
           	     ente_proprietario_id=enteProprietarioId and
            	 data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
		 		 (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
			            or validita_fine is null) and
    	         classif_tipo_id = idClass_siope);
	else
	    -- segnalazione di relazione non inserita per mancanza totale del SIOPE
 		RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento Codice SIOPE!!!';
    end if;

	-- 03.03.2016 Davide aggiunta lettura altri attributi impegni
    -- transazione_ue_spesa
    if coalesce(migrImpegno.transazione_ue_spesa,NVL_STR)!=NVL_STR then
		 strMessaggio:='Inserimento relazione con TRANSAZIONE_UE_SPESA  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
		INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoTransazioneUeSpesaClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoTransazioneUeSpesaClass
    	      where tipoTransazioneUeSpesaClass.classif_code=migrImpegno.transazione_ue_spesa and
        	  	    tipoTransazioneUeSpesaClass.ente_proprietario_id=enteProprietarioId and
            	    tipoTransazioneUeSpesaClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoTransazioneUeSpesaClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoTransazioneUeSpesaClass.validita_fine)
			            or tipoTransazioneUeSpesaClass.validita_fine is null) and
    	            tipoTransazioneUeSpesaClass.classif_tipo_id = idClass_tipoTransazioneUeSpesa);
	--else
	    -- segnalazione di relazione non inserita per mancanza totale del campo TRANSAZIONE_UE_SPESA
 		--RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento TRANSAZIONE_UE_SPESA !!!';
    end if;
    -- spesa_ricorrente
    if coalesce(migrImpegno.spesa_ricorrente,NVL_STR)!=NVL_STR then
		 strMessaggio:='Inserimento relazione con SPESA_RICORRENTE  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
		INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoSpesaRicorrenteClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoSpesaRicorrenteClass
    	      where tipoSpesaRicorrenteClass.classif_code=migrImpegno.spesa_ricorrente and
        	  	    tipoSpesaRicorrenteClass.ente_proprietario_id=enteProprietarioId and
            	    tipoSpesaRicorrenteClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSpesaRicorrenteClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoSpesaRicorrenteClass.validita_fine)
			            or tipoSpesaRicorrenteClass.validita_fine is null) and
    	            tipoSpesaRicorrenteClass.classif_tipo_id = idClass_tipoSpesaRicorrente);
	--else
	    -- segnalazione di relazione non inserita per mancanza totale del campo SPESA_RICORRENTE
 		--RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento SPESA_RICORRENTE !!!';
    end if;
    -- politiche_regionali_unitarie
    if coalesce(migrImpegno.politiche_regionali_unitarie,NVL_STR)!=NVL_STR then
		 strMessaggio:='Inserimento relazione con POLITICHE_REGIONALI_UNITARIE  per siac_t_movgest_ts migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
		INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
        	 (select movgestTsId,tipoPoliticheRegionaliUnitarieClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoPoliticheRegionaliUnitarieClass
    	      where tipoPoliticheRegionaliUnitarieClass.classif_code=migrImpegno.politiche_regionali_unitarie and
        	  	    tipoPoliticheRegionaliUnitarieClass.ente_proprietario_id=enteProprietarioId and
            	    tipoPoliticheRegionaliUnitarieClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPoliticheRegionaliUnitarieClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPoliticheRegionaliUnitarieClass.validita_fine)
			            or tipoPoliticheRegionaliUnitarieClass.validita_fine is null) and
    	            tipoPoliticheRegionaliUnitarieClass.classif_tipo_id = idClass_tipoPoliticheRegionaliUnitarie);
	--else
	    -- segnalazione di relazione non inserita per mancanza totale del campo POLITICHE_REGIONALI_UNITARIE
 		--RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento POLITICHE_REGIONALI_UNITARIE !!!';
    end if;

	if tipoMovGestUsc=MOVGEST_IMPEGNI then
     	 -- classificatori
         -- CLASSIFICATORE_11
		 if coalesce(migrImpegno.classificatore_1,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrImpegno.classificatore_1||'.';
            strToElab:=migrImpegno.classificatore_1;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_11,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;

		 -- CLASSIFICATORE_12
		 if coalesce(migrImpegno.classificatore_2,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrImpegno.classificatore_2||'.';
			strToElab:=migrImpegno.classificatore_2;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_12,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;
		 -- CLASSIFICATORE_13
		 if coalesce(migrImpegno.classificatore_3,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrImpegno.classificatore_3||'.';
			strToElab:=migrImpegno.classificatore_3;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_13,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;
		 -- CLASSIFICATORE_14
		 if coalesce(migrImpegno.classificatore_4,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrImpegno.classificatore_4||'.';
			strToElab:=migrImpegno.classificatore_4;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_14,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;

		 -- CLASSIFICATORE_15
		 if coalesce(migrImpegno.classificatore_5,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrImpegno.classificatore_5||'.';
			strToElab:=migrImpegno.classificatore_5;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_15,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            							          if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;
  end if;

  -- strAmm
  if coalesce(migrImpegno.numero_provvedimento,0)!=0 or
     migrImpegno.tipo_provvedimento=SPR then
	        strMessaggio:='Provvedimento.';
			select * into migrAttoAmmMovGest
            from fnc_migr_attoamm_movgest (migrImpegno.anno_provvedimento,migrImpegno.numero_provvedimento,
            							   migrImpegno.tipo_provvedimento,migrImpegno.direzione_provvedimento,
										   migrImpegno.oggetto_provvedimento,migrImpegno.note_provvedimento,
										   migrImpegno.stato_provvedimento,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione
                                           , dataInizioVal);

            if migrAttoAmmMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrAttoAmmMovGest.messaggioRisultato;
            end if;
   end if;

  strMessaggio:='Inserimento siac_r_migr_impegno_movgest_ts per migr_impegno_id= '
                               ||migrImpegno.migr_impegno_id||'.';
  insert into siac_r_migr_impegno_movgest_ts
  (migr_impegno_id,movgest_ts_id,ente_proprietario_id,data_creazione)
  values
  (migrImpegno.migr_impegno_id,movgestTsId,enteProprietarioId,clock_timestamp());

   numeroElementiInseriti:=numeroElementiInseriti+1;
  end loop;


   RAISE NOTICE 'NumeroImpegniInseriti %', numeroElementiInseriti;

   -- aggiornamento progressivi SOLO PER IMPEGNI
   if tipoMovGestUsc=MOVGEST_IMPEGNI then
   	select * into aggProgressivi
   	from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGestUsc, loginOperazione);

    if aggProgressivi.codresult=-1 then
    	RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
    end if;
   end if;

	-- valorizzare fl_elab = 'S'
    update migr_impegno set fl_elab='S'
    where ente_proprietario_id=enteProprietarioId and
               tipo_movimento = tipoMovGestUsc and
               fl_elab='N'
               and migr_impegno_id >= idMin and migr_impegno_id <=idMax;

   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' impegni.';
   numeroImpegniInseriti:= numeroElementiInseriti;

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroImpegniInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroImpegniInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;