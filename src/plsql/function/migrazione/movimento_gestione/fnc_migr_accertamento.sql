/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_accertamento (enteProprietarioId integer,
							annoBilancio in VARCHAR,
							tipoCapitoloGestEnt varchar,
							tipoMovGestEnt varchar,
							loginOperazione varchar,
							dataElaborazione timestamp,
							idmin integer,
							idmax integer,
							out numeroAccertamentiInseriti integer,
							out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_accertamento --> function che effettua il caricamento degli accertamenti/subaccertamenti migrati
    -- leggendo in tab migr_accertamento
      -- tipoMovGestEnt=A per caricamento accertamenti
      -- tipoMovGestEnt=S per caricamento subaccertamenti
    -- effettua inserimento di
     -- siac_t_movgest    -- per tipoMovGestEnt=A caricamento di accertamento
        -- siac_r_movgest_bil_elem - relazione rispetto al capitolo-ueb
     -- siac_t_movgest_ts -- per tipoMovGestEnt=A caricamento tipo=T
                          -- per tipoMovGestEnt=S caricamento tipo=S per caricamento del subaccertamento
                             -- relazionato attraverso movgest_ts_id_padre al tipo=T di accertamento padre
                          -- siac_r_movgest_ts_stato
    					  -- siac_t_movgest_ts_dett per importo iniale e importo attuale
                          -- siac_r_movgest_ts_attr per accertamento attributi
                             -- <annoCapitoloOrigine,numeroCapitoloOrigine,numeroArticoloOrigine,numeroUEBOrigine,
                             --  annoOriginePlur,numeroOriginePlur,
                             --  annoRiaccertamento,numeroRiaccertamento,flagDaRiaccertamento, note
                             --  ACC_AUTO (automatico) >
                          -- siac_r_movgest_ts_programma per accertamento collegamento con progetto-opera
                          -- siac_r_movgest_ts_sogg collegamento con soggetto
                           -- se migr_accertamento.soggetto_determinato='S' ( accertamento e subaccertamento )
                          -- siac_r_movgest_ts_soggclasse collegamento classe soggetto (dovrebbe essere solo per accertamento)
                             -- se migr_impegno.soggetto_determinato='G'
                             	-- cerca classe in migr_classe
                             -- se migr_impegno.soggetto_determinato='N'
                                -- ricava la classe dal campo migr_impegno.classe_soggetto
                          -- siac_r_migr_movgest_ts
                             -- inserimento della relazione tra migr_accertamento_id e mogest_ts_id
     -- richiama
     -- fnc_migr_aggiorna_classif (accertamento)
        -- per aggiornamento delle descrizioni dei classificatori caricati
        -- in migr_classif_impacc
     -- fnc_migr_classif_movgest (accertamento) per
        --  il caricamento dei classificatori generici <CLASSIFICATORE_16...._20>
        --  collegamento con accertamento
     -- fnc_migr_attoamm_movgest per
        --  il caricamento di atto amministrativo <classificatore tipo CDR > ( accertamento, subaccertamento)
    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroAccertamentiInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_accertamento
        -- -1 errore
        -- N=numero accertamenti-subaccertamenti inseriti

    -- Punti di attenzione
     -- TRB e PdcFIN : indicati in tracciato ma potrebbero non arrivare da sistema di origine
       -- al momento gestito solo PdcFin,  perimetro_sanitario
     -- Atto Amministrativo
       -- si controlla esistenza di atto proveniente dal sistema di origine
       -- se esiste lo si utilizza per collegarlo a accertamento,subaccertamento
       -- se non esiste lo si inserisce
       -- SPR (movimento interno ) -- movimento gestione senza provvedimento
         -- il numero se non passato dal sistema di origine sara impostato a 9999999

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	bilancioid integer:=0;

	migrAccertamento  record;
    migrAttoAmmMovGest record;
    migrClassifMovGest record;
	migrAggClassifAcc   record;
    aggProgressivi record;
    countMigrAccertamento integer:=0;


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

    -- dichiarazione variabili per fk lette una volta
    code varchar(200):='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
	--dataInizioVal timestamp :=annoBilancio||'-01-01';
	dataInizioVal timestamp :=null;

    id_movgesttipo integer := 0;
    id_movgesttstipoAcc integer := 0;
    id_movgesttstipoSacc integer := 0;
    id_statoValido integer := 0;
    id_tipoCapitoloGestEnt integer := 0;
    idImportoIniziale integer := 0; -- id siac_d_movgest_ts_det_tipo per code IMPORTO_INIZIALE
    idImportoAttuale integer := 0; -- id siac_d_movgest_ts_det_tipo per code IMPORTO_ATTUALE
    idImportoUtilizzabile integer := 0; -- id siac_d_movgest_ts_det_tipo per code IMPORTO_UTILIZZABILE -- Davide 06.06.2016 - aggiunta importo utilizzabile
    idAttr_annoCapOrig integer := 0; -- id siac_t_attr per code ANNOCAP_ORIG_ACC_ATTR
    idAttr_numCapOrigine integer := 0; -- id siac_t_attr per code NROCAP_ORIG_ACC_ATTR
    idAttr_numArtOrigine integer := 0; -- id siac_t_attr per code NROART_ORIG_ACC_ATTR
    idAttr_numUebOrigine integer := 0; -- id siac_t_attr per code UEB_ORIG_ACC_ATTR
    idAttr_noteMovgest  integer := 0; -- id siac_t_attr per code NOTE_ACC_ATTR
    idAttr_accAuto  integer := 0; -- id siac_t_attr per code ACC_AUTO_ACC_ATTR
    idAttr_annoOrigPlur integer := 0; -- id siac_t_attr per code ANNOACC_PLUR_ACC_ATTR
    idAttr_numOrigPlur integer := 0; -- id siac_t_attr per code NACC_PLUR_ACC_ATTR
    idAttr_annoRiaccertato integer := 0; -- id siac_t_attr per code ANNOACC_RIACC_ACC_ATTR
    idAttr_numRiaccertato  integer := 0; -- id siac_t_attr per code NACC_RIACC_ACC_ATTR
    idAttr_flagDaRiaccertamento integer := 0; -- id siac_t_attr per code FLAG_RIACC_ACC_ATTR
    idStatovalidoProgramma integer := 0; -- id siac_d_programma_stato per code STATO_VALIDO
    idClass_pdc integer := 0; -- id siac_d_class_tipo per code PDC_FIN_V_LIV
    idClass_tipoSanita integer:= 0;  -- id siac_d_class_tipo per code PERIMETRO_SANITARIO_ENTRATA
	idClass_siope integer:= 0;          -- 20.11.2015 Davide gestione siope
	
	idClass_tipoEntrataRicorrente     integer:= 0; -- 03.03.2016 Davide aggiunta lettura altri attributi accertamenti
	idClass_tipoTransazioneUeEntrata  integer:= 0; -- 03.03.2016 Davide aggiunta lettura altri attributi accertamenti 
	
	
    boolean_value char(1);

	--    costanti
	NVL_STR             CONSTANT VARCHAR:='';
    SEPARATORE			CONSTANT  varchar :='||';
    AMBITO_SOGG         CONSTANT  varchar :='AMBITO_FIN';
    SOGG_CLASSE_TIPO_ND CONSTANT  varchar :='ND';

    NOTE_ACC_LENGTH    CONSTANT integer:=500;

	STATO_VALIDO CONSTANT  varchar :='VA';
    MOVGEST_ACCERT_LIV CONSTANT integer:=1;
    MOVGEST_SUBACC_LIV CONSTANT integer:=1;

    MOVGEST_ACCERT       CONSTANT varchar:='A';
	MOVGEST_TS_ACCERT    CONSTANT varchar:='T';
    MOVGEST_TS_SUBACC     CONSTANT varchar:='S';


    SPR                    CONSTANT varchar:='SPR||';

	IMPORTO_INIZIALE CONSTANT varchar :='I';
	IMPORTO_ATTUALE CONSTANT varchar :='A';
	IMPORTO_UTILIZZABILE CONSTANT varchar :='U'; -- Davide 06.06.2016 - aggiunta importo utilizzabile

    ANNOCAP_ORIG_ACC_ATTR CONSTANT  varchar:='annoCapitoloOrigine';
    NROCAP_ORIG_ACC_ATTR  CONSTANT  varchar:='numeroCapitoloOrigine';
    NROART_ORIG_ACC_ATTR  CONSTANT  varchar:='numeroArticoloOrigine';
    UEB_ORIG_ACC_ATTR     CONSTANT  varchar:='numeroUEBOrigine';

    NOTE_ACC_ATTR         CONSTANT  varchar:='NOTE_MOVGEST';
    ACC_AUTO_ACC_ATTR     CONSTANT  varchar:='ACC_AUTO';

    ANNOACC_PLUR_ACC_ATTR CONSTANT  varchar:='annoOriginePlur';
    NACC_PLUR_ACC_ATTR    CONSTANT  varchar:='numeroOriginePlur';

    ANNOACC_RIACC_ACC_ATTR CONSTANT varchar:='annoRiaccertato';
    NACC_RIACC_ACC_ATTR    CONSTANT varchar:='numeroRiaccertato';
    FLAG_RIACC_ACC_ATTR    CONSTANT varchar:='flagDaRiaccertamento';

    STATO_VALIDO_SOGG    CONSTANT varchar:='VALIDO';


    PDC_FIN_V_LIV         CONSTANT varchar:='PDC_V';

	PERIMETRO_SANITARIO_ENTRATA CONSTANT varchar:='PERIMETRO_SANITARIO_ENTRATA';
	CL_SIOPE              CONSTANT varchar:='SIOPE_ENTRATA_I'; -- 20.11.2015 Davide gestione siope
    SIOPECOD_DEF          CONSTANT varchar :='XXXX';           -- 27.11.2015 Davide gestione siope
	
	ENTRATA_RICORRENTE      CONSTANT varchar:= 'RICORRENTE_ENTRATA';     -- 03.03.2016 Davide aggiunta lettura altri attributi accertamenti
	TRANSAZIONE_UE_ENTRATA  CONSTANT varchar:= 'TRANSAZIONE_UE_ENTRATA'; -- 03.03.2016 Davide aggiunta lettura altri attributi accertamenti
		
    --- classificatori liberi per accertamenti
    CLASSIFICATORE_16 CONSTANT varchar:='CLASSIFICATORE_16';
    CLASSIFICATORE_17 CONSTANT varchar:='CLASSIFICATORE_17';
    CLASSIFICATORE_18 CONSTANT varchar:='CLASSIFICATORE_18';
    CLASSIFICATORE_19 CONSTANT varchar:='CLASSIFICATORE_19';
    CLASSIFICATORE_20 CONSTANT varchar:='CLASSIFICATORE_20';

BEGIN
    numeroAccertamentiInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione accertamenti.da id ['||idmin||'] a id ['||idmax||']';
    strMessaggio:='Lettura accertamenti migrati.';

	/*select COALESCE(count(*),0) into countMigrAccertamento
    from migr_accertamento ms
    where ms.ente_proprietario_id=enteProprietarioId and
          ms.tipo_movimento = tipoMovGestEnt and
          ms.fl_elab='N'
          and ms.migr_accertamento_id >=idmin and ms.migr_accertamento_id <= idmax;

	if COALESCE(countMigrAccertamento,0)=0 then
         messaggioRisultato:=strMessaggioFinale||'Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
         numeroAccertamentiInseriti:=-12;
         return;
    end if;*/
    begin
    	select distinct 1 into countMigrAccertamento from migr_accertamento ms
      	where ms.ente_proprietario_id=enteProprietarioId and
          ms.tipo_movimento = tipoMovGestEnt and
          ms.fl_elab='N'
          and ms.migr_accertamento_id >=idmin and ms.migr_accertamento_id <= idmax;
    exception when NO_DATA_FOUND then
         messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
         numeroAccertamentiInseriti:=-12;
         return;

    end;

    -- lettura id bilancio
    select getBilancio.idbilancio, getBilancio.messaggiorisultato
    into bilancioid, messaggioRisultato
    from fnc_get_bilancio(enteProprietarioId:=enteProprietarioId,annoBilancio:=annoBilancio) getBilancio;

    if (bilancioid=-1) then
         messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
         numeroAccertamentiInseriti:=-13;
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
	    select ambito.ambito_id into strict ambitoId
	    from siac_d_ambito ambito
	    where ambito.ambito_code=AMBITO_SOGG and
		  ambito.ente_proprietario_id=enteProprietarioId;
	exception
	 when NO_DATA_FOUND then
		RAISE EXCEPTION 'Ambito FIN inesistente per ente % ',enteProprietarioId ;
         when others  THEN
	        RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;

	strMessaggio:='Lettura soggetto_classe_tipo_id per AMBITO='||ambito_sogg||' TIPO '||SOGG_CLASSE_TIPO_ND;

	/*select soggetto_classe_tipo_id into soggettoClasseTipoId
    from siac_d_soggetto_classe_tipo soggClasseTipo
    where soggClasseTipo.ambito_id=ambitoId and
          soggClasseTipo.ente_proprietario_id=enteProprietarioId and
          soggClasseTipo.soggetto_classe_tipo_code=SOGG_CLASSE_TIPO_ND;

	if COALESCE(soggettoClasseTipoId,0)=0 then
	    RAISE EXCEPTION 'SoggettoClasseTipo inesistente per ente % ',enteProprietarioId ;
    end if;*/
	begin
		select soggetto_classe_tipo_id into soggettoClasseTipoId
		from siac_d_soggetto_classe_tipo soggClasseTipo
		where soggClasseTipo.ambito_id=ambitoId and
			soggClasseTipo.ente_proprietario_id=enteProprietarioId and
			soggClasseTipo.soggetto_classe_tipo_code=SOGG_CLASSE_TIPO_ND;
	exception
	 when NO_DATA_FOUND then
		RAISE EXCEPTION 'SoggettoClasseTipo inesistente per ente % ',enteProprietarioId ;
         when others  THEN
	        RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;

	if tipoMovGestEnt=MOVGEST_ACCERT then
		strMessaggio:='Aggiornamento Classificatori descri.';
		select * into migrAggClassifAcc
	    from fnc_migr_aggiorna_classif (MOVGEST_ACCERT,
    					                enteProprietarioId,loginOperazione,dataElaborazione);

	   if migrAggClassifAcc.codiceRisultato=-1 then
       	RAISE EXCEPTION ' % ', migrAggClassifAcc.messaggioRisultato;
	   end if;
    end if;



    -- recupero delle fk 'fisse' che saranno usate nel popolamento degli accertamenti
    begin
	code:='MOVGEST_ACCERT';
	    select tipoMovGest.movgest_tipo_id into strict id_movgesttipo
	    from siac_d_movgest_tipo tipoMovGest
	    where tipoMovGest.ente_proprietario_id=enteProprietarioid and
		  tipoMovGest.movgest_tipo_code=MOVGEST_ACCERT and
		  tipoMovGest.data_cancellazione is null and
		  date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
			      or tipoMovGest.validita_fine is null);

	code:='MOVGEST_TS_ACCERT';
		select tipoMovGest.movgest_ts_tipo_id  into strict id_movgesttstipoAcc
	    from siac_d_movgest_ts_tipo tipoMovGest
		where tipoMovGest.ente_proprietario_id=enteProprietarioId and
		  tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_ACCERT and
		      tipoMovGest.data_cancellazione is null and
		  date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			  (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoMovGest.validita_fine)
					      or tipoMovGest.validita_fine is null);
	code:='MOVGEST_TS_SUBACC';
		select tipoMovGest.movgest_ts_tipo_id INTO STRICT id_movgesttstipoSacc
	    from siac_d_movgest_ts_tipo tipoMovGest
	    where tipoMovGest.ente_proprietario_id=enteProprietarioId and
		  tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_SUBACC and
		  tipoMovGest.data_cancellazione is null and
		  date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
		  (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
		      or tipoMovGest.validita_fine is null);
	code:='STATO_VALIDO';
	    select elem_stato_id into strict id_statoValido
	    from siac_d_bil_elem_stato
		where ente_proprietario_id = enteProprietarioId
		and elem_stato_code=STATO_VALIDO
		and data_cancellazione is null
		and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
		    (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
		     or validita_fine is null);
	code:='tipoCapitoloGestEnt';
	    select tipoCapitolo.elem_tipo_id into strict id_tipoCapitoloGestEnt
	    from  siac_d_bil_elem_tipo tipoCapitolo
	    where tipoCapitolo.ente_proprietario_id=enteProprietarioId and
	    tipoCapitolo.elem_tipo_code=tipoCapitoloGestEnt;
	code:='IMPORTO_INIZIALE';
	    select tipoImporto.movgest_ts_det_tipo_id into strict idImportoIniziale
	      from siac_d_movgest_ts_det_tipo tipoImporto
	      where tipoImporto.ente_proprietario_id=enteProprietarioId and
	      tipoImporto.movgest_ts_det_tipo_code=IMPORTO_INIZIALE and
	      tipoImporto.data_cancellazione is null and
	      date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
	      (date_trunc('day',dataElaborazione)<date_trunc('day',tipoImporto.validita_fine)
			or tipoImporto.validita_fine is null);
	code:='IMPORTO_ATTUALE';
	    select tipoImporto.movgest_ts_det_tipo_id into strict idImportoAttuale
	      from siac_d_movgest_ts_det_tipo tipoImporto
	      where tipoImporto.ente_proprietario_id=enteProprietarioId and
		    tipoImporto.movgest_ts_det_tipo_code=IMPORTO_ATTUALE and
		    tipoImporto.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
		    (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoImporto.validita_fine)
			      or tipoImporto.validita_fine is null);

	-- Davide 06.06.2016 - aggiunta importo utilizzabile
	code:='IMPORTO_UTILIZZABILE';
	    select tipoImporto.movgest_ts_det_tipo_id into strict idImportoUtilizzabile
	      from siac_d_movgest_ts_det_tipo tipoImporto
	      where tipoImporto.ente_proprietario_id=enteProprietarioId and
	      tipoImporto.movgest_ts_det_tipo_code=IMPORTO_UTILIZZABILE and
	      tipoImporto.data_cancellazione is null and
	      date_trunc('day',dataElaborazione)>=date_trunc('day',tipoImporto.validita_inizio) and
	      (date_trunc('day',dataElaborazione)<date_trunc('day',tipoImporto.validita_fine)
			or tipoImporto.validita_fine is null);

	code:='ANNOCAP_ORIG_ACC_ATTR';
	     select  attrMovGest.attr_id into strict idAttr_annoCapOrig
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= ANNOCAP_ORIG_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='NROCAP_ORIG_ACC_ATTR';
	    select  attrMovGest.attr_id into strict idAttr_numCapOrigine
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= NROCAP_ORIG_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		    (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='NROART_ORIG_ACC_ATTR';
	    select  attrMovGest.attr_id into strict idAttr_numArtOrigine
	       from siac_t_attr attrMovGest
	       where attrMovGest.ente_proprietario_id=enteProprietarioId and
		     attrMovGest.attr_code= NROART_ORIG_ACC_ATTR and
		     attrMovGest.data_cancellazione is null and
		     date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		     (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='UEB_ORIG_ACC_ATTR';
	    select  attrMovGest.attr_id into strict idAttr_numUebOrigine
		from siac_t_attr attrMovGest
		where attrMovGest.ente_proprietario_id=enteProprietarioId and
		      attrMovGest.attr_code= UEB_ORIG_ACC_ATTR and
		      attrMovGest.data_cancellazione is null and
		      date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='NOTE_ACC_ATTR';
	    select  attrMovGest.attr_id  into strict idAttr_noteMovgest
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= NOTE_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='ACC_AUTO_ACC_ATTR';
	     select  attrMovGest.attr_id into strict idAttr_accAuto
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= ACC_AUTO_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='ANNOACC_PLUR_ACC_ATTR';
	     select  attrMovGest.attr_id into strict idAttr_annoOrigPlur
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= ANNOACC_PLUR_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='NACC_PLUR_ACC_ATTR';
	     select  attrMovGest.attr_id into strict idAttr_numOrigPlur
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= NACC_PLUR_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='ANNOACC_RIACC_ACC_ATTR';
	     select  attrMovGest.attr_id into strict idAttr_annoRiaccertato
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= ANNOACC_RIACC_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='NACC_RIACC_ACC_ATTR';
	    select  attrMovGest.attr_id into strict idAttr_numRiaccertato
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= NACC_RIACC_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='FLAG_RIACC_ACC_ATTR';
	    select attrMovGest.attr_id into strict idAttr_flagDaRiaccertamento
	      from siac_t_attr attrMovGest
	      where attrMovGest.ente_proprietario_id=enteProprietarioId and
		    attrMovGest.attr_code= FLAG_RIACC_ACC_ATTR and
		    attrMovGest.data_cancellazione is null and
		    date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attrMovGest.validita_fine)
			      or attrMovGest.validita_fine is null);
	code:='STATO_VALIDO';
	     select progrStato.programma_stato_id into strict idStatovalidoProgramma
	      from siac_d_programma_stato progrStato
	      where progrStato.programma_stato_code=STATO_VALIDO and
	      progrStato.ente_proprietario_id=enteProprietarioId
	      and progrStato.data_cancellazione is null
	      and date_trunc('day',dataElaborazione)>=date_trunc('day',progrStato.validita_inizio) and
	      (date_trunc('day',dataElaborazione)<=date_trunc('day',progrStato.validita_fine)
			      or progrStato.validita_fine is null);
	code:='PDC_FIN_V_LIV';
	     select tipoPdcFin.classif_tipo_id into strict idClass_pdc
			  from siac_d_class_tipo tipoPdcFin
		      where tipoPdcFin.ente_proprietario_id=enteProprietarioId
				and tipoPdcFin.classif_tipo_code=PDC_FIN_V_LIV
			    and tipoPdcFin.data_cancellazione is null
					and date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
						(date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
				or tipoPdcFin.validita_fine is null);
	code:='PERIMETRO_SANITARIO_ENTRATA';
	      select tipoSanita.classif_tipo_id into strict idClass_tipoSanita
			  from siac_d_class_tipo tipoSanita
		      where tipoSanita.data_cancellazione is null and
				date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSanita.validita_inizio) and
					    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoSanita.validita_fine)
					    or tipoSanita.validita_fine is null) and
						tipoSanita.ente_proprietario_id=enteProprietarioId and
				tipoSanita.classif_tipo_code=PERIMETRO_SANITARIO_ENTRATA;
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
					   
		-- 03.03.2016 Davide aggiunta lettura altri attributi accertamenti
	code:='ENTRATA_RICORRENTE';
	      select tipoEntrataRicorrente.classif_tipo_id into strict idClass_tipoEntrataRicorrente
			  from siac_d_class_tipo tipoEntrataRicorrente
		      where tipoEntrataRicorrente.data_cancellazione is null and
				date_trunc('day',dataElaborazione)>=date_trunc('day',tipoEntrataRicorrente.validita_inizio) and
					    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoEntrataRicorrente.validita_fine)
					    or tipoEntrataRicorrente.validita_fine is null) and
						tipoEntrataRicorrente.ente_proprietario_id=enteProprietarioId and
				tipoEntrataRicorrente.classif_tipo_code=ENTRATA_RICORRENTE;
	code:='TRANSAZIONE_UE_ENTRATA';
	      select tipoTransazioneUeEntrata.classif_tipo_id into strict idClass_tipoTransazioneUeEntrata
			  from siac_d_class_tipo tipoTransazioneUeEntrata
		      where tipoTransazioneUeEntrata.data_cancellazione is null and
				date_trunc('day',dataElaborazione)>=date_trunc('day',tipoTransazioneUeEntrata.validita_inizio) and
					    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoTransazioneUeEntrata.validita_fine)
					    or tipoTransazioneUeEntrata.validita_fine is null) and
						tipoTransazioneUeEntrata.ente_proprietario_id=enteProprietarioId and
				tipoTransazioneUeEntrata.classif_tipo_code=TRANSAZIONE_UE_ENTRATA;					   
exception
	when no_data_found then
		RAISE EXCEPTION 'Code % non presente in archivio',code;
        when others  THEN
	        RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
end;

	-- fine recupero delle fk

    for migrAccertamento IN
    (select ms.*
     from migr_accertamento ms
     where ms.ente_proprietario_id=enteProprietarioId and
     	   ms.tipo_movimento = tipoMovGestEnt and
           ms.fl_elab='N'
           and ms.migr_accertamento_id >=idmin and ms.migr_accertamento_id <= idmax
     order by ms.migr_accertamento_id)
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
		if migrAccertamento.importo_iniziale != migrAccertamento.importo_attuale then
		    migrAccertamento.importo_iniziale := migrAccertamento.importo_attuale; 
        end if;

        --- al momento cercato un capitolo fisso
       -- migrAccertamento.numero_capitolo:=1;
       -- migrAccertamento.numero_articolo=1;
      --  migrAccertamento.numero_ueb=1;

		if tipoMovGestEnt=MOVGEST_ACCERT then
		   	strMessaggio:='Inserimento siac_t_movgest migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
    	    -- siac_t_movgest
			/*INSERT INTO siac_t_movgest
			( movgest_anno, movgest_numero, movgest_desc, movgest_tipo_id, bil_id,
			  validita_inizio, ente_proprietario_id, data_creazione, login_operazione
			)
			(select migrAccertamento.anno_accertamento::numeric, migrAccertamento.numero_accertamento,migrAccertamento.descrizione,
        			tipoMovGest.movgest_tipo_id,bilancioId,
	        	    date_trunc('day', migrAccertamento.data_emissione::timestamp ),enteProprietarioid,CURRENT_TIMESTAMP,loginOperazione
	         from siac_d_movgest_tipo tipoMovGest
    	     where tipoMovGest.ente_proprietario_id=enteProprietarioid and
             	   tipoMovGest.movgest_tipo_code=MOVGEST_ACCERT and
	    	       tipoMovGest.data_cancellazione is null and
            	   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
				   (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
				              or tipoMovGest.validita_fine is null)
        	)*/
			INSERT INTO siac_t_movgest
			( movgest_anno, movgest_numero, movgest_desc, movgest_tipo_id, bil_id,validita_inizio, ente_proprietario_id, data_creazione, login_operazione, parere_finanziario)
            values
			(migrAccertamento.anno_accertamento::numeric,migrAccertamento.numero_accertamento,migrAccertamento.descrizione,
        	id_movgesttipo,bilancioId,date_trunc('day', migrAccertamento.data_emissione::timestamp ),enteProprietarioid,clock_timestamp(),loginOperazione
            , migrAccertamento.parere_finanziario::boolean)
	        returning movgest_id into movgestId;
       ELSE
       	begin
            strMessaggio:='Lettura siac_t_movgest migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
        	/*select coalesce( movGest.movgest_id,0 ) into strict movgestId
            from siac_t_movgest movGest, siac_d_movgest_tipo movGestTipo
            where movGest.ente_proprietario_id=enteProprietarioId and
                  movGest.bil_id=bilancioId and
                  movGestTipo.movgest_tipo_id=movGest.movgest_tipo_id and
                  movGestTipo.movgest_tipo_code=MOVGEST_ACCERT and
                  movGestTipo.ente_proprietario_id=enteProprietarioId and
                  movGestTipo.data_cancellazione is null and
            	   date_trunc('day',dataElaborazione)>=date_trunc('day',movGestTipo.validita_inizio) and
				   (date_trunc('day',dataElaborazione)<date_trunc('day',movGestTipo.validita_fine)
				              or movGestTipo.validita_fine is null) and
                  movGest.movgest_anno= to_number(migrAccertamento.anno_accertamento,'9999') and
                  movGest.movgest_numero=migrAccertamento.numero_accertamento;*/

			select movGest.movgest_id into strict movgestId
            from siac_t_movgest movGest
            where movGest.ente_proprietario_id=enteProprietarioId and
                  movGest.bil_id=bilancioId and
                  movGest.movgest_tipo_id=id_movgesttipo and
                  movGest.movgest_anno= to_number(migrAccertamento.anno_accertamento,'9999') and
                  movGest.movgest_numero=migrAccertamento.numero_accertamento;

             exception
	         	when no_data_found then
				  RAISE EXCEPTION 'Accertamento non presente in archivio';
            	when others  THEN
	              RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        end;
       end if;


       -- siac_t_movgest_ts
  	   if tipoMovGestEnt=MOVGEST_ACCERT then
        strMessaggio:='Inserimento siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
       	/*INSERT INTO siac_t_movgest_ts
	    (  movgest_ts_code,  movgest_id, movgest_ts_tipo_id,
		   livello,  validita_inizio, ente_proprietario_id, data_creazione, login_operazione,
           login_creazione, movgest_ts_scadenza_data
	   	)
	    (select ltrim(rtrim(to_char(migrAccertamento.numero_accertamento,'999999'))),movgestId,tipoMovGest.movgest_ts_tipo_id,
	           MOVGEST_ACCERT_LIV,CURRENT_TIMESTAMP,enteProprietarioid,CURRENT_TIMESTAMP,loginOperazione,
               loginOperazione,date_trunc('day', migrAccertamento.data_scadenza::timestamp )
         from siac_d_movgest_ts_tipo tipoMovGest
         where tipoMovGest.ente_proprietario_id=enteProprietarioId and
         	   tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_ACCERT and
	           tipoMovGest.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
			              or tipoMovGest.validita_fine is null)
         )*/
        INSERT INTO siac_t_movgest_ts
	    (  movgest_ts_code,  movgest_id, movgest_ts_tipo_id,movgest_ts_desc, -- 27.01.2016 Sofia
           livello,validita_inizio, ente_proprietario_id, data_creazione, login_operazione,login_creazione, movgest_ts_scadenza_data)
        values
	    (migrAccertamento.numero_accertamento::varchar,movgestId,id_movgesttstipoAcc,migrAccertamento.descrizione,
         MOVGEST_ACCERT_LIV,dataInizioVal,enteProprietarioid,clock_timestamp(),loginOperazione,loginOperazione,date_trunc('day', migrAccertamento.data_scadenza::timestamp ))
         returning movgest_ts_id into movgestTsId;

       else
           strMessaggio:='Lettura siac_t_movgest_ts id_padre migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
           /*select movGestTsPadre.movgest_ts_id into movgestTsPadreId
           from siac_t_movgest_ts movGestTsPadre,siac_d_movgest_ts_tipo tipoMovGest
           where movGestTsPadre.ente_proprietario_id=enteProprietarioId and
           		 movGestTsPadre.movgest_id=movgestId and
                 tipoMovGest.ente_proprietario_id=enteProprietarioId and
         	     tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_ACCERT and
	             tipoMovGest.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',tipoMovGest.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<date_trunc('day',tipoMovGest.validita_fine)
			              or tipoMovGest.validita_fine is null);*/

           select movgest_ts_id into strict movgestTsPadreId
           from siac_t_movgest_ts
           where ente_proprietario_id=enteProprietarioId
           and movgest_id=movgestId
           and movgest_ts_id_padre is null;

           strMessaggio:='Inserimento siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
	       /*INSERT INTO siac_t_movgest_ts
		   (  movgest_ts_code,  movgest_id, movgest_ts_id_padre, movgest_ts_tipo_id,
			  livello,movgest_ts_desc, validita_inizio, ente_proprietario_id, data_creazione, login_operazione,
              login_creazione, movgest_ts_scadenza_data
	   	   )
	       (select ltrim(rtrim(to_char(migrAccertamento.numero_subaccertamento,'999999'))),movgestId,movgestTsPadreId,tipoMovGest.movgest_ts_tipo_id,
		           MOVGEST_SUBACC_LIV,migrAccertamento.descrizione,
                   date_trunc('day', migrAccertamento.data_emissione::timestamp ),enteProprietarioid,CURRENT_TIMESTAMP,loginOperazione,
    	           loginOperazione,date_trunc('day', migrAccertamento.data_scadenza::timestamp )
            from siac_d_movgest_ts_tipo tipoMovGest
            where tipoMovGest.ente_proprietario_id=enteProprietarioId and
            	  tipoMovGest.movgest_ts_tipo_code=MOVGEST_TS_SUBACC and
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
           (migrAccertamento.numero_subaccertamento::VARCHAR, movgestId, movgestTsPadreId, id_movgesttstipoSacc
           ,MOVGEST_SUBACC_LIV,migrAccertamento.descrizione,date_trunc('day', migrAccertamento.data_emissione::timestamp ),enteProprietarioid, clock_timestamp(),loginOperazione
           ,loginOperazione, date_trunc('day', migrAccertamento.data_scadenza::timestamp ))

            returning movgest_ts_id into movgestTsId;
       end if;

	if tipoMovGestEnt=MOVGEST_ACCERT then
         -- capitolo-ueb
         strMessaggio:='Lettura elemento di bilancio per  siac_t_movgest migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
         begin
         	/*select coalesce(bilCapitolo.elem_id,0)
               into strict capitoloId
            from siac_t_bil_elem bilCapitolo, siac_r_bil_elem_stato statoCapitoloRel,
            	 siac_d_bil_elem_stato statoCapitolo, siac_d_bil_elem_tipo tipoCapitolo
            where bilCapitolo.bil_id=bilancioId and
                  bilCapitolo.elem_code=ltrim(rtrim(to_char(migrAccertamento.numero_capitolo,'999999'))) and
                  bilCapitolo.elem_code2= ltrim(rtrim(to_char(migrAccertamento.numero_articolo,'999999'))) and
                  bilCapitolo.elem_code3= migrAccertamento.numero_ueb and
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
                  tipoCapitolo.elem_tipo_code=tipoCapitoloGestEnt;*/
		select bilCapitolo.elem_id into strict capitoloId
		    from siac_t_bil_elem bilCapitolo, siac_r_bil_elem_stato statoCapitoloRel
		    where bilCapitolo.bil_id=bilancioId and
			  --bilCapitolo.elem_code=ltrim(rtrim(to_char(migrAccertamento.numero_capitolo,'999999'))) and
			  --bilCapitolo.elem_code2= ltrim(rtrim(to_char(migrAccertamento.numero_articolo,'999999'))) and
			  bilCapitolo.elem_code= migrAccertamento.numero_capitolo::varchar and
			  bilCapitolo.elem_code2= migrAccertamento.numero_articolo::varchar and
			  bilCapitolo.elem_code3= migrAccertamento.numero_ueb and
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
			  statoCapitoloRel.elem_stato_id= id_statoValido and
			  bilCapitolo.elem_tipo_id= id_tipoCapitoloGestEnt;
          exception
         	when no_data_found then
			  RAISE EXCEPTION 'Elemento bilancio entrata %/% UEB % non presente in archivio',
              				   migrAccertamento.numero_capitolo,migrAccertamento.numero_articolo,migrAccertamento.numero_ueb;
            when others  THEN
              RAISE EXCEPTION 'Errore per elem bilancio entrata %/% UEB % : %-%.',
              			migrAccertamento.numero_capitolo,migrAccertamento.numero_articolo,migrAccertamento.numero_ueb,
              			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
         end;

         if capitoloId !=0 then
            strMessaggio:='Inserimento relazione con elemento di bilancio per siac_t_movgest migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
         	INSERT INTO siac_r_movgest_bil_elem
            ( movgest_id,elem_id, validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (movgestId,capitoloId,dataInizioVal,enteProprietarioid,clock_timestamp(),loginOperazione);
         end if;
	end if;



    -- stato
	strMessaggio:='Inserimento stato per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
    /*insert into siac_r_movgest_ts_stato
    ( movgest_ts_id, movgest_stato_id, validita_inizio,
	  ente_proprietario_id, data_creazione,login_operazione)
    (select movgestTsId, statoMovGest.movgest_stato_id,CURRENT_TIMESTAMP,
            enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
     from siac_d_movgest_stato statoMovGest
     where statoMovGest.ente_proprietario_id=enteProprietarioId and
       	   statoMovGest.movgest_stato_code=migrAccertamento.stato_operativo and
           statoMovGest.data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',statoMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<date_trunc('day',statoMovGest.validita_fine)
			              or statoMovGest.validita_fine is null)
     );*/
	insert into siac_r_movgest_ts_stato
    ( movgest_ts_id, movgest_stato_id, validita_inizio,ente_proprietario_id, data_creazione,login_operazione)
    (select movgestTsId, statoMovGest.movgest_stato_id,dataInizioVal,
            enteProprietarioId,clock_timestamp(),loginOperazione
     from siac_d_movgest_stato statoMovGest
     where statoMovGest.ente_proprietario_id=enteProprietarioId and
       	   statoMovGest.movgest_stato_code=migrAccertamento.stato_operativo and
           statoMovGest.data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',statoMovGest.validita_inizio) and
		   (date_trunc('day',dataElaborazione)<date_trunc('day',statoMovGest.validita_fine)
			              or statoMovGest.validita_fine is null)
     );


     -- importi
     strMessaggio:='Inserimento importo inziale per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
     /*INSERT INTO siac_t_movgest_ts_det
	 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,
	   validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
     (select movgestTsId,tipoImporto.movgest_ts_det_tipo_id , migrAccertamento.importo_iniziale,
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
	 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
     values
     (movgestTsId,idImportoIniziale, migrAccertamento.importo_iniziale,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);

      strMessaggio:='Inserimento importo attuale per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
      /*INSERT INTO siac_t_movgest_ts_det
		 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,
		   validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
         (select movgestTsId,tipoImporto.movgest_ts_det_tipo_id , migrAccertamento.importo_attuale,
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
		 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
         values
         (movgestTsId,idImportoAttuale, migrAccertamento.importo_attuale,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
		 
      -- Davide 06.06.2016 - aggiunta importo utilizzabile - impostato uguale a importo attuale
      strMessaggio:='Inserimento importo utilizzabile per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
         INSERT INTO siac_t_movgest_ts_det
		 ( movgest_ts_id,  movgest_ts_det_tipo_id, movgest_ts_det_importo,validita_inizio, ente_proprietario_id, data_creazione, login_operazione)
         values
         (movgestTsId,idImportoUtilizzabile, migrAccertamento.importo_attuale,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);

	if tipoMovGestEnt=MOVGEST_ACCERT then
         -- attributi
         --anno_capitolo_orig, numero_capitolo_orig, numero_articolo_orig, numero_ueb_orig
       	 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                         ||' '||ANNOCAP_ORIG_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
	  	 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
           values
           (movgestTsId,idAttr_annoCapOrig,migrAccertamento.anno_capitolo_orig,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
           /*
         (select  movgestTsId,attrMovGest.attr_id,migrAccertamento.anno_capitolo_orig,
            	  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOCAP_ORIG_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
       	 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                         ||' '||NROCAP_ORIG_ACC_ATTR||'.';

         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
           values
           ( movgestTsId,idAttr_numCapOrigine,migrAccertamento.numero_capitolo_orig::varchar,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
                  /*
         (select  movgestTsId,attrMovGest.attr_id,ltrim(rtrim(to_char(migrAccertamento.numero_capitolo_orig,'999999'))),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NROCAP_ORIG_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
				(date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
          strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                         ||' '||NROART_ORIG_ACC_ATTR||'.';

		  INSERT INTO siac_r_movgest_ts_attr
		  ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		    data_creazione, login_operazione )
          values
          (movgestTsId,idAttr_numArtOrigine,migrAccertamento.numero_articolo_orig,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
            /*
          (select  movgestTsId,attrMovGest.attr_id,migrAccertamento.numero_articolo_orig,--ltrim(rtrim(to_char(migrAccertamento.numero_articolo_orig,'999999'))),
            	   CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
           from siac_t_attr attrMovGest
           where attrMovGest.ente_proprietario_id=enteProprietarioId and
                 attrMovGest.attr_code= NROART_ORIG_ACC_ATTR and
                 attrMovGest.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
				 (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
           );*/
           strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||UEB_ORIG_ACC_ATTR||'.';
           INSERT INTO siac_r_movgest_ts_attr
		   ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,
		     data_creazione, login_operazione )
             values
             (movgestTsId, idAttr_numUebOrigine,migrAccertamento.numero_ueb_orig,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
/*           (select  movgestTsId,attrMovGest.attr_id,migrAccertamento.numero_ueb_orig,--ltrim(rtrim(to_char(migrAccertamento.numero_ueb_orig,'999999'))),
           		    CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
            from siac_t_attr attrMovGest
            where attrMovGest.ente_proprietario_id=enteProprietarioId and
                  attrMovGest.attr_code= UEB_ORIG_ACC_ATTR and
                  attrMovGest.data_cancellazione is null and
	              date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
			   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
            );*/

         --nota
		 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||NOTE_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
           values
           (movgestTsId,idAttr_noteMovgest,substring(migrAccertamento.nota from 1 for NOTE_ACC_LENGTH),dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
         /*(select  movgestTsId,attrMovGest.attr_id,substring(migrAccertamento.nota from 1 for NOTE_ACC_LENGTH),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NOTE_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

		 --automatico
		 strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||ACC_AUTO_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, boolean, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
         values
         (movgestTsId,idAttr_accAuto,migrAccertamento.automatico,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
         /*(select  movgestTsId,attrMovGest.attr_id,migrAccertamento.automatico,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ACC_AUTO_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

       	 --anno_accertamento_plur, numero_accertamento_plur
         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||ANNOACC_PLUR_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
         values
         (movgestTsId,idAttr_annoOrigPlur,migrAccertamento.anno_accertamento_plur,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
         /*(select  movgestTsId,attrMovGest.attr_id,migrAccertamento.anno_accertamento_plur,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOACC_PLUR_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||NACC_PLUR_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
           values
           (movgestTsId,idAttr_numOrigPlur,migrAccertamento.numero_accertamento_plur::varchar,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
         /*(select  movgestTsId,attrMovGest.attr_id,ltrim(rtrim(to_char(migrAccertamento.numero_accertamento_plur,'999999'))),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NACC_PLUR_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

         --anno_accertamento_riacc, numero_accertamento_riacc
         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||ANNOACC_RIACC_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
         values
         (movgestTsId,idAttr_annoRiaccertato,migrAccertamento.anno_accertamento_riacc,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
         /*
         (select  movgestTsId,attrMovGest.attr_id,migrAccertamento.anno_accertamento_riacc,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= ANNOACC_RIACC_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/
         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||NACC_RIACC_ACC_ATTR||'.';
         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, testo, validita_inizio, ente_proprietario_id,data_creazione, login_operazione )
           values
           (movgestTsId,idAttr_numRiaccertato,migrAccertamento.numero_accertamento_riacc::varchar,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
         /*(select  movgestTsId,attrMovGest.attr_id,ltrim(rtrim(to_char(migrAccertamento.numero_accertamento_riacc,'999999'))),
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= NACC_RIACC_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/

         strMessaggio:='Inserimento attributi per siac_t_movgest_ts migr_accertamento_id= '||migrAccertamento.migr_accertamento_id
                          ||' '||FLAG_RIACC_ACC_ATTR||'.';

         if migrAccertamento.numero_accertamento_riacc is null or migrAccertamento.numero_accertamento_riacc = 0 then
           	boolean_value := 'N';
         else
            boolean_value := 'S';
          end if;

         INSERT INTO siac_r_movgest_ts_attr
		 ( movgest_ts_id, attr_id, boolean, validita_inizio, ente_proprietario_id,
		   data_creazione, login_operazione )
           values
           (movgestTsId,idAttr_flagDaRiaccertamento,boolean_value,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
         /*(select  movgestTsId,attrMovGest.attr_id,
                   CASE WHEN COALESCE(migrAccertamento.numero_accertamento_riacc,0)!=0
                   		THEN 'S' ELSE 'N' END,
                  CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
          from siac_t_attr attrMovGest
          where attrMovGest.ente_proprietario_id=enteProprietarioId and
                attrMovGest.attr_code= FLAG_RIACC_ACC_ATTR and
                attrMovGest.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attrMovGest.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<date_trunc('day',attrMovGest.validita_fine)
			              or attrMovGest.validita_fine is null)
          );*/


		 -- Opera
         if coalesce(migrAccertamento.opera ,NVL_STR)=NVL_STR then
            strMessaggio:='Inserimento relazione con opera  per siac_t_movgest_ts migr_accertamento_id= '
                           ||migrAccertamento.migr_accertamento_id||'.';
	         INSERT INTO siac_r_movgest_ts_programma
			 ( movgest_ts_id,  programma_id, validita_inizio, ente_proprietario_id,
			   data_creazione,login_operazione
			 )
             (select movgestTsId,programma.programma_id,dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
        	  from siac_t_programma programma , siac_r_programma_stato progrStatoRel
	          where programma.ente_proprietario_id=enteProprietarioId and
    	            programma.programma_code=migrAccertamento.opera and
        	        programma.data_cancellazione is not null and
            	    date_trunc('day',dataElaborazione)>=date_trunc('day',programma.validita_inizio) and
	 		    	(date_trunc('day',dataElaborazione)<=date_trunc('day',programma.validita_fine)
			        	    or programma.validita_fine is null) and
	                progrStatoRel.programma_id=programma.programma_id and
    	            progrStatoRel.programma_stato_id = idStatovalidoProgramma and
        	        progrStatoRel.data_cancellazione is not null and
            	    date_trunc('day',dataElaborazione)>=date_trunc('day',progrStatoRel.validita_inizio) and
	 		    	(date_trunc('day',dataElaborazione)<=date_trunc('day',progrStatoRel.validita_fine)
				            or progrStatoRel.validita_fine is null));
             /*
    	     (select movgestTsId,programma.programma_id,CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
        	  from siac_t_programma programma , siac_r_programma_stato progrStatoRel,
          		   siac_d_programma_stato progrStato
	          where programma.ente_proprietario_id=enteProprietarioId and
    	            programma.programma_code=migrAccertamento.opera and
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
         end if;

    end if;


      -- soggetto
      if migrAccertamento.soggetto_determinato='S' then
        	begin
				strMessaggio:='Lettura soggetto  migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
--				soggettoId := 1;
            	select   coalesce(soggetto.soggetto_id,0) into strict soggettoId
                from siac_t_soggetto soggetto, migr_soggetto migrSoggetto,
                     siac_r_migr_soggetto_soggetto migrRelSoggetto
                where
                	migrSoggetto.fl_genera_codice = 'N' and
                	migrSoggetto.codice_soggetto=migrAccertamento.codice_soggetto and
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
              				   migrAccertamento.codice_soggetto;
           		 when others  THEN
             		 RAISE EXCEPTION 'Errore lettura soggetto codice=% : %-%.',
              			migrAccertamento.codice_soggetto,
              			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

          end;

          if soggettoId!=0 then
	            strMessaggio:='Inserimento relazione con soggetto per siac_t_movgest_ts migr_accertamento_id= '
                               ||migrAccertamento.migr_accertamento_id||'.';
            	INSERT INTO siac_r_movgest_ts_sog
				(movgest_ts_id,soggetto_id, validita_inizio,ente_proprietario_id, data_creazione,login_operazione)
				VALUES
                (movgestTsId,soggettoId, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
            end if;
         else  -- classe soggetto
           if tipoMovGestEnt!=MOVGEST_ACCERT  then
            	RAISE EXCEPTION 'Soggetto non determinato per subAccertamento migr_accertamento_id=%',
              				   migrAccertamento.migr_accertamento_id;
           end if;

           if migrAccertamento.soggetto_determinato='G' then
             begin
   				strMessaggio:='Lettura classe soggetto in migr_classe  migr_accertamento_id= '
                     ||migrAccertamento.migr_accertamento_id||'.';

                --select coalesce(migrClasseRel.soggetto_classe_id,0) into strict soggettoClasseId
                select migrClasseRel.soggetto_classe_id into strict soggettoClasseId
                from migr_classe migrClasse, siac_r_migr_classe_soggclasse migrClasseRel ,
                     siac_d_soggetto_classe soggClasse
                where migrClasse.ente_proprietario_id=enteProprietarioId and
                      migrClasse.codice_soggetto=migrAccertamento.codice_soggetto and
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
              				   migrAccertamento.codice_soggetto;
           		 when others  THEN
             		 RAISE EXCEPTION 'Errore lettura Classe [soggetto codice=%] in migr_classe: %-%.',
              			migrAccertamento.codice_soggetto,
	            			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
               end;
           else
            if COALESCE(migrAccertamento.classe_soggetto,NVL_STR)!=NVL_STR then
             begin
		strMessaggio:='Lettura classe soggetto  migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';

                strToElab:=migrAccertamento.classe_soggetto;
		classeSoggettoCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
                classeSoggettoDesc:=substring(strToElab from
						position(SEPARATORE in strToElab)+2
						for char_length(strToElab)-position(SEPARATORE in strToElab));

            	--select   coalesce(soggClasse.soggetto_classe_id,0) into strict soggettoClasseId
            	select   soggClasse.soggetto_classe_id into strict soggettoClasseId
                from siac_d_soggetto_classe soggClasse
                where soggClasse.soggetto_classe_code=classeSoggettoCode and
			soggClasse.ente_proprietario_id=enteProprietarioId and
			soggClasse.data_cancellazione is null and
			date_trunc('day',dataElaborazione)>=date_trunc('day',soggClasse.validita_inizio) and
			(date_trunc('day',dataElaborazione)<=date_trunc('day',soggClasse.validita_fine)
			or soggClasse.validita_fine is null);

	      exception
		when no_data_found then
	                strMessaggio:='Inserimento classe soggetto  migr_accertamento_id= '||migrAccertamento.migr_accertamento_id||'.';
                	insert into siac_d_soggetto_classe
				( soggetto_classe_tipo_id,soggetto_classe_code,soggetto_classe_desc,validita_inizio, ambito_id,ente_proprietario_id,data_creazione,login_operazione)
	                values
				( soggettoClasseTipoId,classeSoggettoCode,classeSoggettoDesc,dataInizioVal,ambitoId,enteProprietarioId,clock_timestamp(),loginOperazione)
			returning soggetto_classe_id into soggettoClasseId;

		 when others  THEN
             		 RAISE EXCEPTION 'Errore lettura classe soggetto % : %-%.',classeSoggettoCode,SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
             end;
            end if;  --G

            if soggettoClasseId!=0 then
	            strMessaggio:='Inserimento relazione con classe soggetto per siac_t_movgest_ts migr_accertamento_id= '
                               ||migrAccertamento.migr_accertamento_id||'.';
            	INSERT INTO siac_r_movgest_ts_sogclasse
				( movgest_ts_id,soggetto_classe_id, validita_inizio,ente_proprietario_id, data_creazione,login_operazione)
				VALUES
                (movgestTsId,soggettoClasseId, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione);
            end if;

           end if; -- classe_soggetto
        end if; --!=S

	 -- PdcFin - se indicato e di V livello
     if coalesce(migrAccertamento.pdc_finanziario,NVL_STR)!=NVL_STR then
			 strMessaggio:='Inserimento relazione con PDC_FIN_V_LIV  per siac_t_movgest_ts migr_accertamento_id= '
                               ||migrAccertamento.migr_accertamento_id||'.';
			 INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
			(select movgestTsId,tipoPdcFinClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoPdcFinClass
    	      where tipoPdcFinClass.classif_code=migrAccertamento.pdc_finanziario and
        	  	    tipoPdcFinClass.ente_proprietario_id=enteProprietarioId and
            	    tipoPdcFinClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFinClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoPdcFinClass.validita_fine)
			            or tipoPdcFinClass.validita_fine is null) and
    	            tipoPdcFinClass.classif_tipo_id = idClass_pdc);

        	 /*(select movgestTsId,tipoPdcFinClass.classif_id, CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
	          from siac_d_class_tipo tipoPdcFin,  siac_t_class tipoPdcFinClass
    	      where tipoPdcFinClass.classif_code=migrAccertamento.pdc_finanziario and
        	  	    tipoPdcFinClass.ente_proprietario_id=enteProprietarioId and
            	    tipoPdcFinClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFinClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoPdcFinClass.validita_fine)
			            or tipoPdcFinClass.validita_fine is null) and
    	            tipoPdcFin.classif_tipo_id=tipoPdcFinClass.classif_tipo_id and
					tipoPdcFin.ente_proprietario_id=enteProprietarioId and
	                tipoPdcFin.classif_tipo_code=PDC_FIN_V_LIV);*/
      end if;

     -- TRB - al momento solo gestiti perimetro_sanitario_entrata
     -- transazione_ue_entrata
     -- siope_entrata
     -- entrata_ricorrente
     -- politiche_regionali_unitarie
     -- pdc_economico_patr


     -- perimetro_sanitario_entrata
     if coalesce(migrAccertamento.perimetro_sanitario_entrata,NVL_STR)!=NVL_STR then
			 strMessaggio:='Inserimento relazione con PERIMETRO_SANITARIO_ENTRATA  per siac_t_movgest_ts migr_accertamento_id= '
                               ||migrAccertamento.migr_accertamento_id||'.';
			 INSERT INTO siac_r_movgest_class
			 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
			 )
			 (select movgestTsId,tipoSanitaClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	          from siac_t_class tipoSanitaClass
    	      where tipoSanitaClass.classif_code=migrAccertamento.perimetro_sanitario_entrata and
        	  	    tipoSanitaClass.ente_proprietario_id=enteProprietarioId and
            	    tipoSanitaClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSanitaClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoSanitaClass.validita_fine)
			            or tipoSanitaClass.validita_fine is null) and
    	            tipoSanitaClass.classif_tipo_id = idClass_tipoSanita);
             /*
        	 (select movgestTsId,tipoSanitaClass.classif_id, CURRENT_TIMESTAMP, enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
	          from siac_d_class_tipo tipoSanita,  siac_t_class tipoSanitaClass
    	      where tipoSanitaClass.classif_code=migrAccertamento.perimetro_sanitario_entrata and
        	  	    tipoSanitaClass.ente_proprietario_id=enteProprietarioId and
            	    tipoSanitaClass.data_cancellazione is null and
                	date_trunc('day',dataElaborazione)>=date_trunc('day',tipoSanitaClass.validita_inizio) and
		 		    (date_trunc('day',dataElaborazione)<date_trunc('day',tipoSanitaClass.validita_fine)
			            or tipoSanitaClass.validita_fine is null) and
    	            tipoSanita.classif_tipo_id=tipoSanitaClass.classif_tipo_id and
					tipoSanita.ente_proprietario_id=enteProprietarioId and
	                tipoSanita.classif_tipo_code=PERIMETRO_SANITARIO_ENTRATA);*/
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
	         if coalesce(migrAccertamento.siope_entrata,NVL_STR)!=NVL_STR then
	             classif_siope_code := migrAccertamento.siope_entrata;
	         else
	             begin
 			         --... altrimenti lo leggi dal movimento a cui è collegato
                     if tipoMovGestEnt=MOVGEST_ACCERT then
                         strMessaggio:='Lettura del SIOPE dal capitolo di entrata collegato.';
   	                     select tipi_class.classif_code into strict classif_siope_code
		                   from siac_t_class tipi_class, siac_r_bil_elem_class relaz_capclass
                          where relaz_capclass.ente_proprietario_id=enteproprietarioid
                            and tipi_class.ente_proprietario_id=relaz_capclass.ente_proprietario_id
                            and relaz_capclass.elem_id=capitoloId
			                and tipi_class.classif_tipo_id=idClass_siope
			                and tipi_class.classif_id=relaz_capclass.classif_id;
	                 else
                         strMessaggio:='Lettura del SIOPE dall'' accertamento collegato.';
  	                     select tipi_class.classif_code into strict classif_siope_code
			               from siac_t_class tipi_class, siac_r_movgest_class relaz_impclass
                          where relaz_impclass.ente_proprietario_id=enteproprietarioid
                            and tipi_class.ente_proprietario_id=relaz_impclass.ente_proprietario_id
                            -- Dani 25.01.2016 Il siope e legato al subaccertamemto testata dell'accertamento non all'accertamento stesso
--                            and relaz_impclass.movgest_ts_id=movgestId
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
	
	-- 03.03.2016 Davide aggiunta lettura altri attributi accertamenti
    -- transazione_ue_entrata
	if coalesce(migrAccertamento.transazione_ue_entrata,NVL_STR)!=NVL_STR then
         strMessaggio:='Inserimento relazione con TRANSAZIONE_UE_ENTRATA su siac_r_movgest_class.';

         INSERT INTO siac_r_movgest_class
		 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
		 )
		 (select movgestTsId,tipoTransazioneUeEntrataClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	        from siac_t_class tipoTransazioneUeEntrataClass
    	   where tipoTransazioneUeEntrataClass.classif_code=migrAccertamento.transazione_ue_entrata and
           	     tipoTransazioneUeEntrataClass.ente_proprietario_id=enteProprietarioId and
            	 tipoTransazioneUeEntrataClass.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',tipoTransazioneUeEntrataClass.validita_inizio) and
		 		 (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoTransazioneUeEntrataClass.validita_fine)
			            or tipoTransazioneUeEntrataClass.validita_fine is null) and
    	         tipoTransazioneUeEntrataClass.classif_tipo_id = idClass_tipoTransazioneUeEntrata);
	--else
	    -- segnalazione di relazione non inserita per mancanza totale del campo TRANSAZIONE_UE_ENTRATA
 		--RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento TRANSAZIONE_UE_ENTRATA!!!';
    end if;
    -- entrata_ricorrente
	if coalesce(migrAccertamento.entrata_ricorrente,NVL_STR)!=NVL_STR then
         strMessaggio:='Inserimento relazione con ENTRATA_RICORRENTE su siac_r_movgest_class.';

         INSERT INTO siac_r_movgest_class
		 ( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
		 )
		 (select movgestTsId,tipoEntrataRicorrenteClass.classif_id, dataInizioVal, enteProprietarioId,clock_timestamp(),loginOperazione
	        from siac_t_class tipoEntrataRicorrenteClass
    	   where tipoEntrataRicorrenteClass.classif_code=migrAccertamento.entrata_ricorrente and
           	     tipoEntrataRicorrenteClass.ente_proprietario_id=enteProprietarioId and
            	 tipoEntrataRicorrenteClass.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',tipoEntrataRicorrenteClass.validita_inizio) and
		 		 (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoEntrataRicorrenteClass.validita_fine)
			            or tipoEntrataRicorrenteClass.validita_fine is null) and
    	         tipoEntrataRicorrenteClass.classif_tipo_id = idClass_tipoEntrataRicorrente);
	--else
	    -- segnalazione di relazione non inserita per mancanza totale del campo ENTRATA_RICORRENTE
 		--RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento ENTRATA_RICORRENTE!!!';
    end if;
	
	if tipoMovGestEnt=MOVGEST_ACCERT then
     	 -- classificatori
         -- CLASSIFICATORE_16
		 if coalesce(migrAccertamento.classificatore_1,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrAccertamento.classificatore_1||'.';
            strToElab:=migrAccertamento.classificatore_1;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_16,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;

		 -- CLASSIFICATORE_17
		 if coalesce(migrAccertamento.classificatore_2,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrAccertamento.classificatore_2||'.';
			strToElab:=migrAccertamento.classificatore_2;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_17,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;
		 -- CLASSIFICATORE_18
		 if coalesce(migrAccertamento.classificatore_3,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrAccertamento.classificatore_3||'.';
			strToElab:=migrAccertamento.classificatore_3;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_18,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;
		 -- CLASSIFICATORE_19
		 if coalesce(migrAccertamento.classificatore_4,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrAccertamento.classificatore_4||'.';
			strToElab:=migrAccertamento.classificatore_4;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_19,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
            if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;

		 -- CLASSIFICATORE_20
		 if coalesce(migrAccertamento.classificatore_5,NVL_STR)!=NVL_STR then
			strMessaggio:='Classificatore '||migrAccertamento.classificatore_5||'.';
			strToElab:=migrAccertamento.classificatore_5;
		    classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
            classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
			select * into migrClassifMovGest
            from fnc_migr_classif_movgest (CLASSIFICATORE_20,classifCode,classifDesc,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
          	if migrClassifMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassifMovGest.messaggioRisultato;
            end if;
         end if;
  end if;

  -- strAmm
  if coalesce(migrAccertamento.numero_provvedimento,0)!=0 or
	 migrAccertamento.tipo_provvedimento=SPR
     then
	        strMessaggio:='Provvedimento.';
			select * into migrAttoAmmMovGest
            from fnc_migr_attoamm_movgest (migrAccertamento.anno_provvedimento,migrAccertamento.numero_provvedimento,
            							   migrAccertamento.tipo_provvedimento,migrAccertamento.direzione_provvedimento,
										   migrAccertamento.oggetto_provvedimento,migrAccertamento.note_provvedimento,
										   migrAccertamento.stato_provvedimento,
            							   movgestTsId,enteProprietarioId,loginOperazione,dataElaborazione, dataInizioVal);

            if migrAttoAmmMovGest.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrAttoAmmMovGest.messaggioRisultato;
            end if;
   end if;

  strMessaggio:='Inserimento siac_r_migr_accertamento_movgest_ts per migr_accertamento_id= '
                               ||migrAccertamento.migr_accertamento_id||'.';
  insert into siac_r_migr_accertamento_movgest_ts
  (migr_accertamento_id,movgest_ts_id,ente_proprietario_id,data_creazione)
  values
  (migrAccertamento.migr_accertamento_id,movgestTsId,enteProprietarioId,CURRENT_TIMESTAMP);

   numeroElementiInseriti:=numeroElementiInseriti+1;
  end loop;

   RAISE NOTICE 'NumeroAccertamentiInseriti %', numeroElementiInseriti;

   -- aggiornamento progressivi
   if tipoMovGestEnt=MOVGEST_ACCERT then
     select * into aggProgressivi
     from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGestEnt, loginOperazione);

      if aggProgressivi.codresult=-1 then
          RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
      end if;
	end if;

	-- valorizzare fl_elab = 'S'
    update migr_accertamento set fl_elab='S'
    where ente_proprietario_id=enteProprietarioId and
               tipo_movimento = tipoMovGestEnt and
               fl_elab='N'
               and migr_accertamento_id >= idMin and migr_accertamento_id <=idMax;

   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' accertamenti.';
   numeroAccertamentiInseriti:= numeroElementiInseriti;

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 100) ;
        numeroAccertamentiInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        numeroAccertamentiInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;